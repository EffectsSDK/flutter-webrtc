import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/src/effects_sdk_image.dart';

import '../flutter_webrtc.dart';

/// Video Effects SDK API class.
/// 
/// Video Effects SDK can only work with local video tracks.
class VideoEffectsSdk {
  /// Authenticates SDK using remote service.
  ///
  /// Method performs https request to obtain license for customerID.
  /// - [mediaStreamTrack]: Associated media track
  /// - [customerID]: Unique customerID for authentication
  /// - [apiUrl]: Optional custom authentication endpoint
  /// - Returns: [AuthStatus] indicating authentication result
  /// - Throws: Platform exceptions for communication errors
  static Future<AuthStatus> auth(
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
  ) async {
    String status = await WebRTC.invokeMethod(
      'localAuth',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'localKey': localKey},
    );
    return parseJavaAuthStatus(status);
  }

  /// Gets the current background processing mode for a media track.
  ///
  /// - [mediaStreamTrack]: The target media track
  /// - Returns: Current [PipelineMode]
  /// - Throws: [Exception] if native method fails or returns unknown value
  static Future<PipelineMode> getPipelineMode(
      MediaStreamTrack mediaStreamTrack) async {
    String mode = await WebRTC.invokeMethod(
      'getPipelineMode',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
    return parseJavaPipelineMode(mode);
  }

  /// Sets background processing mode for a media track.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [pipelineMode]: New processing mode to apply
  static Future<void> setPipelineMode(
      MediaStreamTrack mediaStreamTrack, PipelineMode pipelineMode) async {
    await WebRTC.invokeMethod(
      'setPipelineMode',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'pipelineMode': pipelineMode.toString()
      },
    );
  }

  /// Adjusts blur strength for background blur mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [power]: Blur strength (0.0 - 1.0 where 1.0 is maximum blur)
  static Future<void> setBlurPower(
      MediaStreamTrack mediaStreamTrack,
      double power) async {
    await WebRTC.invokeMethod(
      'setBlurPower',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'blurPower': power},
    );
  }

  /// Sets custom background image for replace mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [image]: Image to use as background
  /// - See also: [EffectsSdkImage] for supported image types
  static Future<void> setBackgroundImage(
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

  /// Enables/disables face beautification effects.
  ///
  /// Improves the appearance of the human face.
  /// - [mediaStreamTrack]: Target media track
  /// - [enable]: true to enable, false to disable
  static Future<void> enableBeautification(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    await WebRTC.invokeMethod(
      'enableBeautification',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'enable': enable},
    );
  }

  /// Checks if beautification is currently enabled.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current enabled status
  static Future<bool> isBeautificationEnabled(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'isBeautificationEnabled',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
  }

  /// Adjusts beautification effect strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [power]: Effect strength (0.0 - 1.0)
  static Future<void> setBeautificationPower(
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

  /// Gets current smart zoom level.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current zoom level 
  static Future<double> getZoomLevel(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'getZoomLevel',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
  }

  /// Sets smart zoom level.
  ///
  /// When level > 0, crops around the face, 1 means that the face is zoomed into the entire frame.
  /// - [mediaStreamTrack]: Target media track
  /// - [zoomLevel]: zoomLevel (0 - 1)
  static Future<void> setZoomLevel(
    MediaStreamTrack mediaStreamTrack,
    double zoomLevel,
  ) async {
    await WebRTC.invokeMethod(
      'setZoomLevel',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'zoomLevel': zoomLevel},
    );
  }

  /// Enables/disables image sharpening.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [enable]: true to enable, false to disable
  static Future<void> enableSharpening(
    MediaStreamTrack mediaStreamTrack,
    bool enable,
  ) async {
    await WebRTC.invokeMethod(
      'enableSharpening',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'enable': enable},
    );
  }

  /// Gets current sharpening strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current sharpening strength (0.0 - 1.0)
  static Future<double> getSharpeningStrength(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'getSharpeningStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
  }

  /// Adjusts image sharpening strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [strength]: New sharpening strength (0.0 - 1.0), 0 is minimal sharpening (there is still visible effect), 1 is maximal
  static Future<void> setSharpeningStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) async {
    await WebRTC.invokeMethod(
      'setSharpeningStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'strength': strength},
    );
  }

  /// Sets color correction processing mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [colorCorrectionMode]: New color processing mode
  static Future<void> setColorCorrectionMode(
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

  /// Adjusts color filter strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [strength]: Filter intensity (0.0 - 1.0)
  static Future<void> setColorFilterStrength(
    MediaStreamTrack mediaStreamTrack,
    double strength,
  ) async {
    await WebRTC.invokeMethod(
      'setColorFilterStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'strength': strength},
    );
  }

  /// Sets reference image for color grading mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [image]: Reference image for color matching
  static Future<void> setColorGradingReference(
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

  /// Serializes [EffectsSdkImage] to platform-specific format.
  static Map<String, dynamic> _serializeImage(EffectsSdkImage image) {
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
    }
  }
}
