package com.peakvision.between_us

import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.post { applyHighRefreshRatePreference() }
    }

    private fun applyHighRefreshRatePreference() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            Log.i(TAG, "Display modes are unavailable below Android M; keeping system default refresh rate.")
            return
        }

        val refreshRates = getSupportedDisplayModes()
            .map { it.refreshRate }
            .distinct()
            .sorted()

        if (refreshRates.isEmpty()) {
            Log.i(TAG, "No display refresh rates reported; keeping system default refresh rate.")
            return
        }

        val preferredRefreshRate = refreshRates
            .filter { it > STANDARD_REFRESH_RATE }
            .maxOrNull()

        if (preferredRefreshRate == null) {
            Log.i(
                TAG,
                "Available refresh rates=${refreshRates.joinToString()}; no rate above ${STANDARD_REFRESH_RATE}Hz.",
            )
            return
        }

        val attributes = window.attributes
        attributes.preferredRefreshRate = preferredRefreshRate
        window.attributes = attributes

        Log.i(
            TAG,
            "Available refresh rates=${refreshRates.joinToString()}; selected preferredRefreshRate=$preferredRefreshRate.",
        )

        applySurfaceFrameRate(preferredRefreshRate)
    }

    @Suppress("DEPRECATION")
    private fun getSupportedDisplayModes(): Array<Display.Mode> {
        val currentDisplay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            windowManager.defaultDisplay
        }

        return currentDisplay?.supportedModes ?: emptyArray()
    }

    private fun applySurfaceFrameRate(refreshRate: Float) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            Log.i(TAG, "Surface frame rate API is unavailable below Android R.")
            return
        }

        val surfaceView = findSurfaceView(window.decorView)

        if (surfaceView == null) {
            Log.i(TAG, "No SurfaceView found for frame rate hint; preferredRefreshRate remains applied.")
            return
        }

        val holder = surfaceView.holder

        holder.addCallback(
            object : SurfaceHolder.Callback {
                override fun surfaceCreated(surfaceHolder: SurfaceHolder) {
                    setSurfaceFrameRate(surfaceHolder.surface, refreshRate)
                }

                override fun surfaceChanged(
                    surfaceHolder: SurfaceHolder,
                    format: Int,
                    width: Int,
                    height: Int,
                ) {
                    setSurfaceFrameRate(surfaceHolder.surface, refreshRate)
                }

                override fun surfaceDestroyed(surfaceHolder: SurfaceHolder) = Unit
            },
        )

        setSurfaceFrameRate(holder.surface, refreshRate)
    }

    private fun setSurfaceFrameRate(surface: Surface?, refreshRate: Float) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return
        }

        if (surface?.isValid != true) {
            Log.i(TAG, "Surface is not ready; frame rate hint will be applied when it is created.")
            return
        }

        surface.setFrameRate(refreshRate, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
        Log.i(TAG, "Applied Surface frame rate hint=$refreshRate.")
    }

    private fun findSurfaceView(view: View): SurfaceView? {
        if (view is SurfaceView) {
            return view
        }

        if (view !is ViewGroup) {
            return null
        }

        for (index in 0 until view.childCount) {
            val surfaceView = findSurfaceView(view.getChildAt(index))
            if (surfaceView != null) {
                return surfaceView
            }
        }

        return null
    }

    private companion object {
        private const val TAG = "BetweenUsRefreshRate"
        private const val STANDARD_REFRESH_RATE = 60f
    }
}
