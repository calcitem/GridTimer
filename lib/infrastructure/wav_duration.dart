import 'dart:typed_data';

/// Attempts to parse the duration of a PCM WAV file from its header.
///
/// Returns null when the bytes are not a supported WAV format or the header is
/// malformed.
Duration? tryParsePcmWavDuration(Uint8List bytes) {
  // Minimal PCM WAV header is 44 bytes.
  if (bytes.length < 44) return null;

  // RIFF container header:
  // 0..3  "RIFF"
  // 8..11 "WAVE"
  if (!_matchesFourCC(bytes, 0, 'RIFF')) return null;
  if (!_matchesFourCC(bytes, 8, 'WAVE')) return null;

  final byteData = ByteData.sublistView(bytes);

  int? byteRate;
  int? dataSize;

  // Chunk parsing starts after RIFF header (12 bytes).
  int offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkId = _fourCC(bytes, offset);
    final chunkSize = byteData.getUint32(offset + 4, Endian.little);
    final chunkDataStart = offset + 8;
    final chunkDataEnd = chunkDataStart + chunkSize;

    if (chunkDataEnd > bytes.length) break;

    if (chunkId == 'fmt ') {
      // PCM format chunk should be at least 16 bytes.
      if (chunkSize < 16) return null;

      final audioFormat = byteData.getUint16(chunkDataStart + 0, Endian.little);
      final numChannels = byteData.getUint16(chunkDataStart + 2, Endian.little);
      final sampleRate = byteData.getUint32(chunkDataStart + 4, Endian.little);
      final headerByteRate = byteData.getUint32(
        chunkDataStart + 8,
        Endian.little,
      );
      final bitsPerSample = byteData.getUint16(
        chunkDataStart + 14,
        Endian.little,
      );

      // Only PCM (format = 1) is supported for now.
      if (audioFormat != 1) return null;

      if (headerByteRate > 0) {
        byteRate = headerByteRate;
      } else {
        final computedByteRate =
            sampleRate * numChannels * (bitsPerSample ~/ 8);
        if (computedByteRate > 0) {
          byteRate = computedByteRate;
        }
      }
    } else if (chunkId == 'data') {
      dataSize = chunkSize;
    }

    // Chunks are word-aligned: odd-sized chunks have a padding byte.
    offset = chunkDataEnd + (chunkSize.isOdd ? 1 : 0);

    if (byteRate != null && dataSize != null) break;
  }

  final br = byteRate;
  final ds = dataSize;
  if (br == null || ds == null || br <= 0 || ds <= 0) return null;

  final seconds = ds / br;
  if (seconds <= 0 || seconds.isNaN || seconds.isInfinite) return null;

  return Duration(milliseconds: (seconds * 1000).round());
}

bool _matchesFourCC(Uint8List bytes, int offset, String fourCC) {
  if (offset + 4 > bytes.length) return false;
  return bytes[offset] == fourCC.codeUnitAt(0) &&
      bytes[offset + 1] == fourCC.codeUnitAt(1) &&
      bytes[offset + 2] == fourCC.codeUnitAt(2) &&
      bytes[offset + 3] == fourCC.codeUnitAt(3);
}

String _fourCC(Uint8List bytes, int offset) {
  return String.fromCharCodes(bytes.sublist(offset, offset + 4));
}
