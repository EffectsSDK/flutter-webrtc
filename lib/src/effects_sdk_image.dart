import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// Types of image sources supported by the effects SDK.
sealed class ImageSource {}

/// Pixel format for raw image data.
///
/// Currently only RGBA format is supported (4 bytes per pixel).
enum RawImageFormat {
  /// 4 bytes per pixel in Red-Green-Blue-Alpha order.
  rgba
}

/// Raw pixel data image representation.
///
/// Used for direct pixel manipulation with format, dimensions and stride.
class RawImage extends ImageSource {
  /// Creates a raw image from pixel data.
  ///
  /// - [data]: Raw pixel bytes in specified format
  /// - [format]: Pixel format (currently only [RawImageFormat.rgba])
  /// - [width]: Image width in pixels
  /// - [height]: Image height in pixels
  /// - [bytesPerRow]: Number of bytes per row (stride). Defaults to
  ///   `width * 4` if not specified (for RGBA format).
  RawImage({
    required this.data,
    required this.format,
    required this.width,
    required this.height,
    required this.bytesPerRow,
  });

  /// Raw pixel bytes.
  final Uint8List data;

  /// Pixel format specification.
  final RawImageFormat format;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Number of bytes per row (stride).
  final int bytesPerRow;
}

/// Image loaded from a file path.
class FilePathImage extends ImageSource {
  /// Creates an image from a local file path.
  ///
  /// - [path]: Filesystem path to the image (e.g. 'assets/background.jpg')
  FilePathImage(this.path);

  /// Local filesystem path to the image file.
  final String path;
}

/// Encoded image data (e.g. PNG/JPEG).
class EncodedImageData extends ImageSource {
  /// Creates an image from encoded bytes.
  ///
  /// - [data]: Compressed image bytes in supported format
  EncodedImageData(this.data);

  /// Encoded image bytes.
  final Uint8List data;
}

/// Solid color image defined by RGB components.
class SolidRGBImage extends ImageSource {
  /// Creates a solid color image.
  ///
  /// All values should be in 0.0-1.0 range.
  ///
  /// - [r]: Red channel (0.0 to 1.0)
  /// - [g]: Green channel (0.0 to 1.0)
  /// - [b]: Blue channel (0.0 to 1.0)
  SolidRGBImage({
    required this.r,
    required this.g,
    required this.b,
  });

  /// Red channel value.
  final double r;

  /// Green channel value.
  final double g;

  /// Blue channel value.
  final double b;
}

/// Container for image data used by the effects SDK.
class EffectsSdkImage {
  /// The source of the image data.
  final ImageSource source;

  /// Creates image from raw pixel data.
  ///
  /// - [data]: Raw pixel bytes in specified format
  /// - [format]: Pixel format (must be [RawImageFormat.rgba])
  /// - [width]: Image width in pixels
  /// - [height]: Image height in pixels
  /// - [bytesPerRow]: Optional stride. Defaults to `width * 4`.
  EffectsSdkImage.fromRaw({
    required Uint8List data,
    required RawImageFormat format,
    required int width,
    required int height,
    int bytesPerRow = 0,
  }) : source = RawImage(
    data: data,
    format: format,
    width: width,
    height: height,
    bytesPerRow: (bytesPerRow > 0) ? bytesPerRow : width * 4,
  );

  /// Creates image from a local file path.
  ///
  /// - [filepath]: Path to image file (JPEG/PNG supported)
  EffectsSdkImage.fromPath(String filepath) : source = FilePathImage(filepath);

  /// Creates image from encoded bytes.
  ///
  /// - [encoded]: Compressed image data (JPEG/PNG supported)
  EffectsSdkImage.fromEncoded(Uint8List encoded) : source = EncodedImageData(encoded);

  /// Creates solid color image from RGB values.
  ///
  /// All values should be in 0.0-1.0 range.
  ///
  /// - [r]: Red component (0.0 to 1.0)
  /// - [g]: Green component (0.0 to 1.0)
  /// - [b]: Blue component (0.0 to 1.0)
  EffectsSdkImage.fromRGB({
    required double r,
    required double g,
    required double b,
  }) : source = SolidRGBImage(r: r, g: g, b: b);
}