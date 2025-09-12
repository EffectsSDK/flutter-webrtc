import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../flutter_webrtc.dart';
import '../effects_sdk_base.dart';

import '../effects_sdk_image.dart';

import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_webrtc/dart_webrtc.dart' as dart_rtc show MediaStreamWeb;
import 'package:dart_webrtc/src/media_stream_track_impl.dart' as dart_rtc show MediaStreamTrackWeb;
class FeatureDisabledError extends Error
{
  FeatureDisabledError(this.featureName);

  final String featureName;

  String toString() {
    return "Effects SDK Error: $featureName is disabled";
  }
}

enum WebErrorCode {
  NO_ERROR(0),
  UNKNOWN_ERROR(-1),
  CPU_FALLBACK(3001),
  SESSION_INITIALIZATION_SUCCESS(3020),
  EFFECT_INITIALIZATION_SUCCESS(3021),
  APP_CREATION_ISSUE(1002),
  NO_VIDEO_TRACK(1030),
  SESSION_INITIALIZATION_FAILED(1020),
  SESSION_INITIALIZATION_ISSUE(1021),
  GPU_DEVICE_LOST(1001),
  GPU_UNCAPTUREDERROR(1010),
  LOADER_ISSUE(1023),
  PRESET_ISSUE(1024),
  MODEL_INITIALIZATION_ISSUE(1022),
  EFFECT_INITIALIZATION_ISSUE(1025),
  INFERENCE_RUN_ISSUE(1040),
  RENDERING_ISSUE(1050);

  final int code;
  const WebErrorCode(this.code);

  factory WebErrorCode.fromCode(int code) {
    for (final value in WebErrorCode.values) {
      if (value.code == code) {
        return value;
      }
    }

    return WebErrorCode.UNKNOWN_ERROR;
  }
}

extension type VideoEffectsSdkJS._(JSObject _) implements JSObject {

  external void useStream(web.MediaStream stream);
  external web.MediaStream getStream();

  external void config(JSAny? config);
  external bool? run();
  external JSPromise preload();
  
  external bool? clearBlur();
  external bool? setBlur(double power);

  external void clearBackground();
  external void setBackground(JSAny? source);
  external void setBackgroundColor(double color);

  external bool? enableBeautification();
  external bool? disableBeautification();
  external bool? setBeautificationLevel(double level);

  external bool? enableColorCorrector();
  external bool? disableColorCorrector();
  external bool? setColorCorrectorPower(double power);

  external bool? enableSharpnessEffect();
  external bool? disableSharpnessEffect();
  external bool? setSharpnessEffectConfig(JSAny? config);

  external bool? enableSmartZoom();
  external bool? disableSmartZoom();
  external bool? setFaceArea(double power);

  external bool? enableLowLightEffect();
  external bool? disableLowLightEffect();
  external bool? setLowLightEffectPower(double power);

  external set onReady(JSFunction callback);
  external void onError(JSFunction callback);

  external void showFps();

  external ExternalDartReference<VideoEffectsSdkWebContext> getContextReference();
}

class EffectsSDKErrorJS {
  EffectsSDKErrorJS(this.jsError);

  final JSAny? jsError;

  String? get name {
    if (jsError.isA<JSObject>()) {
      return _toJSObject?.getProperty('name'.toJS).toString();
    }
  } 

  String? get message {
    return _toJSObject?.getProperty('message'.toJS).toString();
  }

  EffectsSDKErrorJS? get cause {
    final jsErrorCause = _toJSObject?.getProperty('cause'.toJS);
    if (null == jsErrorCause) {
      return null;
    }

    return EffectsSDKErrorJS(jsErrorCause);
  }

  JSObject? get _toJSObject {
    if (jsError.isA<JSObject>()) {
      return jsError as JSObject?;
    }

    return null;
  }

  @override
  String toString() {
    return 'Caught JavaScript error: $_toJSString';
  }

  String get _toJSString {
    final causedBy = cause;
    if (null == causedBy) {
      return jsError.toString();
    }

    return '${jsError.toString()} caused by ${causedBy._toJSString}';
  }

  EffectsSDKErrorJS get clone {
    return EffectsSDKErrorJS(jsError);
  }
}

EffectsSDKErrorJS jsErrorToDart(JSAny? error) {
  return EffectsSDKErrorJS(error);
}

extension type VideoEffectsSdkErrorJS._(JSObject _) implements JSObject {
  external String? get message;
  external JSNumber? get code;
  external String? get emitter;
  external JSAny? get cause;
}

extension VideoEffectsSdkErrorJSExt on VideoEffectsSdkErrorJS {
  WebErrorCode get errorCode {
    return WebErrorCode.fromCode(code?.toDartInt ?? 0);
  }
}

extension VideoEffectSDKConfigJSExt on VideoEffectSDKConfig {
  JSObject? toJSConfig() {
    final configMap = Map<String, dynamic>();
    void safeAssign(String key, dynamic value) {
      if (null != value) {
        configMap[key] = value;
      }
    }

    safeAssign('api_url', this.apiUrl);
    safeAssign('model_url', this.modelUrl);
    safeAssign('sdk_url', this.sdkUrl);
    safeAssign('preset', this.preset?.name);
    safeAssign('effects', this.effects?.map((e)=>e.name));
    safeAssign('proxy', this.proxy);
    safeAssign('provider', this.webInferenceProvider?.name);
    safeAssign('stats', this.stats);
    safeAssign('cache_models', this.cacheModels);
    safeAssign('test_inference', this.testInference);
    safeAssign('models', this.models);
    safeAssign('wasmPaths', this.wasmPaths);

    final result = configMap.jsify() as JSObject?;
    if (null == result) {
      throw 'Failure to convert the config to JS config';
    }
    return result;
  }
}

class VideoEffectsSdkWebContext {
  VideoEffectsSdkWebContext(this.jsContext, this.globalContext) {
    void callback(){
      ready = true;
      jsContext.run();
      final callbacks = readyCallbacks;
      readyCallbacks = [];
      for (final cb in callbacks) {
        cb();
      }
    }
    jsContext.onReady = callback.toJS;
  }

  VideoEffectsSdkJS jsContext;
  VideoEffectsSdkImpl globalContext;

  MediaStream? originalStream;

  bool ready = false;
  List<Function> readyCallbacks = [];
  PipelineMode pipelineMode = PipelineMode.noEffects;
  ColorCorrectionMode colorCorrectionMode = ColorCorrectionMode.noFilterMode;
  bool beautificationEnabled = false;
  bool smartZoomEnabled = false;

  double blurPower = 0.7;
  double smartZoomLevel = 0;
  double sharpeningStrength = 0;
  EffectsSdkImage? backgroundImage = null;

  Future<T> callWhenReady<T>(FutureOr<T> Function() functor) {
    if (ready) {
      return Future.sync(functor);
    }

    final completer = Completer<T>();
    readyCallbacks.add((){
      final result = functor();
      completer.complete(result);
    });

    return completer.future;
  }

  Future<void> getReady() {
    return callWhenReady((){});
  }
}

class VideoEffectsSdkImpl extends VideoEffectsSdkBase {
  static final _videoContextSymbol = "VideoEffectsSDK_Context".toJS;
  String? _customerID;
  
  EffectsSDKErrorJS? _initializationError;

  List<Future<void> Function()> _taskQueue = [];

  VideoEffectSDKConfig? _config;
  VideoEffectsSdkWebContext? _preloadContext = null;

  VideoEffectsSdkImpl() {
    if (!web.window.has('tsvb')) {
      throw StateError('tsvb has not been loaded.'
          ' Please, add <script src="https://effectssdk.ai/sdk/web/3.5.7/tsvb-web.js"></script> to your index.html');
    }
  }

  VideoEffectsSdkWebContext createContext(String customerID)
  {
    final tsvb = web.window['tsvb'] as JSFunction;
    VideoEffectsSdkJS jsContext = tsvb.callAsConstructor([customerID.toJS].toJS);
    void onError(VideoEffectsSdkErrorJS e){ this.onError(e); }
    jsContext.onError(onError.toJS);

    final context = VideoEffectsSdkWebContext(jsContext, this);
    final contextRef = context.toExternalReference;
    jsContext.setProperty("getContextReference".toJS, ((){
      return contextRef;
    }).toJS);
    return context;
  }

  @override
  void initialize(
      String customerID, 
      {bool preload = true, VideoEffectSDKConfig? config}) {
    _customerID = customerID;
    _config = config;
    if (!preload) {
      return;
    }

    _preloadContext = createContext(customerID);
    if (_config != null) {
      _preloadContext?.jsContext.config(config?.toJSConfig());
    }
    _preloadContext?.jsContext.preload();
    _config = null;
  }

  @override
  Future<AuthStatus> auth(MediaStreamTrack track, String customerID, {String? apiUrl}) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      await sdkContext.getReady();
      _throwIfError();
      return AuthStatus.active;
    });
  }

  @override
  Future<MediaStream> wrapStream(MediaStream stream) async {
    if (null == _customerID) {
      throw StateError("The Video Effects SDK is not initialized, use VideoEffectsSdk.initialize");
    }
    if (stream.getVideoTracks().isEmpty) {
      throw ArgumentError("The stream has no video track", "stream");
    }

    final sdkContext = _preloadContext ?? createContext(_customerID!);
    _preloadContext = null;
    if (null != _config) {
      sdkContext.jsContext.config(_config?.toJSConfig());
      _config = null;
    }
    final streamWeb = stream as dart_rtc.MediaStreamWeb;
    sdkContext.jsContext.useStream(streamWeb.jsStream);
    final sdkJsStream = sdkContext.jsContext.getStream();
    final sdkStream = dart_rtc.MediaStreamWeb(sdkJsStream, "local");
    _attachSDKContextToStream(sdkContext, sdkStream);
    sdkContext.originalStream = stream;
    return sdkStream;
  }

  @override
  Future<MediaStream?> getWrappedStream(MediaStream stream) async {
    try {
      return _getSDKContext(stream).originalStream;
    }
    catch (_) {
      return null;
    }
  }

  @override
  Future<void> enableBeautification(MediaStreamTrack track, bool enable) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      if (sdkContext.beautificationEnabled == enable) {
        return;
      }

      await sdkContext.getReady();
      bool ok = enable? 
        sdkContext.jsContext.enableBeautification() ?? false : 
        sdkContext.jsContext.disableBeautification() ?? false;
      if (!ok) {
        throw FeatureDisabledError("Beautification");
      }
      sdkContext.beautificationEnabled = enable;
    });
  }

  @override
  Future<bool> isBeautificationEnabled(MediaStreamTrack track) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      return sdkContext.beautificationEnabled;
    });
  }

  @override
  Future<void> enableSharpening(MediaStreamTrack track, bool enable) async {
      return _enqueue(() async {
        final sdkContext = _getSDKContext(track);
        await sdkContext.getReady();
        bool ok = enable? 
          sdkContext.jsContext.enableSharpnessEffect() ?? false : 
          sdkContext.jsContext.disableSharpnessEffect() ?? false;
        if (!ok) {
          throw FeatureDisabledError("Sharpening");
        }
    });
  }

  @override
  Future<PipelineMode> getPipelineMode(MediaStreamTrack track) {
    return _enqueue((){
      final sdkContext = _getSDKContext(track);
      return sdkContext.pipelineMode;
    });
  }

  @override
  Future<void> setPipelineMode(MediaStreamTrack track, PipelineMode pipelineMode) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      if (sdkContext.pipelineMode == pipelineMode) {
        return;
      }
      await sdkContext.getReady();
      _throwIfError();

      switch (pipelineMode) {
      case PipelineMode.noEffects:
        sdkContext.jsContext.clearBlur();
        sdkContext.jsContext.clearBackground();
        sdkContext.pipelineMode = pipelineMode;
        break;
      case PipelineMode.replace:
        await _setBackground(track, sdkContext.backgroundImage);
        sdkContext.jsContext.clearBlur();
        sdkContext.pipelineMode = pipelineMode;
        break;
      case PipelineMode.blur:
        bool ok = sdkContext.jsContext.setBlur(sdkContext.blurPower) ?? false;
        if (!ok) {
          throw FeatureDisabledError("BackgroundBlur");
        }
        sdkContext.jsContext.clearBackground();
        sdkContext.pipelineMode = pipelineMode;
        break;
      }
    });
  }

  @override
  Future<AuthStatus> localAuth(MediaStreamTrack track, String localKey) {
    throw UnsupportedError("Offline Authorization is unsupported on web");
  }

  @override
  Future<void> setBackgroundImage(MediaStreamTrack track, EffectsSdkImage image) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      if (PipelineMode.replace != sdkContext.pipelineMode) {
        sdkContext.backgroundImage = image;
        return;
      }

      await _setBackground(track, image);
      sdkContext.backgroundImage = image;      
    });
  }

  @override
  Future<void> setBeautificationPower(MediaStreamTrack mediaStreamTrack, double power)  {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(mediaStreamTrack);
      await sdkContext.getReady();
      sdkContext.jsContext.setBeautificationLevel(power);
    });
  }

  @override
  Future<void> setBlurPower(MediaStreamTrack mediaStreamTrack, double power) {
    return _enqueue((){
      final sdkContext = _getSDKContext(mediaStreamTrack);
      sdkContext.blurPower = power;
      if (PipelineMode.blur == sdkContext.pipelineMode) {
        sdkContext.jsContext.setBlur(power);
      }
    });
  }

  @override
  Future<void> setColorCorrectionMode(MediaStreamTrack track, ColorCorrectionMode colorCorrectionMode) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      if (colorCorrectionMode == sdkContext.colorCorrectionMode) {
        return;
      }
      await sdkContext.getReady();
      _throwIfError();

      switch(colorCorrectionMode) {
        case ColorCorrectionMode.noFilterMode:
          sdkContext.jsContext.disableColorCorrector();
          sdkContext.jsContext.disableLowLightEffect();
          sdkContext.colorCorrectionMode = ColorCorrectionMode.noFilterMode;
          break;

        case ColorCorrectionMode.colorCorrectionMode: {
          bool ok = sdkContext.jsContext.enableColorCorrector() ?? false;
          if (!ok) {
            throw FeatureDisabledError("ColorCorrection");
          }
          sdkContext.jsContext.disableLowLightEffect();
          sdkContext.colorCorrectionMode = ColorCorrectionMode.colorCorrectionMode;
        } break;
          
        case ColorCorrectionMode.colorGradingMode:
          throw UnsupportedError("Color Grading is unsupported on Web");

        case ColorCorrectionMode.lowLightMode:{
          bool ok = sdkContext.jsContext.enableLowLightEffect() ?? false;
          if (!ok) {
            throw FeatureDisabledError("LowLightAdjustment");
          }
          sdkContext.jsContext.disableColorCorrector();
          sdkContext.colorCorrectionMode = ColorCorrectionMode.lowLightMode;
        } break;
      }
    });
  }

  @override
  Future<void> setColorFilterStrength(MediaStreamTrack track, double strength) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      await sdkContext.getReady();
      sdkContext.jsContext.setColorCorrectorPower(strength);
      sdkContext.jsContext.setLowLightEffectPower(strength);
    });
  }

  @override
  Future<void> setColorGradingReference(MediaStreamTrack mediaStreamTrack, EffectsSdkImage image) async {
    // Do nothing there, unsupported on Web.
  }

  @override
  Future<void> setSharpeningStrength(MediaStreamTrack track, double strength) async {
    final sdkContext = _getSDKContext(track);
    await sdkContext.getReady();
    sdkContext.jsContext.setSharpnessEffectConfig({"power": strength}.jsify());
    sdkContext.sharpeningStrength = strength;
  }

  @override
  Future<double> getSharpeningStrength(MediaStreamTrack track) async {
    final sdkContext = _getSDKContext(track);
    return sdkContext.sharpeningStrength;
  }

  @override
  Future<void> setZoomLevel(MediaStreamTrack track, double zoomLevel) {
    return _enqueue(() async {
      final sdkContext = _getSDKContext(track);
      zoomLevel = clampDouble(zoomLevel, 0, 1);
      if (0 == zoomLevel) {
        if (!sdkContext.smartZoomEnabled) {
          return;
        }
        
        sdkContext.jsContext.disableSmartZoom();
        sdkContext.smartZoomEnabled = false;
        sdkContext.smartZoomLevel = 0;
        return;
      }

      await sdkContext.getReady();
      if (!sdkContext.smartZoomEnabled) {
        final ok = sdkContext.jsContext.enableSmartZoom() ?? false;
        if (!ok) {
          throw FeatureDisabledError("SmartZoom");
        }
        sdkContext.smartZoomEnabled = true;
      }

      sdkContext.jsContext.setFaceArea(zoomLevel);
      sdkContext.smartZoomLevel = zoomLevel;
    });
  }

  @override
  Future<double> getZoomLevel(MediaStreamTrack track) {
    return _enqueue((){
      final sdkContext = _getSDKContext(track);
      return sdkContext.smartZoomLevel;
    });
  }

  void _attachSDKContextToStream(VideoEffectsSdkWebContext context, MediaStream stream) {
    final jsStream = (stream as dart_rtc.MediaStreamWeb).jsStream;
    jsStream.setProperty(_videoContextSymbol, context.jsContext);

    final videoTrack = stream.getVideoTracks().first;
    final jsTrack = (videoTrack as dart_rtc.MediaStreamTrackWeb).jsTrack;
    jsTrack.setProperty(_videoContextSymbol, context.jsContext);
  }

  VideoEffectsSdkWebContext _getSDKContext<T>(T object) {
    if (object is JSObject) {
      final value = (object as JSObject).getProperty(_videoContextSymbol);
      if (value.isUndefinedOrNull) {
        throw ArgumentError("The object has no attached context");
      }
      final context = (value as VideoEffectsSdkJS).getContextReference().toDartObject;
      return context;
    }

    if (object is MediaStreamTrack) {
      return _getSDKContext((object as dart_rtc.MediaStreamTrackWeb).jsTrack);
    }
    if (object is MediaStream) {
      return _getSDKContext((object as dart_rtc.MediaStreamWeb).jsStream);
    }

    throw ArgumentError("Unexpected object type");
  }

  Future<void> _setBackground(MediaStreamTrack track, EffectsSdkImage? image_) async {
    final sdkContext = _getSDKContext(track);
    final image = image_ ?? EffectsSdkImage.fromRGB(r: 0, g: 0, b: 0);

    switch (image.source) {
      case FilePathImage _:
        throw UnsupportedError("Filepath background is unsupported on Web");
      case EncodedImageData s:
        final dataUrl = dataUrlFromEncoded(encodedImage: s.data);
        sdkContext.jsContext.setBackground(dataUrl.toJS);
        break;
      case SolidRGBImage(r: final r, g: final g, b: final b):
        double colorNum = (r * 256 * 256 * 255) + (g * 256 * 255) + (b * 255);
        sdkContext.jsContext.setBackgroundColor(colorNum);
        sdkContext.jsContext.setBackground('color'.toJS);
        break;
      case RawImage s:
        final dataUrl = await dataUrlFromRaw(raw: s);
        sdkContext.jsContext.setBackground(dataUrl.toJS);
        break;
      case UrlImage(url: final url):
        sdkContext.jsContext.setBackground(url.toJS);
        break;
    }
  }

  Future<web.ImageBitmap> toBitmap(RawImage image) async {
    final clamped = Uint8ClampedList.view(image.data.buffer);
    final imageData = web.ImageData(clamped.toJS, image.width, image.height.toJS);
    return web.window.createImageBitmap(imageData).toDart;
  }

  String dataUrlFromEncoded({required Uint8List encodedImage}) {
    final base64Data = Base64Encoder().convert(encodedImage);
    final mimeType = getImageMIMEType(encodedImage);
    final dataUrl = 'data:$mimeType;base64,$base64Data';
    return dataUrl;
  }

  Future<String> dataUrlFromRaw({required RawImage raw}) async {
    final bitmap = await toBitmap(raw);
    final canvas = web.HTMLCanvasElement();
    final bitmapRenderer = canvas.getContext('bitmaprenderer') as web.ImageBitmapRenderingContext?;
    bitmapRenderer?.transferFromImageBitmap(bitmap);
    return canvas.toDataURL();
  }

  String getImageMIMEType(Uint8List encodedImage) {
    final mimeTypes = {
        '89504e47': 'image/png',
        '49492a00': 'image/tiff',
        '4d4d002a': 'image/tiff'
    };

    final hex = encodedImage.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (hex.startsWith('ffd8ff')) {
      return 'image/jpeg';
    }

    return mimeTypes[hex] ?? "image/*";
  }

  Future<T> _enqueue<T>(FutureOr<T> Function() task) {
    final completer = Completer<T>();
    Future<void> wrapper() async {
      try {
        final result = await task();
        completer.complete(result);
      }
      catch (e) {
        completer.completeError(e);
      }
    };
    _taskQueue.add(wrapper);
    if (_taskQueue.length == 1) {
      _runQueue();
    }
    return completer.future;
  }

  void _runQueue() async {
    while(_taskQueue.isNotEmpty) {
      final task = _taskQueue.first;
      await task();
      _taskQueue.removeAt(0);
    }
  }

  void _throwIfError() {
    if (null != _initializationError) {
      throw _initializationError!.clone;
    }
  }

  void onError(VideoEffectsSdkErrorJS e) {
    switch(e.errorCode) {
      case WebErrorCode.SESSION_INITIALIZATION_FAILED:
      case WebErrorCode.SESSION_INITIALIZATION_ISSUE:
      case WebErrorCode.MODEL_INITIALIZATION_ISSUE:
      case WebErrorCode.EFFECT_INITIALIZATION_ISSUE:
        _initializationError ??= jsErrorToDart(e.cause);
        break;
      default: break;
    }
  }
}