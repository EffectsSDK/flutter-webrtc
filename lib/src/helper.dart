import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/src/effects_sdk_image.dart';

import '../flutter_webrtc.dart';

class Helper {
  static Future<List<MediaDeviceInfo>> enumerateDevices(String type) async {
    var devices = await navigator.mediaDevices.enumerateDevices();
    return devices.where((d) => d.kind == type).toList();
  }

  /// Return the available cameras
  ///
  /// Note: Make sure to call this gettet after
  /// navigator.mediaDevices.getUserMedia(), otherwise the devices will not be
  /// listed.
  static Future<List<MediaDeviceInfo>> get cameras =>
      enumerateDevices('videoinput');

  /// Return the available audiooutputs
  ///
  /// Note: Make sure to call this gettet after
  /// navigator.mediaDevices.getUserMedia(), otherwise the devices will not be
  /// listed.
  static Future<List<MediaDeviceInfo>> get audiooutputs =>
      enumerateDevices('audiooutput');

  /// For web implementation, make sure to pass the target deviceId
  static Future<bool> switchCamera(MediaStreamTrack track,
      [String? deviceId, MediaStream? stream]) async {
    if (track.kind != 'video') {
      throw 'The is not a video track => $track';
    }

    if (!kIsWeb) {
      return WebRTC.invokeMethod(
        'mediaStreamTrackSwitchCamera',
        <String, dynamic>{'trackId': track.id},
      ).then((value) => value ?? false);
    }

    if (deviceId == null) throw 'You need to specify the deviceId';
    if (stream == null) throw 'You need to specify the stream';

    var cams = await cameras;
    if (!cams.any((e) => e.deviceId == deviceId)) {
      throw 'The provided deviceId is not available, make sure to retreive the deviceId from Helper.cammeras()';
    }

    // stop only video tracks
    // so that we can recapture video track
    stream.getVideoTracks().forEach((track) {
      track.stop();
      stream.removeTrack(track);
    });

    var mediaConstraints = {
      'audio': false, // NO need to capture audio again
      'video': {'deviceId': deviceId}
    };

    var newStream = await openCamera(mediaConstraints);
    var newCamTrack = newStream.getVideoTracks()[0];

    await stream.addTrack(newCamTrack, addToNative: true);

    return Future.value(true);
  }

  static Future<void> setZoom(MediaStreamTrack videoTrack, double zoomLevel) =>
      CameraUtils.setZoom(videoTrack, zoomLevel);

  static Future<void> setFocusMode(
          MediaStreamTrack videoTrack, CameraFocusMode focusMode) =>
      CameraUtils.setFocusMode(videoTrack, focusMode);

  static Future<void> setFocusPoint(
          MediaStreamTrack videoTrack, Point<double>? point) =>
      CameraUtils.setFocusPoint(videoTrack, point);

  static Future<void> setExposureMode(
          MediaStreamTrack videoTrack, CameraExposureMode exposureMode) =>
      CameraUtils.setExposureMode(videoTrack, exposureMode);

  static Future<void> setExposurePoint(
          MediaStreamTrack videoTrack, Point<double>? point) =>
      CameraUtils.setExposurePoint(videoTrack, point);

  /// Used to select a specific audio output device.
  ///
  /// Note: This method is only used for Flutter native,
  /// supported on iOS/Android/macOS/Windows.
  ///
  /// Android/macOS/Windows: Can be used to switch all output devices.
  /// iOS: you can only switch directly between the
  /// speaker and the preferred device
  /// web: flutter web can use RTCVideoRenderer.audioOutput instead
  static Future<void> selectAudioOutput(String deviceId) async {
    await navigator.mediaDevices
        .selectAudioOutput(AudioOutputOptions(deviceId: deviceId));
  }

  /// Set audio input device for Flutter native
  /// Note: The usual practice in flutter web is to use deviceId as the
  /// `getUserMedia` parameter to get a new audio track and replace it with the
  ///  audio track in the original rtpsender.
  static Future<void> selectAudioInput(String deviceId) =>
      NativeAudioManagement.selectAudioInput(deviceId);

  /// Enable or disable speakerphone
  /// for iOS/Android only
  static Future<void> setSpeakerphoneOn(bool enable) =>
      NativeAudioManagement.setSpeakerphoneOn(enable);

  /// Ensure audio session
  /// for iOS only
  static Future<void> ensureAudioSession() =>
      NativeAudioManagement.ensureAudioSession();

  /// Enable speakerphone, but use bluetooth if audio output device available
  /// for iOS/Android only
  static Future<void> setSpeakerphoneOnButPreferBluetooth() =>
      NativeAudioManagement.setSpeakerphoneOnButPreferBluetooth();

  /// To select a a specific camera, you need to set constraints
  /// eg.
  /// var constraints = {
  ///      'audio': true,
  ///      'video': {
  ///          'deviceId': Helper.cameras[0].deviceId,
  ///          }
  ///      };
  ///
  /// var stream = await Helper.openCamera(constraints);
  ///
  static Future<MediaStream> openCamera(Map<String, dynamic> mediaConstraints) {
    return navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  /// Set the volume for Flutter native
  static Future<void> setVolume(double volume, MediaStreamTrack track) =>
      NativeAudioManagement.setVolume(volume, track);

  /// Set the microphone mute/unmute for Flutter native
  static Future<void> setMicrophoneMute(bool mute, MediaStreamTrack track) =>
      NativeAudioManagement.setMicrophoneMute(mute, track);

  /// Set the audio configuration to for Android.
  /// Must be set before initiating a WebRTC session and cannot be changed
  /// mid session.
  static Future<void> setAndroidAudioConfiguration(
          AndroidAudioConfiguration androidAudioConfiguration) =>
      AndroidNativeAudioManagement.setAndroidAudioConfiguration(
          androidAudioConfiguration);

  /// After Android app finishes a session, on audio focus loss, clear the active communication device.
  static Future<void> clearAndroidCommunicationDevice() =>
      WebRTC.invokeMethod('clearAndroidCommunicationDevice');

  /// Set the audio configuration for iOS
  static Future<void> setAppleAudioConfiguration(
          AppleAudioConfiguration appleAudioConfiguration) =>
      AppleNativeAudioManagement.setAppleAudioConfiguration(
          appleAudioConfiguration);

  /// Set the audio configuration for iOS
  static Future<void> setAppleAudioIOMode(AppleAudioIOMode mode,
          {bool preferSpeakerOutput = false}) =>
      AppleNativeAudioManagement.setAppleAudioConfiguration(
          AppleNativeAudioManagement.getAppleAudioConfigurationForMode(mode,
              preferSpeakerOutput: preferSpeakerOutput));

  /// Request capture permission for Android
  static Future<bool> requestCapturePermission() async {
    if (WebRTC.platformIsAndroid) {
      return await WebRTC.invokeMethod('requestCapturePermission');
    } else {
      throw Exception('requestCapturePermission only support for Android');
    }
  }

  /// Effects SDK control methods. Check effectsSDK docs here:
  /// iOS: *link*
  /// android: *link*

  /// Gets the current background processing mode for a media track.
  ///
  /// - [mediaStreamTrack]: The target media track
  /// - Returns: Current [PipelineMode]
  /// - Throws: [Exception] if native method fails or returns unknown value
  static Future<PipelineMode> getEffectsSdkPipelineMode(
      MediaStreamTrack mediaStreamTrack) async {
    String mode = await WebRTC.invokeMethod(
      'getPipelineMode',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
    return parseJavaPipelineMode(mode);
  }

  /// Authenticates SDK using remote service.
  ///
  /// - [mediaStreamTrack]: Associated media track
  /// - [customerKey]: License key for authentication
  /// - [apiUrl]: Optional custom authentication endpoint
  /// - Returns: [AuthStatus] indicating authentication result
  /// - Throws: Platform exceptions for communication errors
  static Future<AuthStatus> auth(
      MediaStreamTrack mediaStreamTrack, String customerKey,
      {String? apiUrl}) async {
    String status = await WebRTC.invokeMethod(
      'auth',
      <String, dynamic>{
        'trackId': mediaStreamTrack.id,
        'customerKey': customerKey,
        'apiUrl': apiUrl
      },
    );
    return parseJavaAuthStatus(status);
  }

  /// Authenticates SDK using local license validation.
  ///
  /// - [mediaStreamTrack]: Associated media track
  /// - [localKey]: Locally stored license key
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

  /// Sets background processing mode for a media track.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [pipelineMode]: New processing mode to apply
  static Future<void> setEffectsSdkPipelineMode(
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
  /// - [blurPower]: Blur strength (0.0 - 1.0 where 1.0 is maximum blur)
  static Future<void> setEffectsSdkBlurPower(
      MediaStreamTrack mediaStreamTrack,
      double blurPower) async {
    await WebRTC.invokeMethod(
      'setBlurPower',
      <String, dynamic>{'trackId': mediaStreamTrack.id, 'blurPower': blurPower},
    );
  }

  /// Sets custom background image for replace mode.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [image]: Image to use as background
  /// - See also: [EffectsSdkImage] for supported image types
  static Future<void> setEffectsSdkBackgroundImage(
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
  /// - [mediaStreamTrack]: Target media track
  /// - [enable]: true to enable, false to disable
  static Future<void> enableEffectsSdkBeautification(
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
  static Future<bool> isEffectsSdkBeautificationEnabled(
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
  static Future<void> setEffectsSdkBeautificationPower(
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

  /// Gets current digital zoom level.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - Returns: Current zoom level (1.0 = no zoom)
  static Future<double> getEffectsSdkZoomLevel(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'getZoomLevel',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
  }

  /// Sets digital zoom level.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [zoomLevel]: New zoom level (≥1.0)
  static Future<void> setEffectsSdkZoomLevel(
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
  static Future<void> enableEffectsSdkSharpening(
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
  static Future<double> getEffectsSdkSharpeningStrength(
      MediaStreamTrack mediaStreamTrack) async {
    return await WebRTC.invokeMethod(
      'getSharpeningStrength',
      <String, dynamic>{'trackId': mediaStreamTrack.id},
    );
  }

  /// Adjusts image sharpening strength.
  ///
  /// - [mediaStreamTrack]: Target media track
  /// - [strength]: New sharpening strength (0.0 - 1.0)
  static Future<void> setEffectsSdkSharpeningStrength(
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
  static Future<void> setEffectsSdkColorCorrectionMode(
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
  static Future<void> setEffectsSdkColorFilterStrength(
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
  static Future<void> setEffectsSdkColorGradingReferenceImage(
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
