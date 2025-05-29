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
  /// Remove background completely
  remove,

  /// Replace background with custom image/video
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

  /// Automatic color correction and white balance
  colorCorrectionMode,

  /// Manual color grading controls
  colorGradingMode,

  /// Apply predefined color presets
  presetMode,

  /// Low light environment optimization
  lowLightMode,
}

/// Converts Java Platform enum string to [AuthStatus] value.
///
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
/// Supported values:
/// - 'REMOVE' → [PipelineMode.remove]
/// - 'REPLACE' → [PipelineMode.replace]
/// - 'BLUR' → [PipelineMode.blur]
/// - 'NO_EFFECTS' → [PipelineMode.noEffects]
///
/// Throws [Exception] if unknown value is passed.
PipelineMode parseJavaPipelineMode(String javaEnumValue) {
  switch (javaEnumValue) {
    case 'REMOVE': return PipelineMode.remove;
    case 'REPLACE': return PipelineMode.replace;
    case 'BLUR': return PipelineMode.blur;
    case 'NO_EFFECTS': return PipelineMode.noEffects;
    default: throw Exception('Unknown enum value: $javaEnumValue');
  }
}

/// Converts Java Platform enum string to [ColorCorrectionMode] value.
///
/// Supported values:
/// - 'NO_FILTER_MODE' → [ColorCorrectionMode.noFilterMode]
/// - 'COLOR_CORRECTION_MODE' → [ColorCorrectionMode.colorCorrectionMode]
/// - 'COLOR_GRADING_MODE' → [ColorCorrectionMode.colorGradingMode]
/// - 'PRESET_MODE' → [ColorCorrectionMode.presetMode]
/// - 'LOW_LIGHT_MODE' → [ColorCorrectionMode.lowLightMode]
///
/// Throws [Exception] if unknown value is passed.
ColorCorrectionMode parseJavaColorCorrectionMode(String javaEnumValue) {
  switch (javaEnumValue) {
    case 'NO_FILTER_MODE': return ColorCorrectionMode.noFilterMode;
    case 'COLOR_CORRECTION_MODE': return ColorCorrectionMode.colorCorrectionMode;
    case 'COLOR_GRADING_MODE': return ColorCorrectionMode.colorGradingMode;
    case 'PRESET_MODE': return ColorCorrectionMode.presetMode;
    case 'LOW_LIGHT_MODE': return ColorCorrectionMode.lowLightMode;
    default: throw Exception('Unknown enum value: $javaEnumValue');
  }
}