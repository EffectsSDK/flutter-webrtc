import '../flutter_webrtc.dart';
import 'effects_sdk_base.dart';

class VideoEffectsSdkImpl extends VideoEffectsSdkBase {

@override
void initialize(
    String customerID, 
    {bool preload = true, VideoEffectSDKConfig? config}) {}

@override
Future<AuthStatus> auth(
      MediaStreamTrack mediaStreamTrack, String customerID,
      {String? apiUrl}) async {
    return AuthStatus.error;
}

@override
Future<AuthStatus> localAuth(
    MediaStreamTrack mediaStreamTrack,
    String localKey
  ) async {
    return AuthStatus.error;
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
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setPipelineMode(
      MediaStreamTrack mediaStreamTrack, PipelineMode pipelineMode) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setBlurPower(
      MediaStreamTrack mediaStreamTrack,
      double power) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setBackgroundImage(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> enableBeautification(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<bool> isBeautificationEnabled(
      MediaStreamTrack mediaStreamTrack) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setBeautificationPower(
    MediaStreamTrack mediaStreamTrack,
    double power,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<double> getZoomLevel(
      MediaStreamTrack mediaStreamTrack) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setZoomLevel(
    MediaStreamTrack mediaStreamTrack,
    double zoomLevel,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> enableSharpening(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<double> getSharpeningStrength(
      MediaStreamTrack mediaStreamTrack) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setSharpeningStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setColorCorrectionMode(
    MediaStreamTrack mediaStreamTrack,
    ColorCorrectionMode colorCorrectionMode,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setColorFilterStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

@override
Future<void> setColorGradingReference(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  ) async {
    throw UnimplementedError("Unimplemented for this platform.");
}

}