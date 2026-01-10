import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grid_timer/infrastructure/wav_duration.dart';

void main() {
  test('tryParsePcmWavDuration returns null for non-WAV bytes', () {
    expect(tryParsePcmWavDuration(Uint8List.fromList(<int>[1, 2, 3])), isNull);
  });

  test('tryParsePcmWavDuration parses PCM WAV duration from header', () {
    final wavBytes = _buildPcmWav(
      sampleRate: 8000,
      numChannels: 1,
      bitsPerSample: 16,
      dataSizeBytes: 16000, // 1 second @ 8000 Hz mono 16-bit
    );

    expect(tryParsePcmWavDuration(wavBytes), const Duration(seconds: 1));
  });

  test('tryParsePcmWavDuration skips unknown chunks', () {
    final wavBytes = _buildPcmWavWithExtraChunk(
      sampleRate: 8000,
      numChannels: 1,
      bitsPerSample: 16,
      dataSizeBytes: 8000, // 0.5 seconds
    );

    expect(
      tryParsePcmWavDuration(wavBytes),
      const Duration(milliseconds: 500),
    );
  });
}

Uint8List _buildPcmWav({
  required int sampleRate,
  required int numChannels,
  required int bitsPerSample,
  required int dataSizeBytes,
}) {
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);

  final fileSize = 44 + dataSizeBytes;
  final riffChunkSize = fileSize - 8;

  final bytes = Uint8List(fileSize);
  final bd = ByteData.sublistView(bytes);

  _writeFourCC(bytes, 0, 'RIFF');
  bd.setUint32(4, riffChunkSize, Endian.little);
  _writeFourCC(bytes, 8, 'WAVE');

  // fmt chunk
  _writeFourCC(bytes, 12, 'fmt ');
  bd.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  bd.setUint16(20, 1, Endian.little); // audio format PCM
  bd.setUint16(22, numChannels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, byteRate, Endian.little);
  bd.setUint16(32, blockAlign, Endian.little);
  bd.setUint16(34, bitsPerSample, Endian.little);

  // data chunk
  _writeFourCC(bytes, 36, 'data');
  bd.setUint32(40, dataSizeBytes, Endian.little);
  // Data payload remains zeroed.

  return bytes;
}

Uint8List _buildPcmWavWithExtraChunk({
  required int sampleRate,
  required int numChannels,
  required int bitsPerSample,
  required int dataSizeBytes,
}) {
  // Add a fake "JUNK" chunk between fmt and data.
  const junkChunkSize = 4;
  final extraHeader = 8 + junkChunkSize; // id + size + payload

  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);

  final fileSize = 44 + extraHeader + dataSizeBytes;
  final riffChunkSize = fileSize - 8;

  final bytes = Uint8List(fileSize);
  final bd = ByteData.sublistView(bytes);

  _writeFourCC(bytes, 0, 'RIFF');
  bd.setUint32(4, riffChunkSize, Endian.little);
  _writeFourCC(bytes, 8, 'WAVE');

  // fmt chunk (same as normal)
  _writeFourCC(bytes, 12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, numChannels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, byteRate, Endian.little);
  bd.setUint16(32, blockAlign, Endian.little);
  bd.setUint16(34, bitsPerSample, Endian.little);

  // JUNK chunk (unknown)
  final junkOffset = 36;
  _writeFourCC(bytes, junkOffset, 'JUNK');
  bd.setUint32(junkOffset + 4, junkChunkSize, Endian.little);
  // payload is zeroed

  // data chunk after JUNK
  final dataOffset = junkOffset + extraHeader;
  _writeFourCC(bytes, dataOffset, 'data');
  bd.setUint32(dataOffset + 4, dataSizeBytes, Endian.little);

  return bytes;
}

void _writeFourCC(Uint8List bytes, int offset, String fourCC) {
  assert(fourCC.length == 4, 'fourCC must be 4 characters');
  bytes[offset] = fourCC.codeUnitAt(0);
  bytes[offset + 1] = fourCC.codeUnitAt(1);
  bytes[offset + 2] = fourCC.codeUnitAt(2);
  bytes[offset + 3] = fourCC.codeUnitAt(3);
}
