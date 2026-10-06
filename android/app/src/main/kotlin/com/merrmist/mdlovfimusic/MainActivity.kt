package com.merrmist.mdlovfimusic

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private const val CHANNEL = "com.merrmist.mdlovfimusic/equalizer"
    private val equalizer = com.merrmist.mdlovfimusicmusic.Equalizer()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val sessionId = call.argument<Int>("sessionId") ?: 0
            when (call.method) {
                "setBandGains" -> {
                    val gainsList = call.argument<List<Int>>("gains")
                    if (gainsList != null) {
                        equalizer.setBandGains(sessionId, gainsList.toIntArray())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "gains parameter required", null)
                    }
                }
                "setBassBoost" -> {
                    val strength = call.argument<Int>("strength") ?: 0
                    equalizer.setBassBoost(sessionId, strength)
                    result.success(true)
                }
                "setLoudnessGain" -> {
                    val gainMb = call.argument<Int>("gainMb") ?: 0
                    equalizer.setLoudnessGain(sessionId, gainMb)
                    result.success(true)
                }
                "initAudioEffect" -> {
                    equalizer.initAudioEffect(sessionId, applicationContext)
                    result.success(true)
                }
                "endAudioEffect" -> {
                    equalizer.endAudioEffect(sessionId, applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
