import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Parâmetros clínicos de otimização — ajustáveis sem mudar o pipeline.
///
/// Política de retenção (F3S-521): a versão **pós-otimização** (JPEG sem EXIF)
/// é a imagem principal de qualidade clínica persistida. Não mantemos cópia em
/// claro da original do picker na pasta do app. Miniaturas/derivados entram com
/// a criptografia (F3S-505), não neste serviço.
class PhotoOptimizeSettings {
  const PhotoOptimizeSettings({
    this.maxLongestSide = 2048,
    this.quality = 85,
  });

  /// Maior lado em pixels; proporção preservada, sem upscaling.
  final int maxLongestSide;

  /// Qualidade JPEG 0–100. Valores agressivos exigem validação clínica.
  final int quality;
}

class OptimizedPhoto {
  const OptimizedPhoto({
    required this.bytes,
    required this.extension,
    required this.contentType,
    required this.originalByteSize,
    required this.optimizedByteSize,
  });

  final Uint8List bytes;
  final String extension;
  final String contentType;
  final int originalByteSize;
  final int optimizedByteSize;

  bool get reduced => optimizedByteSize < originalByteSize;
}

typedef PhotoCompressor = Future<Uint8List?> Function(
  Uint8List input, {
  required int minWidth,
  required int minHeight,
  required int quality,
  required CompressFormat format,
  required bool keepExif,
});

/// Otimiza fotos clínicas **antes** de qualquer criptografia/persistência.
///
/// Ordem do ecossistema: capturar → otimizar (aqui) → criptografar → gravar/enviar.
class PhotoOptimizeService {
  PhotoOptimizeService({
    PhotoCompressor? compressor,
    this.settings = const PhotoOptimizeSettings(),
  }) : _compressor = compressor ?? _defaultCompressor;

  final PhotoCompressor _compressor;
  final PhotoOptimizeSettings settings;

  static Future<Uint8List?> _defaultCompressor(
    Uint8List input, {
    required int minWidth,
    required int minHeight,
    required int quality,
    required CompressFormat format,
    required bool keepExif,
  }) {
    return FlutterImageCompress.compressWithList(
      input,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
      keepExif: keepExif,
    );
  }

  Future<OptimizedPhoto> optimizeFile(String path) async {
    final original = await File(path).readAsBytes();
    return optimizeBytes(Uint8List.fromList(original));
  }

  Future<OptimizedPhoto> optimizeBytes(Uint8List original) async {
    if (original.isEmpty) {
      throw const PhotoOptimizeException('A imagem está vazia.');
    }

    final compressed = await _compressor(
      original,
      minWidth: settings.maxLongestSide,
      minHeight: settings.maxLongestSide,
      quality: settings.quality,
      format: CompressFormat.jpeg,
      // Remove GPS e demais EXIF; orientação é aplicada nos pixels.
      keepExif: false,
    );

    if (compressed == null || compressed.isEmpty) {
      throw const PhotoOptimizeException('Não foi possível otimizar a imagem.');
    }

    final bytes = Uint8List.fromList(compressed);
    return OptimizedPhoto(
      bytes: bytes,
      extension: 'jpg',
      contentType: 'image/jpeg',
      originalByteSize: original.length,
      optimizedByteSize: bytes.length,
    );
  }
}

class PhotoOptimizeException implements Exception {
  const PhotoOptimizeException(this.message);

  final String message;

  @override
  String toString() => message;
}
