class ContentAnalyzer {
  static final ContentAnalyzer _instance = ContentAnalyzer._();
  factory ContentAnalyzer() => _instance;
  ContentAnalyzer._();

  static const _stopwords = {
    'this', 'that', 'with', 'from', 'have', 'been', 'were', 'they',
    'their', 'them', 'than', 'then', 'what', 'when', 'where', 'which',
    'will', 'would', 'could', 'should', 'about', 'into', 'over', 'such',
    'also', 'more', 'most', 'other', 'some', 'very', 'each', 'just',
    'only', 'like', 'well', 'back', 'make', 'many', 'much', 'does',
    'here', 'there', 'being', 'both', 'between', 'through', 'after',
    'before', 'under', 'during', 'using', 'used', 'may', 'might',
    'shall', 'must', 'need', 'able', 'same', 'still', 'even', 'first',
    'last', 'long', 'great', 'little', 'own', 'old', 'right', 'big',
    'high', 'small', 'large', 'next', 'early', 'young', 'important',
    'few', 'public', 'bad', 'part', 'keep', 'let', 'seem', 'help',
    'show', 'hear', 'play', 'run', 'move', 'live', 'believe', 'bring',
    'happen', 'take', 'come', 'made', 'find', 'give', 'tell', 'work',
    'call', 'try', 'ask', 'feel', 'become', 'leave', 'put', 'mean',
    'begin', 'hold', 'write', 'provide', 'sit', 'stand', 'lose', 'pay',
    'meet', 'include', 'continue', 'set', 'learn', 'change', 'lead',
    'understand', 'watch', 'follow', 'stop', 'create', 'speak', 'read',
    'allow', 'add', 'spend', 'grow', 'open', 'walk', 'win', 'offer',
    'remember', 'love', 'consider', 'appear', 'buy', 'wait', 'serve',
    'die', 'send', 'expect', 'build', 'stay', 'fall', 'cut', 'reach',
    'kill', 'remain', 'suggest', 'raise', 'pass', 'sell', 'require',
    'report', 'decide', 'pull', 'however', 'though', 'yet', 'either',
    'neither', 'every', 'often', 'never', 'always', 'sometimes',
    'usually', 'perhaps', 'rather', 'quite', 'enough', 'already',
    'making', 'things', 'thing', 'itself', 'yourself', 'himself',
    'herself', 'its', 'people', 'time', 'year', 'way', 'day', 'man',
    'woman', 'child', 'world', 'life', 'hand', 'place', 'case', 'week',
    'per', 'any', 'all', 'can', 'our', 'one', 'two', 'three', 'four',
    'five', 'six', 'seven', 'eight', 'nine', 'ten', 'new', 'now', 'see',
    'him', 'her', 'his', 'she', 'not', 'you', 'how', 'out', 'got',
    'get', 'had', 'has', 'did', 'done', 'says', 'said',
  };

  AnalyzedContent analyze(String text) {
    final cleaned = _cleanText(text);
    final sentences = _extractSentences(cleaned);
    final validSentences = sentences.where(_isGoodSentence).toList();

    final topics = _splitIntoTopics(cleaned, validSentences);
    final concepts = extractConcepts(cleaned);

    final wordCount = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final summary = cleaned.length > 500 ? '${cleaned.substring(0, 500)}...' : cleaned;

    final title = _extractTitle(cleaned, concepts);

    return AnalyzedContent(
      title: title,
      topics: topics,
      keyConcepts: concepts,
      wordCount: wordCount,
      summary: summary,
      fullText: cleaned,
    );
  }

  List<String> extractConcepts(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\W+'));

    final freq = <String, int>{};
    for (final w in words) {
      if (w.length > 3 && !_stopwords.contains(w)) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }

    final capPattern = RegExp(r'\b[A-Z][a-z]{2,}(?:\s+[A-Z][a-z]{2,}){0,2}\b');
    final properNouns = <String, int>{};
    for (final m in capPattern.allMatches(text)) {
      final term = m.group(0)!;
      if (term.split(' ').length <= 3 && !_stopwords.contains(term.toLowerCase())) {
        properNouns[term] = (properNouns[term] ?? 0) + 1;
      }
    }

    final concepts = <String>[];

    for (final entry in properNouns.entries) {
      if (entry.value >= 2) {
        concepts.add(entry.key);
      }
    }

    final topWords = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in topWords.take(10)) {
      final capitalized = _capitalize(entry.key);
      if (!concepts.any((c) => c.toLowerCase() == entry.key)) {
        concepts.add(capitalized);
      }
    }

    return concepts.take(15).toList();
  }

  List<TopicSection> _splitIntoTopics(String fullText, List<String> sentences) {
    final paragraphs = fullText.split(RegExp(r'\n\s*\n'));
    final topics = <TopicSection>[];

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.length < 30) continue;

      final paraSentences = _extractSentences(trimmed)
          .where(_isGoodSentence)
          .toList();

      if (paraSentences.isEmpty) continue;

      final title = _extractTopicTitle(trimmed);
      final keywords = _extractKeywords(trimmed);

      topics.add(TopicSection(
        title: title,
        content: trimmed,
        keywords: keywords,
        sentences: paraSentences,
      ));
    }

    if (topics.isEmpty && sentences.isNotEmpty) {
      final chunkSize = (sentences.length / 5).ceil().clamp(3, 10);
      for (var i = 0; i < sentences.length; i += chunkSize) {
        final chunk = sentences.sublist(i, (i + chunkSize).clamp(0, sentences.length));
        final chunkText = chunk.join(' ');
        topics.add(TopicSection(
          title: _extractTopicTitle(chunkText),
          content: chunkText,
          keywords: _extractKeywords(chunkText),
          sentences: chunk,
        ));
      }
    }

    return topics;
  }

  String findRelevantContext(String text, String query) {
    final queryWords = query.toLowerCase().split(RegExp(r'\W+'))
        .where((w) => w.length > 2 && !_stopwords.contains(w))
        .toList();

    if (queryWords.isEmpty) return text.length > 2000 ? text.substring(0, 2000) : text;

    final sentences = _extractSentences(text);
    final scored = <MapEntry<String, double>>[];

    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      var score = 0.0;
      for (final word in queryWords) {
        if (lower.contains(word)) score += 1.0;
      }
      if (score > 0) {
        scored.add(MapEntry(sentence, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    var totalLength = 0;
    for (final entry in scored.take(10)) {
      if (totalLength + entry.key.length > 2000) break;
      buffer.writeln(entry.key);
      totalLength += entry.key.length;
    }

    if (buffer.isEmpty) {
      return text.length > 2000 ? text.substring(0, 2000) : text;
    }

    return buffer.toString();
  }

  String _cleanText(String content) {
    return content
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\r'), '\n')
        .replaceAll(RegExp(r'\t'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  List<String> _extractSentences(String text) {
    final raw = text.split(RegExp(r'(?<=[.!?])\s*(?=\n|[A-Z])'));
    return raw
        .map((s) => s.trim())
        .where((s) => s.split(' ').length >= 4 && s.length >= 15)
        .toList();
  }

  bool _isGoodSentence(String s) {
    if (s.contains(RegExp(r'[=]{3,}'))) return false;
    if (s.contains(RegExp(r'[-]{5,}'))) return false;
    if (s.contains(RegExp(r'[_]{3,}'))) return false;

    final words = s.split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    final stopCount = words.where((w) => _stopwords.contains(w.toLowerCase())).length;
    if (words.isNotEmpty && stopCount / words.length > 0.6) return false;

    final realWords = words
        .where((w) => !_stopwords.contains(w.toLowerCase()) && w.length > 2)
        .toList();
    return realWords.length >= 3;
  }

  String _extractTitle(String text, List<String> concepts) {
    final firstLine = text.split('\n').first.trim();
    if (firstLine.length < 50 && firstLine.split(' ').length <= 10) {
      return firstLine;
    }
    if (concepts.isNotEmpty) return concepts.first;
    return 'Learning Material';
  }

  String _extractTopicTitle(String text) {
    final firstSentence = _extractSentences(text).firstOrNull;
    if (firstSentence != null && firstSentence.length < 60) {
      return firstSentence;
    }

    final words = text.split(RegExp(r'\W+'))
        .where((w) => w.length > 3 && !_stopwords.contains(w.toLowerCase()))
        .toList();

    if (words.length >= 2) {
      return '${_capitalize(words[0])} ${_capitalize(words[1])}';
    }
    return 'Topic';
  }

  List<String> _extractKeywords(String text) {
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\W+'));

    final freq = <String, int>{};
    for (final w in words) {
      if (w.length > 3 && !_stopwords.contains(w)) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => _capitalize(e.key)).toList();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class AnalyzedContent {
  final String title;
  final List<TopicSection> topics;
  final List<String> keyConcepts;
  final int wordCount;
  final String summary;
  final String fullText;

  AnalyzedContent({
    required this.title,
    required this.topics,
    required this.keyConcepts,
    required this.wordCount,
    required this.summary,
    required this.fullText,
  });

  int get conceptCount => keyConcepts.length;
  int get topicCount => topics.length;
}

class TopicSection {
  final String title;
  final String content;
  final List<String> keywords;
  final List<String> sentences;

  TopicSection({
    required this.title,
    required this.content,
    required this.keywords,
    required this.sentences,
  });
}
