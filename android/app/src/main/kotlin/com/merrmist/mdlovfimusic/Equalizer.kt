package com.merrmist.mdlovfimusic

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.AudioEffect
import android.media.audiofx.DynamicsProcessing
import android.os.Build
import androidx.annotation.Keep
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

@Keep
class Equalizer {
    private val dynamicsProcessors = ConcurrentHashMap<Int, DynamicsProcessing>()

    fun openEqualizer(sessionId: Int, context: Context, activity: Activity): Boolean {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
            putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
            putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
            putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
        }
        if (intent.resolveActivity(context.packageManager) != null) {
            activity.startActivityForResult(intent, 0)
            return true
        }

        return openManufacturerEqualizer(sessionId, context, activity) ||
            openSoundSettings(activity)
    }

    /**
     * Applies the platform-independent MDLovFi EQ model to an Android audio session.
     *
     * API 28+ uses DynamicsProcessing because it supports a configurable multi-band
     * EQ stage and a limiter on the same AudioTrack/MediaPlayer session.
     */
    fun applyEqualizerConfig(sessionId: Int, configJson: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P || sessionId <= 0) {
            return false
        }

        return try {
            val config = JSONObject(configJson)
            val enabled = config.optBoolean("enabled", true)
            val preamp = config.optDouble("preamp", 0.0).toFloat()
            val outputGain = config.optDouble("outputGain", 0.0).toFloat()
            val limiterEnabled = config.optBoolean("limiterEnabled", true)
            val bands = config.optJSONArray("bands") ?: return false

            if (bands.length() == 0 || bands.length() > MAX_EQ_BANDS) {
                return false
            }

            val oldProcessor = dynamicsProcessors.remove(sessionId)
            oldProcessor?.release()

            // Create a temporary effect to discover the actual channel count for this
            // audio session. The configured effect is then created with the same count.
            val probe = DynamicsProcessing(sessionId)
            val channelCount = probe.channelCount
            probe.release()

            if (channelCount <= 0) {
                return false
            }

            val builder = DynamicsProcessing.Config.Builder(
                DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                channelCount,
                true,
                bands.length(),
                false,
                0,
                false,
                0,
                true
            )

            val totalInputGain = (preamp + outputGain).coerceIn(-15f, 15f)
            builder.setInputGainAllChannelsTo(totalInputGain)

            val processor = DynamicsProcessing(
                0,
                sessionId,
                builder.build()
            )

            val cutoffs = calculateCutoffs(bands)
            for (channel in 0 until channelCount) {
                for (bandIndex in 0 until bands.length()) {
                    val band = bands.getJSONObject(bandIndex)
                    val gain = band.optDouble("gainDb", 0.0).toFloat().coerceIn(-15f, 15f)
                    val bandEnabled = band.optBoolean("enabled", true)
                    processor.setPreEqBandByChannelIndex(
                        channel,
                        bandIndex,
                        DynamicsProcessing.EqBand(
                            bandEnabled,
                            cutoffs[bandIndex],
                            gain
                        )
                    )
                }

                processor.setLimiterByChannelIndex(
                    channel,
                    DynamicsProcessing.Limiter(
                        true,
                        limiterEnabled && enabled,
                        0,
                        5f,
                        100f,
                        20f,
                        -1f,
                        0f
                    )
                )
            }

            processor.enabled = enabled
            dynamicsProcessors[sessionId] = processor
            true
        } catch (_: Throwable) {
            false
        }
    }

    fun releaseEqualizer(sessionId: Int) {
        dynamicsProcessors.remove(sessionId)?.release()
    }

    fun initAudioEffect(sessionId: Int, context: Context) {
        sendAudioEffectIntent(
            sessionId,
            AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION,
            context
        )
    }

    fun endAudioEffect(sessionId: Int, context: Context) {
        releaseEqualizer(sessionId)
        sendAudioEffectIntent(
            sessionId,
            AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION,
            context
        )
    }

    private fun calculateCutoffs(bands: org.json.JSONArray): FloatArray {
        val cutoffs = FloatArray(bands.length())
        var previous = 20f

        for (index in 0 until bands.length()) {
            val frequency = bands.getJSONObject(index)
                .optDouble("frequency", previous.toDouble())
                .toFloat()

            val cutoff = frequency.coerceAtLeast(previous + 0.1f)
            cutoffs[index] = cutoff.coerceIn(20.1f, 20000f)
            previous = cutoffs[index]
        }

        return cutoffs
    }

    private fun sendAudioEffectIntent(
        sessionId: Int,
        action: String,
        context: Context
    ) {
        val intent = Intent(action).apply {
            putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
            putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
            putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
        }
        context.sendBroadcast(intent)
    }

    private fun openManufacturerEqualizer(
        sessionId: Int,
        context: Context,
        activity: Activity
    ): Boolean {
        val equalizerPackages = listOf(
            "com.android.settings.Settings$SoundSettingsActivity",
            "com.android.settings.EqualizerSettings",
            "com.samsung.android.soundalive",
            "com.miui.audioeffect",
            "com.oneplus.sound.tuner"
        )

        for (packageName in equalizerPackages) {
            try {
                val intent = context.packageManager.getLaunchIntentForPackage(packageName)
                if (intent != null) {
                    intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                    intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
                    activity.startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
                // Continue to the next known manufacturer implementation.
            }
        }
        return false
    }

    private fun openSoundSettings(activity: Activity): Boolean {
        return try {
            activity.startActivity(Intent(android.provider.Settings.ACTION_SOUND_SETTINGS))
            true
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        private const val MAX_EQ_BANDS = 12
    }
}
