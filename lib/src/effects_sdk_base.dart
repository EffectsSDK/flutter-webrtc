import 'package:flutter/foundation.dart';

import '../flutter_webrtc.dart';
import 'effects_sdk.dart';

abstract class VideoEffectsSdkBase {
  void initialize(String customerID, {bool preload = false, VideoEffectSDKConfig? config});

  Future<AuthStatus> auth(
    MediaStreamTrack track,
    String customerID,
    {String? apiUrl}
  );

  Future<AuthStatus> localAuth(
    MediaStreamTrack mediaStreamTrack,
    String localKey
  );

  Future<MediaStream> wrapStream(MediaStream stream);

  Future<MediaStream?> getWrappedStream(MediaStream stream);

  Future<PipelineMode> getPipelineMode(MediaStreamTrack mediaStreamTrack);

  Future<void> setPipelineMode(
      MediaStreamTrack mediaStreamTrack, 
      PipelineMode pipelineMode);

  Future<void> setBlurPower(
    MediaStreamTrack mediaStreamTrack,
    double power
  );

  Future<void> setBackgroundImage(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  );

  Future<void> enableBeautification(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  );

  Future<bool> isBeautificationEnabled(
      MediaStreamTrack mediaStreamTrack);

  Future<void> setBeautificationPower(
    MediaStreamTrack mediaStreamTrack,
    double power,
  );

  Future<double> getZoomLevel(
      MediaStreamTrack mediaStreamTrack);

  Future<void> setZoomLevel(
    MediaStreamTrack mediaStreamTrack,
    double zoomLevel,
  );

  Future<void> enableSharpening(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  );

  Future<double> getSharpeningStrength(MediaStreamTrack mediaStreamTrack);

  Future<void> setSharpeningStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  );

  Future<void> setColorCorrectionMode(
    MediaStreamTrack mediaStreamTrack,
    ColorCorrectionMode colorCorrectionMode,
  );

  Future<void> setColorFilterStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  );

  Future<void> setColorGradingReference(
    MediaStreamTrack mediaStreamTrack,
    EffectsSdkImage image,
  );
}