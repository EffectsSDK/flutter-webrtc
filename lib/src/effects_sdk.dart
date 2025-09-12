import '../flutter_webrtc.dart';
import 'effects_sdk_base.dart';

import 'video_effects_sdk_stub.dart' 
  if (dart.library.js_interop) 'web/video_effects_sdk_impl.dart'
  if (dart.library.io) 'native/video_effects_sdk_impl.dart';

enum WebInferenceProvider {
  wasm,
  webgpu,
  auto
}

enum VideoEffect {
  virtual_background,
  smart_zoom, 
  low_light, 
  color_correction
}

enum SegmentationPreset {
  lightning, 
  speed,
  balanced,
  quality
}

/// Video Effects SDK configuration.
/// 
/// Currently applicable only for web.
class VideoEffectSDKConfig {
  VideoEffectSDKConfig({
    this.apiUrl,
    this.sdkUrl,
    this.modelUrl,
    this.preset,
    this.webInferenceProvider,
    this.effects,
    this.cacheModels,
    this.testInference,
    this.proxy,
    this.stats,
    this.models,
    this.wasmPaths,
  });

  /// Custom url for sdk authentication, applicable for on-premises solutions.
  String? apiUrl;

  // Web only

  /// Specifies the url to SDK folder in case when you host model files by yourself (Web only).
  String? sdkUrl;
  
  /// Specifies custom URL for the segmentation model; in most cases, this parameter does not require configuration.
  String? modelUrl;

  /// Specifies background segmentation preset (Currently Web Only)
  /// 
  /// [SegmentationPreset.balanced] by default.
  SegmentationPreset? preset;

  /// Specifies backend for ML inference. (Web only).
  /// 
  /// [WebInferenceProvider.auto] by default.
  WebInferenceProvider? webInferenceProvider;
  
  /// List of effects which should be loaded at initialization. (Web only)
  List<VideoEffect>? effects;

  /// Specifies to cache models locally, this will speed up the load time. (Web only)
  ///
  /// true by default.
  bool? cacheModels;

  /// If set to true, the SDK will test inference consistency on the WebGPU backend.
  /// 
  /// false by default.
  bool? testInference;

  /// Configuration specifies if segmentation should be working in separate worker thread (not in main UI thread), default value is true. (Web only)
  bool? proxy;

  /// Enabling/disabling statistics sending. (Web only).
  bool? stats;

  /// Ability to provide a custom path of model (Web only).
  ///
  /// ````
  /// final modelPaths = {
  ///   'colorcorrector': 'path',
  ///   'facedetector': 'path',
  ///   'lowlighter': 'path'
  /// };
  /// ````
  Map<String, String>? models;

  /// Currently wasm files are loading from the same directory where SDK is placed, but custom urls also supported (for example you can load it from CDNs) (Web only).
  /// 
  /// ````
  /// final paths = {
  ///   'ort-wasm.wasm': 'url',
  ///   'ort-wasm-simd.wasm': 'url',
  ///   'ort-wasm-threaded.wasm': 'url',
  ///   'ort-wasm-simd-threaded.wasm': 'url'
  /// };
  /// ````
  Map<String, String>? wasmPaths;
}

/// Video Effects SDK API class.
/// 
/// Video Effects SDK can only work with local video tracks.
class VideoEffectsSdk {
  /// Initializes Video Effects SDK for the web.
  ///
  /// Should be called before the first local camera stream created.
  /// For native platforms do nothing.
  /// - [customerID]: Unique customerID for authentication
  /// - [preload]: Start preloading models if true. 
  /// - [config]: Optional Web SDK configuration.
  static void initialize(String customerID, {bool preload = false, VideoEffectSDKConfig? config}) {
    _impl.initialize(customerID, preload: preload, config: config);
  }

  /// Authenticates SDK using remote service (Optional for the web).
  ///
  /// Method performs https request to obtain license for customerID.
  /// Optional if web platform 
  /// - [mediaStreamTrack]: Associated media track
  /// - [customerID]: Unique customerID for authentication
  /// - [apiUrl]: Optional custom authentication endpoint
  /// - Returns: [AuthStatus] indicating authentication result
  /// - Throws: Platform exceptions for communication errors
  static Future<AuthStatus> auth(
    MediaStreamTrack track,
    String customerID,
    {String? apiUrl}
  ) {
    return _impl.auth(track, customerID, apiUrl: apiUrl);
  }

  /// Offline authorization with a secret key.
  /// 
  /// Authorizes the Effects SDK instance similar to [auth], but performs license verification without web requests. 
  /// Internet connection is not required.
  /// - [mediaStreamTrack]: Associated media track
  /// - [localKey]: Unique client’s secret key. DO NOT reveal it.
  /// - Returns: [AuthStatus] indicating authentication result
  static Future<AuthStatus> localAuth(
    MediaStreamTrack mediaStreamTrack,
    String localKey
  ) {
    return _impl.localAuth(mediaStreamTrack, localKey);
  }

  /// Wraps stream to attack the SDK (For web only). 
  /// 
  /// Behavior different between platforms:
  /// * On web platform returns new stream with the sdk plugged in.
  /// * On native platforms returns the same stream. (does nothing with it).
  /// 
  /// The caller is responsible for disposing of both the original stream and the created stream.
  static Future<MediaStream> wrapStream(MediaStream stream) {
    return _impl.wrapStream(stream);
  }

  /// Returns original stream it was crated from.
  /// 
  /// This method can be used to get original stream to dispose it.
  static Future<MediaStream?> getWrappedStream(MediaStream stream) {
    return _impl.getWrappedStream(stream);
  }

  /// Gets the current background processing mode for a media track.
  ///
  /// - [mediaStreamTrack]: The target media track
  /// - Returns: Current [PipelineMode]
  /// - Throws: [Exception] if native method fails or returns unknown value
  static Future<PipelineMode> getPipelineMode(MediaStreamTrack mediaStreamTrack) {
    return _impl.getPipelineMode(mediaStreamTrack);
  }

  /// Sets background processing mode for a media track.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [pipelineMode]: New processing mode to apply
  static Future<void> setPipelineMode(
      MediaStreamTrack mediaStreamTrack, PipelineMode pipelineMode) {
    return _impl.setPipelineMode(mediaStreamTrack, pipelineMode);
  }

  /// Adjusts blur strength for background blur mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [power]: Blur strength (0.0 - 1.0 where 1.0 is maximum blur)
  static Future<void> setBlurPower(
    MediaStreamTrack mediaStreamTrack,
    double power
  ) {
    return _impl.setBlurPower(mediaStreamTrack, power);
  }

  /// Sets custom background image for replace mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [image]: Image to use as background
  /// - See also: [EffectsSdkImage] for supported image types
  static Future<void> setBackgroundImage(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  ) {
    return _impl.setBackgroundImage(mediaStreamTrack, image);
  }

  /// Enables/disables face beautification effects.
  ///
  /// Improves the appearance of the human face.
  /// - [mediaStreamTrack]: Target media track
  /// - [enable]: true to enable, false to disable
  static Future<void> enableBeautification(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) {
    return _impl.enableBeautification(mediaStreamTrack, enable);
  }

  /// Checks if beautification is currently enabled.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current enabled status
  static Future<bool> isBeautificationEnabled(
      MediaStreamTrack mediaStreamTrack) {
    return _impl.isBeautificationEnabled(mediaStreamTrack);
  }

  /// Adjusts beautification effect strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [power]: Effect strength (0.0 - 1.0)
  static Future<void> setBeautificationPower(
    MediaStreamTrack mediaStreamTrack,
    double power,
  ) {
    return _impl.setBeautificationPower(mediaStreamTrack, power);
  }

  /// Gets current smart zoom level.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current zoom level 
  static Future<double> getZoomLevel(
      MediaStreamTrack mediaStreamTrack) {
    return _impl.getZoomLevel(mediaStreamTrack);
  }

  /// Sets smart zoom level.
  ///
  /// When level > 0, crops around the face, 1 means that the face is zoomed into the entire frame.
  /// - [mediaStreamTrack]: Target media track
  /// - [zoomLevel]: zoomLevel (0 - 1)
  static Future<void> setZoomLevel(
    MediaStreamTrack mediaStreamTrack,
    double zoomLevel,
  ) {
    return _impl.setZoomLevel(mediaStreamTrack, zoomLevel);
  }

  /// Enables/disables image sharpening.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [enable]: true to enable, false to disable
  static Future<void> enableSharpening(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ){
    return _impl.enableSharpening(mediaStreamTrack, enable);
  }

  /// Gets current sharpening strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current sharpening strength (0.0 - 1.0)
  static Future<double> getSharpeningStrength(
      MediaStreamTrack mediaStreamTrack) {
    return _impl.getSharpeningStrength(mediaStreamTrack);
  }

  /// Adjusts image sharpening strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [strength]: New sharpening strength (0.0 - 1.0), 0 is minimal sharpening (there is still visible effect), 1 is maximal
  static Future<void> setSharpeningStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) {
    return _impl.setSharpeningStrength(mediaStreamTrack, strength);
  }

  /// Sets color correction processing mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [colorCorrectionMode]: New color processing mode
  static Future<void> setColorCorrectionMode(
    MediaStreamTrack mediaStreamTrack,
    ColorCorrectionMode colorCorrectionMode,
  ) {
    return _impl.setColorCorrectionMode(mediaStreamTrack, colorCorrectionMode);
  }

  /// Adjusts color filter strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [strength]: Filter intensity (0.0 - 1.0)
  static Future<void> setColorFilterStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) {
    return _impl.setColorFilterStrength(mediaStreamTrack, strength);
  }

  /// Sets reference image for color grading mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [image]: Reference image for color matching
  static Future<void> setColorGradingReference(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  )
  {
    return _impl.setColorGradingReference(mediaStreamTrack, image);
  }

  static final VideoEffectsSdkBase _impl = VideoEffectsSdkImpl();
}