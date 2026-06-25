package com.cloudwebrtc.webrtc.video.camera

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import android.util.Size
import android.view.Surface
import com.effectssdk.tsvb.Camera
import com.effectssdk.tsvb.EffectsSDK
import com.effectssdk.tsvb.EffectsSDKStatus
import com.effectssdk.tsvb.pipeline.CameraPipeline
import com.effectssdk.tsvb.pipeline.ColorCorrectionMode
import com.effectssdk.tsvb.pipeline.PipelineMode
import org.webrtc.CameraEnumerator
import org.webrtc.CameraVideoCapturer
import org.webrtc.CameraVideoCapturer.CameraEventsHandler
import org.webrtc.CapturerObserver
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoFrame
import java.net.URL


/**
 * Custom video capturer for Effects SDK
 */
class EffectsSDKVideoCapturer(
    private val device: String,
    private val eventsHandler: CameraEventsHandler,
    enumerator: CameraEnumerator
) : CameraVideoCapturer {

    @Volatile private var isPipelineCameraUsed: Boolean = false
    //Set once dispose() runs. Guards against the async pipeline creation
    //callback firing after the capturer was already disposed.
    @Volatile private var disposed = false
    //Guards the disposed flag together with the cameraPipeline lifecycle so the
    //check-and-assign in the creation callback can't interleave with dispose().
    private val pipelineLock = Any()
    private var context: Context? = null
    private var capturerObserver: CapturerObserver? = null
    //Default WebRTC capturer. Used until EffectsSDK not ready to provide frames
    //You can remove this if you don't need non-processed frames
    private var webRtcCameraCapturer: CameraVideoCapturer? = null

    @Volatile private var cameraPipeline: CameraPipeline? = null
    private val currentPipelineOptions = EffectsSdkOptionsCache()
	private var selectedCamera = Camera.FRONT

    private var width = 720
    private var height = 1280

    private var surfaceTextureHelper: SurfaceTextureHelper? = null
    private var surface: Surface? = null
    private var framesActive = false

    init {
        //Custom event handler. Used until EffectsSDK not ready to provide frames
        val cameraEventHandler = object : CameraEventsHandler {
            override fun onCameraError(p0: String?) {
                if (!isPipelineCameraUsed) eventsHandler.onCameraError(p0)
            }

            override fun onCameraDisconnected() {
                if (!isPipelineCameraUsed) eventsHandler.onCameraDisconnected()
            }

            override fun onCameraFreezed(p0: String?) {
                if (!isPipelineCameraUsed) eventsHandler.onCameraFreezed(p0)
            }

            override fun onCameraOpening(p0: String?) {
                if (!isPipelineCameraUsed) eventsHandler.onCameraOpening(p0)
            }

            override fun onFirstFrameAvailable() {
                if (!isPipelineCameraUsed) eventsHandler.onFirstFrameAvailable()
            }

            override fun onCameraClosed() {
                if (!isPipelineCameraUsed) eventsHandler.onCameraClosed()
            }

        }
        webRtcCameraCapturer = enumerator.createCapturer(device, cameraEventHandler)
    }

    override fun initialize(
        surfaceTextureHelper: SurfaceTextureHelper?,
        context: Context?,
        observer: CapturerObserver?
    ) {
        if (!isPipelineCameraUsed) {
            //Custom Capturer observer. Used until EffectsSDK not ready to provide frames
            val nativeCapturerObserver = object : CapturerObserver {
                override fun onCapturerStarted(p0: Boolean) {
                    if (!isPipelineCameraUsed) capturerObserver?.onCapturerStarted(p0)
                }

                override fun onCapturerStopped() {
                    if (!isPipelineCameraUsed) capturerObserver?.onCapturerStopped()

                }

                override fun onFrameCaptured(p0: VideoFrame?) {
                    if (!isPipelineCameraUsed) capturerObserver?.onFrameCaptured(p0)
                }
            }
            webRtcCameraCapturer?.initialize(surfaceTextureHelper, context, nativeCapturerObserver)
        }
        this.surfaceTextureHelper = surfaceTextureHelper
        this.context = context
        capturerObserver = observer
    }


    override fun startCapture(width: Int, height: Int, framerate: Int) {
        this.width = width
        this.height = height
        if (!isPipelineCameraUsed) {
            webRtcCameraCapturer?.startCapture(width, height, framerate)
        } else {
            synchronized(pipelineLock) { startPipelineFrames() }
        }
    }

    override fun stopCapture() {
        if (!isPipelineCameraUsed) {
            webRtcCameraCapturer?.stopCapture()
        } else {
            synchronized(pipelineLock) { stopPipelineFrames() }
        }
    }

    private fun createPipeline() {
        val factory = EffectsSDK.createSDKFactory()
		selectedCamera = if (device == "1") Camera.FRONT else Camera.BACK
        factory.createCameraPipelineAsync(
            context!!,
			camera = selectedCamera,
            resolution = Size(width, height),
            mode = PipelineMode.REPLACE
        ) { pipeline ->
            synchronized(pipelineLock) {
                if (disposed) {
                    pipeline.release()
                    return@synchronized
                }
                cameraPipeline = pipeline
                isPipelineCameraUsed = true
                webRtcCameraCapturer?.stopCapture()
                webRtcCameraCapturer?.dispose()
                webRtcCameraCapturer = null
                currentPipelineOptions.isImageFlipped = (device == "1")
                startPipelineFrames()
            }
        }
    }

    fun enableVideo(enabled: Boolean) {
        synchronized(pipelineLock) {
            if (enabled) startPipelineFrames() else stopPipelineFrames()
        }
    }

    override fun changeCaptureFormat(width: Int, height: Int, framerate: Int) {
        if (!isPipelineCameraUsed) {
            webRtcCameraCapturer?.changeCaptureFormat(width, height, framerate)
        } else {
            synchronized(pipelineLock) {
                this.width = width
                this.height = height
                surfaceTextureHelper?.setTextureSize(width, height)
                cameraPipeline?.setResolution(Size(width, height))
            }
        }
    }

    override fun dispose() {
        synchronized(pipelineLock) {
            disposed = true

            if (framesActive) {
                surfaceTextureHelper?.stopListening()
                framesActive = false
            }
            cameraPipeline?.stopPipeline()
            cameraPipeline?.setSurfaceOutput(null)
            cameraPipeline?.release()
            cameraPipeline = null

            surface?.release()
            surface = null
            surfaceTextureHelper = null

            webRtcCameraCapturer?.dispose()
            webRtcCameraCapturer = null

            capturerObserver = null
            context = null
            isPipelineCameraUsed = false
        }
    }

    override fun isScreencast(): Boolean {
        return false
    }

    override fun switchCamera(switchEventsHandler: CameraVideoCapturer.CameraSwitchHandler?) {
        if (!isPipelineCameraUsed) {
            webRtcCameraCapturer?.switchCamera(switchEventsHandler)
        } else {
            selectedCamera = if (selectedCamera == Camera.FRONT) Camera.BACK else Camera.FRONT
            cameraPipeline?.switchCamera(selectedCamera)
            switchEventsHandler?.onCameraSwitchDone(selectedCamera == Camera.FRONT)
        }
    }

    override fun switchCamera(
        switchEventsHandler: CameraVideoCapturer.CameraSwitchHandler?,
        cameraName: String?
    ) {
        if (!isPipelineCameraUsed) {
            webRtcCameraCapturer?.switchCamera(switchEventsHandler, cameraName)
        } else {
            //Device id "1" is the front camera (same mapping as createPipeline).
            selectedCamera = if (cameraName == "1") Camera.FRONT else Camera.BACK
            cameraPipeline?.switchCamera(selectedCamera)
            switchEventsHandler?.onCameraSwitchDone(selectedCamera == Camera.FRONT)
        }
    }

    private fun startPipelineFrames() {
        val pipeline = cameraPipeline ?: return
        val helper = surfaceTextureHelper ?: return
        pipeline.setResolution(Size(width, height))
        helper.setTextureSize(width, height)
        if (framesActive) return
        val output = surface ?: Surface(helper.surfaceTexture).also { surface = it }
        pipeline.setSurfaceOutput(output)
        pipeline.startPipeline()
        setPipelineOptionsFromCache(currentPipelineOptions)
        helper.startListening { frame -> capturerObserver?.onFrameCaptured(frame) }
        framesActive = true
    }

    private fun stopPipelineFrames() {
        if (!framesActive) return
        surfaceTextureHelper?.stopListening()
        cameraPipeline?.stopPipeline()
        framesActive = false
    }

    fun initializeEffectsSdk(customerId: String, url: String?, callback: EffectsSdkInitCallback) {
        EffectsSDK.initialize(context!!, customerId, url?.let { URL(it) }) { status ->
            if (status == EffectsSDKStatus.ACTIVE) {
                createPipeline()
            }
            callback.onResult(status)
        }
    }

    fun initializeEffectsSdkLocal(localKey: String): EffectsSDKStatus {
        return EffectsSDK.initialize(context!!, localKey)
    }

    fun setPipelineMode(pipelineMode: String) {
        var value: String = pipelineMode.split('.')[1]
        if (value == "noEffects") value = "no_effect"
        val mode: PipelineMode = PipelineMode.valueOf(value.uppercase())
        currentPipelineOptions.pipelineMode = mode
        cameraPipeline?.setMode(mode)
    }

    fun getPipelineMode(): PipelineMode? {
        return cameraPipeline?.getMode()
    }

    fun setBlurPower(blurPower: Float) {
        currentPipelineOptions.blurPower = blurPower
        cameraPipeline?.setBlurPower(blurPower)
    }

    fun enableBeautification(enableBeautification: Boolean) {
        currentPipelineOptions.isBeautificationEnabled = enableBeautification
        cameraPipeline?.enableBeautification(enableBeautification)
    }

    fun isBeautificationEnabled(): Boolean {
        return cameraPipeline?.isBeautificationEnabled()!!
    }

    fun setBeautificationPower(power: Double) {
        currentPipelineOptions.beautificationPower = power.toFloat()
        cameraPipeline?.setBeautificationPower(power.toFloat())
    }

    fun getZoomLevel(): Double {
        return (cameraPipeline?.getZoomLevel()!! / 100).toDouble()
    }

    fun setZoomLevel(zoomLevel: Double) {
        val intValue = (zoomLevel * 100).toInt()
        currentPipelineOptions.zoomLevel = intValue
        cameraPipeline?.setZoomLevel(intValue)
    }

    fun enableSharpening(enableSharpening: Boolean) {
        currentPipelineOptions.isSharpeningEnabled = enableSharpening
        cameraPipeline?.enableSharpening(enableSharpening)
    }

    fun getSharpeningStrength(): Double {
        return cameraPipeline?.getSharpeningStrength()!!.toDouble()
    }

    fun setSharpeningStrength(strength: Double) {
        currentPipelineOptions.sharpeningStrength = strength.toFloat()
        cameraPipeline?.setSharpeningStrength(strength.toFloat())
    }

    fun setColorCorrectionMode(mode: String) {
        val value: String = mode.split('.')[1]
        val colorCorrectionMode = when (value) {
            "noFilterMode" -> ColorCorrectionMode.NO_FILTER_MODE
            "colorCorrectionMode" -> ColorCorrectionMode.COLOR_CORRECTION_MODE
            "colorGradingMode" -> ColorCorrectionMode.COLOR_GRADING_MODE
            "presetMode" -> ColorCorrectionMode.PRESET_MODE
            "lowLightMode" -> ColorCorrectionMode.LOW_LIGHT_MODE
            else -> {
                Log.w(
                    this.javaClass.simpleName,
                    "Incorrect color correction constant value. NO_FILTER_MODE set."
                )
                ColorCorrectionMode.NO_FILTER_MODE
            }
        }
        currentPipelineOptions.colorCorrectionMode = colorCorrectionMode
        cameraPipeline?.setColorCorrectionMode(colorCorrectionMode)
        if (colorCorrectionMode == ColorCorrectionMode.LOW_LIGHT_MODE) {
            cameraPipeline?.updateLowLightLut()
        }
    }

    fun setColorFilterStrength(strength: Double) {
        currentPipelineOptions.colorFilterStrength = strength.toFloat()
        cameraPipeline?.setColorFilterStrength(strength.toFloat())
    }

    fun setColorGradingReference(bitmap: Bitmap) {
        currentPipelineOptions.colorGradingReference = bitmap
        cameraPipeline?.setColorGradingReferenceImage(bitmap)
    }

    fun setBackgroundBitmap(bitmap: Bitmap) {
        currentPipelineOptions.backgroundBitmap = bitmap
        cameraPipeline?.setBackground(bitmap)
    }

    private fun setPipelineOptionsFromCache(cache: EffectsSdkOptionsCache) {
        cameraPipeline?.let { pipeline ->
            pipeline.setFlipX(cache.isImageFlipped)
            pipeline.setMode(cache.pipelineMode)
            pipeline.setBlurPower(cache.blurPower)
            pipeline.setColorCorrectionMode(cache.colorCorrectionMode)
            pipeline.enableSharpening(cache.isSharpeningEnabled)
            pipeline.enableBeautification(cache.isBeautificationEnabled)
            pipeline.setBeautificationPower(cache.beautificationPower)
            pipeline.setColorFilterStrength(cache.colorFilterStrength)
            pipeline.setSharpeningStrength(cache.sharpeningStrength)
            pipeline.setZoomLevel(cache.zoomLevel)
            cache.backgroundBitmap?.let { img -> pipeline.setBackground(img) }
            cache.colorGradingReference?.let { img -> pipeline.setColorGradingReferenceImage(img) }
        }
    }

    fun interface EffectsSdkInitCallback {
        fun onResult(status: EffectsSDKStatus)
    }

    private data class EffectsSdkOptionsCache(
        var isImageFlipped: Boolean = false,
        var pipelineMode: PipelineMode = PipelineMode.NO_EFFECT,
        var blurPower: Float = 0f,
        var colorCorrectionMode: ColorCorrectionMode = ColorCorrectionMode.NO_FILTER_MODE,
        var isSharpeningEnabled: Boolean = false,
        var isBeautificationEnabled: Boolean = false,
        var beautificationPower: Float = 0f,
        var colorFilterStrength: Float = 0f,
        var sharpeningStrength: Float = 0f,
        var zoomLevel: Int = 0,
        var backgroundBitmap: Bitmap? = null,
        var colorGradingReference: Bitmap? = null
    )

}