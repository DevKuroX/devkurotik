/// RouterOS binary API protocol framing.
///
/// Implements the MikroTik RouterOS binary API word length encoding/decoding
/// and sentence framing as documented in:
/// - MikroTik RouterOS API documentation
/// - Audited behavior from Mikhmon v3 `lib/routeros_api.class.php`
///
/// ## Word Length Encoding
///
/// The RouterOS API uses a variable-length prefix (1–5 bytes) before each word:
///
/// | Length value | Encoding |
/// |---|---|
/// | 0x00 – 0x7F  | 1 byte: `0xxxxxxx` |
/// | 0x80 – 0x3FFF | 2 bytes: `10xxxxxx xxxxxxxx` |
/// | 0x4000 – 0x1FFFFF | 3 bytes: `110xxxxx xxxxxxxx xxxxxxxx` |
/// | 0x200000 – 0xFFFFFFF | 4 bytes: `1110xxxx xxxxxxxx xxxxxxxx xxxxxxxx` |
/// | 0x10000000 – 0xFFFFFFFF | 5 bytes: `11110000 xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx` |
///
/// A length of 0 (single zero byte) signals end of sentence.
library;

import 'dart:typed_data';

/// Encodes a word length into the RouterOS variable-length byte format.
///
/// Returns a [Uint8List] of 1–5 bytes that prefix a word in the API stream.
///
/// Throws [ArgumentError] if [length] is negative.
Uint8List encodeLength(int length) {
  if (length < 0) {
    throw ArgumentError.value(length, 'length', 'must be non-negative');
  }

  if (length <= 0x7F) {
    return Uint8List.fromList([length]);
  } else if (length <= 0x3FFF) {
    return Uint8List.fromList([((length >> 8) & 0x3F) | 0x80, length & 0xFF]);
  } else if (length <= 0x1FFFFF) {
    return Uint8List.fromList([
      ((length >> 16) & 0x1F) | 0xC0,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);
  } else if (length <= 0xFFFFFFF) {
    return Uint8List.fromList([
      ((length >> 24) & 0x0F) | 0xE0,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);
  } else {
    return Uint8List.fromList([
      0xF0,
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);
  }
}

/// Decodes a RouterOS variable-length word length from a byte buffer.
///
/// Reads from [bytes] starting at [offset] and returns a [DecodedLength]
/// containing the decoded integer value and the number of bytes consumed.
///
/// Throws [ArgumentError] if the buffer is too short to decode.
DecodedLength decodeLength(Uint8List bytes, int offset) {
  if (offset >= bytes.length) {
    throw ArgumentError('Buffer too short to decode length at offset $offset');
  }

  final first = bytes[offset];

  if (first & 0x80 == 0) {
    // 1 byte: 0xxxxxxx
    return DecodedLength(first, 1);
  } else if (first & 0xC0 == 0x80) {
    // 2 bytes: 10xxxxxx xxxxxxxx
    if (offset + 1 >= bytes.length) {
      throw ArgumentError('Buffer too short: need 2 bytes');
    }
    return DecodedLength(((first & 0x3F) << 8) | bytes[offset + 1], 2);
  } else if (first & 0xE0 == 0xC0) {
    // 3 bytes: 110xxxxx xxxxxxxx xxxxxxxx
    if (offset + 2 >= bytes.length) {
      throw ArgumentError('Buffer too short: need 3 bytes');
    }
    return DecodedLength(
      ((first & 0x1F) << 16) | (bytes[offset + 1] << 8) | bytes[offset + 2],
      3,
    );
  } else if (first & 0xF0 == 0xE0) {
    // 4 bytes: 1110xxxx xxxxxxxx xxxxxxxx xxxxxxxx
    if (offset + 3 >= bytes.length) {
      throw ArgumentError('Buffer too short: need 4 bytes');
    }
    return DecodedLength(
      ((first & 0x0F) << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3],
      4,
    );
  } else {
    // 5 bytes: 11110000 xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx
    if (offset + 4 >= bytes.length) {
      throw ArgumentError('Buffer too short: need 5 bytes');
    }
    return DecodedLength(
      (bytes[offset + 1] << 24) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 8) |
          bytes[offset + 4],
      5,
    );
  }
}

/// Result of a [decodeLength] operation.
final class DecodedLength {
  /// The decoded length value.
  final int value;

  /// The number of bytes consumed by the length prefix.
  final int bytesConsumed;

  const DecodedLength(this.value, this.bytesConsumed);
}

/// Encodes a single RouterOS API word (length-prefixed UTF-8 string).
///
/// The encoded form is: `[length bytes][UTF-8 word bytes]`
Uint8List encodeWord(String word) {
  final wordBytes = Uint8List.fromList(word.codeUnits);
  final lengthBytes = encodeLength(wordBytes.length);
  return Uint8List.fromList([...lengthBytes, ...wordBytes]);
}

/// Encodes an end-of-sentence marker (single zero byte).
Uint8List encodeEndOfSentence() => Uint8List.fromList([0x00]);

/// Encodes a complete RouterOS API sentence.
///
/// A sentence is a sequence of words followed by a zero-length terminator.
///
/// Example:
/// ```dart
/// encodeSentence(['/ip/hotspot/user/print', '?profile=daily']);
/// ```
Uint8List encodeSentence(List<String> words) {
  final buffer = <int>[];
  for (final word in words) {
    buffer.addAll(encodeWord(word));
  }
  buffer.add(0x00); // end-of-sentence
  return Uint8List.fromList(buffer);
}

/// Parses a RouterOS API response sentence from raw bytes.
///
/// Returns a list of [RouterosSentence] objects decoded from [bytes].
/// Handles multiple sentences in a single buffer (common in streaming responses).
List<RouterosSentence> parseSentences(Uint8List bytes) {
  final sentences = <RouterosSentence>[];
  final words = <String>[];
  var offset = 0;

  while (offset < bytes.length) {
    if (bytes[offset] == 0x00) {
      // End of sentence
      if (words.isNotEmpty) {
        sentences.add(RouterosSentence(List.unmodifiable(words)));
        words.clear();
      }
      offset++;
    } else {
      final decoded = decodeLength(bytes, offset);
      offset += decoded.bytesConsumed;
      final wordEnd = offset + decoded.value;
      if (wordEnd > bytes.length) break; // incomplete read — caller must buffer
      final word = String.fromCharCodes(bytes.sublist(offset, wordEnd));
      words.add(word);
      offset = wordEnd;
    }
  }

  return sentences;
}

/// A single RouterOS API response sentence.
///
/// A sentence contains one or more words returned by the router.
/// The first word is always a reply type word:
/// - `!re` — response row
/// - `!done` — end of response
/// - `!trap` — error
/// - `!fatal` — fatal error
final class RouterosSentence {
  /// The raw words in this sentence.
  final List<String> words;

  const RouterosSentence(this.words);

  /// The reply type word (first word, e.g. `!re`, `!done`, `!trap`, `!fatal`).
  String get replyWord => words.isNotEmpty ? words.first : '';

  /// Whether this is a `!re` (data) sentence.
  bool get isRe => replyWord == '!re';

  /// Whether this is a `!done` (end of response) sentence.
  bool get isDone => replyWord == '!done';

  /// Whether this is a `!trap` (command error) sentence.
  bool get isTrap => replyWord == '!trap';

  /// Whether this is a `!fatal` (fatal error) sentence.
  bool get isFatal => replyWord == '!fatal';

  /// Parses attribute words (`=key=value` format) into a [Map].
  ///
  /// Ignores words that do not match the `=key=value` pattern.
  Map<String, String> toMap() {
    final result = <String, String>{};
    for (final word in words) {
      if (word.startsWith('=') && word.length > 1) {
        final eqIndex = word.indexOf('=', 1);
        if (eqIndex > 1) {
          final key = word.substring(1, eqIndex);
          final value = word.substring(eqIndex + 1);
          result[key] = value;
        }
      }
    }
    return result;
  }

  /// Returns the value of a specific attribute word.
  String? getAttribute(String key) => toMap()[key];

  @override
  String toString() => 'RouterosSentence($replyWord, ${words.length} words)';
}
