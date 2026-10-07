package com.merrmist.mdlovfimusic

import android.media.audiofx.Visualizer
import android.os.Build
import androidx.annotation.Keep
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.hypot

class MainActivity : AudioServiceActivity() {
    private val spectrumChannel = "mdlovfi/spectrum_analyzer"
    private val visualizers = ConcurrentHashMap<Int, Visualizer>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, spectrumChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val sessionId = call.argument<Int>("sessionId") ?: 0
                        val captureSize = call.argument<Int>("captureSize") ?: 1024
                        result.success(startVisualizer(sessionId, captureSize))
                    }
                    "getFft" -> {
                        val data = readSpectrum()
                        if (data == null) {
                            result.success(null)
                        } else {
                            result.success(data)
                        }
                    }
                    "stop" -> {
                        stopVisualizer()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startVisualizer(sessionId: Int, requestedCaptureSize: Int): Boolean {
        if (sessionId <= 0) return false
        stopVisualizer()
        return try {
            val visualizer = Visualizer(sessionId)
            val range = Visualizer.getCaptureSizeRange()
            val requested = requestedCaptureSize
                .coerceAtLeast(range[0])
                .coerceAtMost(range[1])
            val captureSize = Integer.highestOneBit(requested)
                .coerceIn(range[0], range[1])
            visualizer.setCaptureSize(captureSize)
            visualizer.setScalingMode(Visualizer.SCALING_MODE_NORMALIZED)
            visualizer.enabled = true
            visualizers[sessionId] = visualizer
            true
        } catch (_: SecurityException) {
            false
        } catch (_: RuntimeException) {
            false
        } catch (_: UnsupportedOperationException) {
            false
        }
    }

    private fun readSpectrum(): Map<String, Any>? {
        val visualizer = visualizers.values.firstOrNull() ?: return null
        return try {
            if (!visualizer.enabled) return null
            val fft = ByteArray(visualizer.captureSize)
            if (visualizer.getFft(fft) != Visualizer.SUCCESS) return null

            val magnitudes = ArrayList<Double>(fft.size / 2 + 1)
            magnitudes.add(kotlin.math.abs(fft[0].toInt()).toDouble())
            for (index in 1 until fft.size / 2) {
                val real = fft[index * 2].toInt()
                val imaginary = fft[index * 2 + 1].toInt()
                magnitudes.add(hypot(real.toDouble(), imaginary.toDouble()))
            }
            magnitudes.add(kotlin.math.abs(fft[1].toInt()).toDouble())

            mapOf(
                "magnitudes" to magnitudes,
                "sampleRateHz" to visualizer.samplingRate / 1000,
                "captureSize" to visualizer.captureSize
            )
        } catch (_: IllegalStateException) {
            null
        } catch (_: RuntimeException) {
            null
        }
    }

    private fun stopVisualizer() {
        val current = visualizers.values.toList()
        visualizers.clear()
        current.forEach { visualizer ->
            try {
                visualizer.enabled = false
            } catch (_: RuntimeException) {
            }
            try {
                visualizer.release()
            } catch (_: RuntimeException) {
            }
        }
    }

    override fun onDestroy() {
        stopVisualizer()
        super.onDestroy()
    }
}
