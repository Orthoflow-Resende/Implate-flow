import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/services/photo_optimize.dart';

void main() {
  test('optimizeBytes produz JPEG sem EXIF e reporta tamanhos', () async {
    final original = Uint8List.fromList(List<int>.filled(4000, 7));
    final compressed = Uint8List.fromList(List<int>.filled(1200, 3));

    final service = PhotoOptimizeService(
      settings: const PhotoOptimizeSettings(maxLongestSide: 1600, quality: 80),
      compressor: (
        input, {
        required minWidth,
        required minHeight,
        required quality,
        required format,
        required keepExif,
      }) async {
        expect(input, original);
        expect(minWidth, 1600);
        expect(minHeight, 1600);
        expect(quality, 80);
        expect(format, CompressFormat.jpeg);
        expect(keepExif, isFalse);
        return compressed;
      },
    );

    final result = await service.optimizeBytes(original);
    expect(result.bytes, compressed);
    expect(result.extension, 'jpg');
    expect(result.contentType, 'image/jpeg');
    expect(result.originalByteSize, 4000);
    expect(result.optimizedByteSize, 1200);
    expect(result.reduced, isTrue);
  });

  test('optimizeBytes rejeita entrada vazia', () async {
    final service = PhotoOptimizeService(
      compressor: (
        input, {
        required minWidth,
        required minHeight,
        required quality,
        required format,
        required keepExif,
      }) async =>
          Uint8List(0),
    );
    await expectLater(
      () => service.optimizeBytes(Uint8List(0)),
      throwsA(isA<PhotoOptimizeException>()),
    );
  });

  test('optimizeBytes falha quando o compressor não devolve bytes', () async {
    final service = PhotoOptimizeService(
      compressor: (
        input, {
        required minWidth,
        required minHeight,
        required quality,
        required format,
        required keepExif,
      }) async =>
          null,
    );
    await expectLater(
      () => service.optimizeBytes(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<PhotoOptimizeException>()),
    );
  });
}
