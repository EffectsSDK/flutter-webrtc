import 'dart:io' show Platform;

import '../../flutter_webrtc.dart';

import '../effects_sdk_image.dart';

import '../effects_sdk_base.dart';

class VideoEffectsSdkImpl extends VideoEffectsSdkBase {

@override
void initialize(
    String customerID, 
    {bool preload = true, VideoEffectSDKConfig? config}) {}

@override
Future<AuthStatus> auth(
      MediaStreamTrack mediaStreamTrack, String customerID,
      {String? apiUrl}) async {
    String status = await WebRTC.invokeMethod(
      'auth',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'customerKey': customerID,
        'apiUrl': apiUrl
      },
    );
    return parseJavaAuthStatus(status);
}

@override
Future<AuthStatus> localAuth(
    MediaStreamTrack mediaStreamTrack,
    String localKey
  ) async {
    String status = await WebRTC.invokeMethod(
      'localAuth',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'localKey': localKey},
    );
    return parseJavaAuthStatus(status);
}

@override
Future<MediaStream> wrapStream(MediaStream stream) async
{
  return stream;
}

@override
Future<MediaStream?> getWrappedStream(MediaStream stream) async {
  return null;
}

@override
Future<PipelineMode> getPipelineMode(
      MediaStreamTrack mediaStreamTrack) async {
    String mode = await WebRTC.invokeMethod(
      'getPipelineMode',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
    return parseJavaPipelineMode(mode);
}

@override
Future<void> setPipelineMode(
      MediaStreamTrack mediaStreamTrack, PipelineMode pipelineMode) async {
    await WebRTC.invokeMethod(
      'setPipelineMode',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'pipelineMode': pipelineMode.toString()
      },
    );
}

@override
Future<void> setBlurPower(
      MediaStreamTrack mediaStreamTrack,
      double power) async {
    await WebRTC.invokeMethod(
      'setBlurPower',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'blurPower': power},
    );
}

@override
Future<void> setBackgroundImage(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  ) async {
    await WebRTC.invokeMethod(
      'setBackgroundImage',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'image': _serializeImage(image)
      },
    );
}

@override
Future<void> enableBeautification(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    await WebRTC.invokeMethod(
      'enableBeautification',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'enable': enable},
    );
}

@override
Future<bool> isBeautificationEnabled(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'isBeautificationEnabled',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
}

@override
Future<void> setBeautificationPower(
    MediaStreamTrack mediaStreamTrack,
    double power,
  ) async {
    await WebRTC.invokeMethod(
      'setBeautificationPower',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'beautificationPower': power
      },
    );
}

@override
Future<double> getZoomLevel(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'getZoomLevel',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
}

@override
Future<void> setZoomLevel(
    MediaStreamTrack mediaStreamTrack,
    double zoomLevel,
  ) async {
    await WebRTC.invokeMethod(
      'setZoomLevel',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'zoomLevel': zoomLevel},
    );
}

@override
Future<void> enableSharpening(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    await WebRTC.invokeMethod(
      'enableSharpening',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'enable': enable},
    );
}

@override
Future<double> getSharpeningStrength(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'getSharpeningStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
}

@override
Future<void> setSharpeningStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) async {
    await WebRTC.invokeMethod(
      'setSharpeningStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'strength': strength},
    );
}

@override
Future<void> setColorCorrectionMode(
    MediaStreamTrack mediaStreamTrack,
    ColorCorrectionMode colorCorrectionMode,
  ) async {
    await WebRTC.invokeMethod(
      'setColorCorrectionMode',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'colorCorrectionMode': colorCorrectionMode.toString()
      },
    );
}

@override
Future<void> setColorFilterStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) async {
    await WebRTC.invokeMethod(
      'setColorFilterStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'strength': strength},
    );
}

@override
Future<void> setColorGradingReference(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  ) async {
    await WebRTC.invokeMethod(
      'setColorGradingReferenceImage',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'reference': _serializeImage(image)
      },
    );
}

@override
Future<void> enableNoiseSuppression(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    _ensureAndroid('enableNoiseSuppression');
    await WebRTC.invokeMethod(
      'enableNoiseSuppression',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'enable': enable},
    );
}

@override
Future<void> enablePortraitLighting(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    _ensureAndroid('enablePortraitLighting');
    await WebRTC.invokeMethod(
      'enablePortraitLighting',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'enable': enable},
    );
}

@override
Future<void> setPortraitLightingOptions(
    MediaStreamTrack mediaStreamTrack,
    PortraitLightingOptions options,
  ) async {
    _ensureAndroid('setPortraitLightingOptions');
    await WebRTC.invokeMethod(
      'setPortraitLightingOptions',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'options': options.toMap()
      },
    );
}

@override
Future<void> setLowLightConfig(
    MediaStreamTrack mediaStreamTrack,
    LowLightConfig config,
  ) async {
    _ensureAndroid('setLowLightConfig');
    await WebRTC.invokeMethod(
      'setLowLightConfig',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'config': config.toMap()
      },
    );
}

@override
Future<void> setLowLightPower(
    MediaStreamTrack mediaStreamTrack,
    double power,
  ) async {
    _ensureAndroid('setLowLightPower');
    await WebRTC.invokeMethod(
      'setLowLightPower',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'power': power},
    );
}

@override
Future<void> setColorCorrectionConfig(
    MediaStreamTrack mediaStreamTrack,
    ColorCorrectionConfig config,
  ) async {
    _ensureAndroid('setColorCorrectionConfig');
    await WebRTC.invokeMethod(
      'setColorCorrectionConfig',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'config': config.toMap()
      },
    );
}

@override
Future<void> setColorCorrectionPower(
    MediaStreamTrack mediaStreamTrack,
    double power,
  ) async {
    _ensureAndroid('setColorCorrectionPower');
    await WebRTC.invokeMethod(
      'setColorCorrectionPower',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'power': power},
    );
}

@override
Future<void> setColorCorrectionPeriod(
    MediaStreamTrack mediaStreamTrack,
    double periodMs,
  ) async {
    _ensureAndroid('setColorCorrectionPeriod');
    await WebRTC.invokeMethod(
      'setColorCorrectionPeriod',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'periodMs': periodMs},
    );
}

/// Features added in Android SDK 2.15 are not implemented for iOS yet.
void _ensureAndroid(String method) {
    if (!Platform.isAndroid) {
      throw UnimplementedError('$method is currently supported only on Android.');
    }
}

/// Serializes [EffectsSdkImage] to platform-specific format.
Map<String, dynamic> _serializeImage(EffectsSdkImage image) {
    switch (image.source) {
      case FilePathImage s:
        return <String, dynamic>{"type": "filepath", "path": s.path};
      case EncodedImageData s:
        return <String, dynamic>{"type": "encoded", "data": s.data};
      case SolidRGBImage(r: final r, g: final g, b: final b):
        return <String, dynamic>{"type": "rgb", "r": r, "g": g, "b": b};
      case RawImage s:
        return <String, dynamic>{
          "type": "raw",
          "data": s.data,
          "format": s.format.name,
          "width": s.width,
          "height": s.height,
          "stride": s.bytesPerRow
        };
      case UrlImage _:
        throw UnsupportedError('EffectsSdkImage.fromURL is not supported on this platform');
    }
}

}