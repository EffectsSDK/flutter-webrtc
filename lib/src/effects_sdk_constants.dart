/// Authentication statuses for the SDK license.
enum AuthStatus {
  /// License is active and valid
  active,

  /// License has expired
  expired,

  /// License is not activated
  inactive,

  /// Authentication service unavailable
  unavailable,

  /// General authentication error
  error,
}

/// Video background processing modes
enum PipelineMode {
  /// Replace background with custom image
  replace,

  /// Apply background blur effect
  blur,

  /// Disable all background processing
  noEffects,
}

/// Color processing modes for video
enum ColorCorrectionMode {
  /// No color adjustments applied
  noFilterMode,

  /// Automatic color correction using Machine Learning
  colorCorrectionMode,

  /// Generates a color palette from the reference image and apply it to the video.
  colorGradingMode,

  /// Low light environment optimization
  /// 
  /// Makes the video brighter using machine learning, can improve videos shot in a dark room.
  lowLightMode,
}

/// Converts Java Platform enum string to [AuthStatus] value.
///
/// @nodoc
/// Supported values:
/// - 'ACTIVE' → [AuthStatus.active]
/// - 'INACTIVE' → [AuthStatus.inactive]
/// - 'EXPIRED' → [AuthStatus.expired]
/// - 'UNAVAILABLE' → [AuthStatus.unavailable]
/// - 'ERROR' → [AuthStatus.error]
///
/// Throws [Exception] if unknown value is passed.
AuthStatus parseJavaAuthStatus(String javaEnumValue) {
  switch (javaEnumValue) {
    case 'ACTIVE': return AuthStatus.active;
    case 'INACTIVE': return AuthStatus.inactive;
    case 'EXPIRED': return AuthStatus.expired;
    case 'UNAVAILABLE': return AuthStatus.unavailable;
    case 'ERROR': return AuthStatus.error;
    default: throw Exception('Unknown enum value: $javaEnumValue');
  }
}

/// Converts Java Platform enum string to [PipelineMode] value.
///
/// @nodoc
/// Supported values:
/// - 'REPLACE' → [PipelineMode.replace]
/// - 'BLUR' → [PipelineMode.blur]
/// - 'NO_EFFECTS' → [PipelineMode.noEffects]
///
/// Throws [Exception] if unknown value is passed.
PipelineMode parseJavaPipelineMode(String javaEnumValue) {
  switch (javaEnumValue) {
    case 'REPLACE': return PipelineMode.replace;
    case 'BLUR': return PipelineMode.blur;
    case 'NO_EFFECTS': return PipelineMode.noEffects;
    default: throw Exception('Unknown enum value: $javaEnumValue');
  }
}

/// Converts Java Platform enum string to [ColorCorrectionMode] value.
///
/// @nodoc
/// Supported values:
/// - 'NO_FILTER_MODE' → [ColorCorrectionMode.noFilterMode]
/// - 'COLOR_CORRECTION_MODE' → [ColorCorrectionMode.colorCorrectionMode]
/// - 'COLOR_GRADING_MODE' → [ColorCorrectionMode.colorGradingMode]
/// - 'LOW_LIGHT_MODE' → [ColorCorrectionMode.lowLightMode]
///
/// Throws [Exception] if unknown value is passed.
ColorCorrectionMode parseJavaColorCorrectionMode(String javaEnumValue) {
  switch (javaEnumValue) {
    case 'NO_FILTER_MODE': return ColorCorrectionMode.noFilterMode;
    case 'COLOR_CORRECTION_MODE': return ColorCorrectionMode.colorCorrectionMode;
    case 'COLOR_GRADING_MODE': return ColorCorrectionMode.colorGradingMode;
    case 'LOW_LIGHT_MODE': return ColorCorrectionMode.lowLightMode;
    default: throw Exception('Unknown enum value: $javaEnumValue');
  }
}