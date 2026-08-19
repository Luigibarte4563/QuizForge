import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class FileExtractionService {
  static Future<ExtractionResult> extractText(File file) async {
    final path = file.path.toLowerCase();

    if (path.endsWith('.json')) {
      final content = await file.readAsString();
      return ExtractionResult(text: _extractJson(content));
    }

    if (path.endsWith('.txt') || path.endsWith('.csv')) {
      try {
        final content = await file.readAsString();
        return ExtractionResult(text: content);
      } catch (e) {
        return ExtractionResult(text: '[Error reading file: $e]', error: e.toString());
      }
    }

    if (path.endsWith('.rtf')) {
      try {
        final content = await file.readAsString();
        final text = _stripRtf(content);
        return ExtractionResult(text: text);
      } catch (e) {
        return ExtractionResult(text: '[Error reading RTF: $e]', error: e.toString());
      }
    }

    if (path.endsWith('.html') || path.endsWith('.htm')) {
      try {
        final content = await file.readAsString();
        return ExtractionResult(text: _stripHtmlTags(content));
      } catch (e) {
        return ExtractionResult(text: '[Error reading HTML: $e]', error: e.toString());
      }
    }

    if (path.endsWith('.pdf')) {
      return _extractPdf(file);
    }

    if (path.endsWith('.docx')) {
      return _extractDocx(file);
    }

    if (path.endsWith('.pptx')) {
      return _extractPptx(file);
    }

    if (path.endsWith('.xlsx') || path.endsWith('.xls')) {
      return _extractXlsx(file);
    }

    throw UnsupportedError('Unsupported file format: $path');
  }

  static Future<ExtractionResult> _extractPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final text = _extractPdfText(bytes);
      if (text.trim().isEmpty) {
        return ExtractionResult(
          text: '[PDF file detected but no extractable text found. The PDF may contain only images.]',
          error: 'No text content',
        );
      }
      return ExtractionResult(text: text);
    } catch (e) {
      return ExtractionResult(
        text: '[Error extracting PDF: $e]',
        error: e.toString(),
      );
    }
  }

  static String _extractPdfText(Uint8List bytes) {
    final buffer = StringBuffer();
    final str = String.fromCharCodes(bytes);

    final btEtPattern = RegExp(r'BT\s(.*?)\sET', dotAll: true);
    final matches = btEtPattern.allMatches(str);

    for (final match in matches) {
      final block = match.group(1) ?? '';

      final tjPattern = RegExp(r'\(([^)]*)\)\s*Tj');
      final tjMatches = tjPattern.allMatches(block);
      for (final tj in tjMatches) {
        final text = tj.group(1) ?? '';
        buffer.write(_decodePdfString(text));
        buffer.write(' ');
      }

      final tjArrayPattern = RegExp(r'\[(.*?)\]\s*TJ', dotAll: true);
      final tjArrayMatches = tjArrayPattern.allMatches(block);
      for (final tjArray in tjArrayMatches) {
        final content = tjArray.group(1) ?? '';
        final strParts = RegExp(r'\(([^)]*)\)').allMatches(content);
        for (final part in strParts) {
          buffer.write(_decodePdfString(part.group(1) ?? ''));
        }
        buffer.write(' ');
      }

      final hexPattern = RegExp(r'<([0-9A-Fa-f]+)>\s*Tj');
      final hexMatches = hexPattern.allMatches(block);
      for (final hex in hexMatches) {
        final hexStr = hex.group(1) ?? '';
        final decoded = _decodePdfHex(hexStr);
        if (decoded.isNotEmpty) {
          buffer.write(decoded);
          buffer.write(' ');
        }
      }
    }

    var result = buffer.toString();
    result = result.replaceAll(RegExp(r'endobj'), '\n');
    result = result.replaceAll(RegExp(r'stream|endstream'), ' ');

    final lines = result.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.join('\n');
  }

  static String _decodePdfHex(String hex) {
    try {
      final bytes = <int>[];
      for (var i = 0; i < hex.length - 1; i += 2) {
        final byte = int.tryParse(hex.substring(i, i + 2), radix: 16);
        if (byte != null && byte >= 32 && byte < 127) {
          bytes.add(byte);
        }
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  static String _decodePdfString(String input) {
    try {
      final bytes = <int>[];
      var i = 0;
      while (i < input.length) {
        if (input[i] == '\\' && i + 1 < input.length) {
          final next = input[i + 1];
          if (next == 'n') {
            bytes.add(10);
            i += 2;
          } else if (next == 'r') {
            bytes.add(13);
            i += 2;
          } else if (next == 't') {
            bytes.add(9);
            i += 2;
          } else if (next == '\\') {
            bytes.add(92);
            i += 2;
          } else if (next == '(') {
            bytes.add(40);
            i += 2;
          } else if (next == ')') {
            bytes.add(41);
            i += 2;
          } else {
            bytes.add(input.codeUnitAt(i));
            i++;
          }
        } else {
          bytes.add(input.codeUnitAt(i));
          i++;
        }
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return input;
    }
  }

  static Future<ExtractionResult> _extractDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final docXml = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => throw Exception('word/document.xml not found in DOCX'),
      );

      final xmlContent = utf8.decode(docXml.content as List<int>);
      final doc = XmlDocument.parse(xmlContent);
      final text = _extractXmlText(doc);

      if (text.trim().isEmpty) {
        return ExtractionResult(
          text: '[DOCX file detected but no text content found]',
          error: 'No text content',
        );
      }
      return ExtractionResult(text: text);
    } catch (e) {
      return ExtractionResult(
        text: '[Error extracting DOCX: $e]',
        error: e.toString(),
      );
    }
  }

  static Future<ExtractionResult> _extractPptx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final slideFiles = archive.files
          .where((f) => RegExp(r'ppt/slides/slide\d+\.xml').hasMatch(f.name))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final buffer = StringBuffer();
      for (final slide in slideFiles) {
        final xmlContent = utf8.decode(slide.content as List<int>);
        final doc = XmlDocument.parse(xmlContent);
        final text = _extractXmlText(doc);
        if (text.trim().isNotEmpty) {
          buffer.writeln('--- Slide ---');
          buffer.writeln(text);
          buffer.writeln();
        }
      }

      final result = buffer.toString();
      if (result.trim().isEmpty) {
        return ExtractionResult(
          text: '[PPTX file detected but no text content found]',
          error: 'No text content',
        );
      }
      return ExtractionResult(text: result);
    } catch (e) {
      return ExtractionResult(
        text: '[Error extracting PPTX: $e]',
        error: e.toString(),
      );
    }
  }

  static Future<ExtractionResult> _extractXlsx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final sharedStringsFile = archive.files.firstWhere(
        (f) => f.name == 'xl/sharedStrings.xml',
        orElse: () => throw Exception('sharedStrings.xml not found'),
      );

      final ssContent = utf8.decode(sharedStringsFile.content as List<int>);
      final ssDoc = XmlDocument.parse(ssContent);
      final sharedStrings = <String>[];
      for (final si in ssDoc.findAllElements('si')) {
        final tElements = si.findAllElements('t');
        final value = tElements.map((t) => t.innerText).join('');
        sharedStrings.add(value);
      }

      final sheetFiles = archive.files
          .where((f) => RegExp(r'xl/worksheets/sheet\d+\.xml').hasMatch(f.name))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final buffer = StringBuffer();
      for (final sheet in sheetFiles) {
        final xmlContent = utf8.decode(sheet.content as List<int>);
        final doc = XmlDocument.parse(xmlContent);

        for (final row in doc.findAllElements('row')) {
          final cells = <String>[];
          for (final c in row.findAllElements('c')) {
            final v = c.findElements('v').firstOrNull;
            if (v != null) {
              final val = v.innerText;
              final t = c.getAttribute('t');
              if (t == 's') {
                final idx = int.tryParse(val);
                if (idx != null && idx < sharedStrings.length) {
                  cells.add(sharedStrings[idx]);
                } else {
                  cells.add(val);
                }
              } else {
                cells.add(val);
              }
            }
          }
          if (cells.isNotEmpty) {
            buffer.writeln(cells.join('\t'));
          }
        }
      }

      final result = buffer.toString();
      if (result.trim().isEmpty) {
        return ExtractionResult(
          text: '[XLSX file detected but no text content found]',
          error: 'No text content',
        );
      }
      return ExtractionResult(text: result);
    } catch (e) {
      return ExtractionResult(
        text: '[Error extracting XLSX: $e]',
        error: e.toString(),
      );
    }
  }

  static String _extractXmlText(XmlDocument doc) {
    final buffer = StringBuffer();

    void walk(XmlNode node) {
      if (node is XmlText) {
        final text = node.value.trim();
        if (text.isNotEmpty) {
          buffer.write(text);
          buffer.write(' ');
        }
      }
      for (final child in node.children) {
        walk(child);
      }
    }

    walk(doc);
    return buffer.toString().trim();
  }

  static String _stripHtmlTags(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<br\s*/?\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</?(p|div|li|h[1-6]|tr|td|th)[^>]*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll(RegExp(r'&#x?[0-9a-fA-F]+;'), ' ');
    text = text.replaceAll(RegExp(r'&\w+;'), ' ');
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    return lines.join('\n');
  }

  static bool isSupportedFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.rtf') ||
        lower.endsWith('.html') ||
        lower.endsWith('.htm') ||
        lower.endsWith('.json');
  }

  static String getFileTypeLabel(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF Document';
    if (lower.endsWith('.docx')) return 'Word Document';
    if (lower.endsWith('.pptx')) return 'PowerPoint';
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return 'Spreadsheet';
    if (lower.endsWith('.csv')) return 'CSV Data';
    if (lower.endsWith('.txt')) return 'Text File';
    if (lower.endsWith('.rtf')) return 'Rich Text';
    if (lower.endsWith('.html') || lower.endsWith('.htm')) return 'HTML Page';
    if (lower.endsWith('.json')) return 'JSON Data';
    return 'Unknown';
  }

  static List<String> get supportedExtensions => [
    '.pdf', '.docx', '.pptx',
    '.xlsx', '.xls', '.csv', '.txt', '.rtf',
    '.html', '.htm', '.json',
  ];

  static String _stripRtf(String rtf) {
    var text = rtf;
    text = text.replaceAll(RegExp(r'\{\\[^{}]*\}'), '');
    text = text.replaceAll(RegExp(r'\\[a-z]+\d*\s?'), '');
    text = text.replaceAll(RegExp(r'\\[^a-z{}]'), '');
    text = text.replaceAll('{', '').replaceAll('}', '');
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return lines.join('\n');
  }

  static String _extractJson(String content) {
    try {
      final data = jsonDecode(content);
      if (data is Map<String, dynamic>) {
        return _flattenMap(data);
      } else if (data is List) {
        return data.map((e) => e.toString()).join('\n');
      }
      return content;
    } catch (_) {
      return content;
    }
  }

  static String _flattenMap(Map<String, dynamic> data, [String prefix = '']) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln(_flattenMap(value, '$prefix$key: '));
      } else if (value is List) {
        buffer.writeln('$key: ${value.join(", ")}');
      } else {
        buffer.writeln('$prefix$key: $value');
      }
    });
    return buffer.toString();
  }
}

class ExtractionResult {
  final String text;
  final String? error;

  ExtractionResult({required this.text, this.error});

  bool get hasError => error != null;
  bool get isEmpty => text.trim().length < 30;
}
