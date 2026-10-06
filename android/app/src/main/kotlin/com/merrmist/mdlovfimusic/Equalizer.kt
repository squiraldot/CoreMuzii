package com.merrmist.mdlovfimusicmusic

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.audiofx.AudioEffect
import android.media.audiofx.BassBoost
import android.media.audiofx.DynamicsProcessing
import android.media.audiofx.Equalizer as AndroidEqualizer
import android.media.audiofx.LoudnessEnhancer
import android.os.Build
import androidx.annotation.Keep

@Keep
class Equalizer {
    private var androidEq: AndroidEqualizer? = null
    private var bassBoost: BassBoost? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var dynamicsProcessing: DynamicsProcessing? = null

    fun openEqualizer(sessionId: Int, context: Context, activity: Activity): Boolean {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
            putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
            putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
            putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
        }
        if ((intent.resolveActivity(context.packageManager) != null)) {
            activity.startActivityForResult(intent, 0)
            return true
        } else {
            if (!openManufacturerEqualizer(sessionId, context, activity)) {
                return openSoundSettings(activity)
            }
            return true
        }
    }

    fun initAudioEffect(sessionId: Int, context: Context) {
        if (sessionId <= 0) return
        releaseAudioEffects()

        try {
            androidEq = AndroidEqualizer(0, sessionId).apply {
                enabled = true
            }
            bassBoost = BassBoost(0, sessionId).apply {
                enabled = true
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                loudnessEnhancer = LoudnessEnhancer(sessionId).apply {
                    enabled = true
                }
            }
            sendAudioEffectIntent(
                sessionId,
                AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION,
                context
            )
            println("Native audio effects initialized for session: $sessionId")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setBandGains(sessionId: Int, gainsMillibels: IntArray) {
        try {
            val eq = androidEq ?: AndroidEqualizer(0, sessionId).also { androidEq = it }
            eq.enabled = true
            val numBands = eq.numberOfBands.toInt()
            for (i in 0 until minOf(numBands, gainsMillibels.size)) {
                val range = eq.bandLevelRange
                val clamped = gainsMillibels[i].clamp(range[0].toInt(), range[1].toInt())
                eq.setBandLevel(i.toShort(), clamped.toShort())
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setBassBoost(sessionId: Int, strength: Int) {
        try {
            val bb = bassBoost ?: BassBoost(0, sessionId).also { bassBoost = it }
            bb.enabled = strength > 0
            if (strength > 0) {
                bb.setStrength(strength.clamp(0, 1000).toShort())
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setLoudnessGain(sessionId: Int, gainMb: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) return
        try {
            val le = loudnessEnhancer ?: LoudnessEnhancer(sessionId).also { loudnessEnhancer = it }
            le.enabled = gainMb != 0
            le.setTargetGain(gainMb)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun endAudioEffect(sessionId: Int, context: Context) {
        releaseAudioEffects()
        sendAudioEffectIntent(
            sessionId,
            AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION,
            context
        )
        println("Native audio effects released for session: $sessionId")
    }

    private fun releaseAudioEffects() {
        try {
            androidEq?.release()
            androidEq = null
            bassBoost?.release()
            bassBoost = null
            loudnessEnhancer?.release()
            loudnessEnhancer = null
            dynamicsProcessing?.release()
            dynamicsProcessing = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendAudioEffectIntent(sessionId: Int, action: String, context: Context) {
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
            "com.android.settings.Settings\$SoundSettingsActivity",
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
                    intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                    activity.startActivity(intent)
                    return true
                }
            } catch (_: Exception) {

            }
        }
        return false
    }

    private fun openSoundSettings(activity: Activity): Boolean {
        try {
            activity.startActivity(Intent(android.provider.Settings.ACTION_SOUND_SETTINGS))
            return true
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    private fun Int.clamp(min: Int, max: Int): Int = if (this < min) min else if (this > max) max else this
}
