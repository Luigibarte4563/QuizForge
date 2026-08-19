import 'dart:math';
import '../models/question.dart';
import '../models/quiz_settings.dart';

class LocalQuizGenerator {
  static final LocalQuizGenerator _instance = LocalQuizGenerator._();
  factory LocalQuizGenerator() => _instance;
  LocalQuizGenerator._();

  final _random = Random();

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

  List<Question> generate({
    required String content,
    required QuizSettings settings,
  }) {
    return generateMixed(
      content: content,
      count: settings.questionCount,
      mixedTypes: false,
      preferredType: settings.questionType,
    );
  }

  List<Question> generateMixed({
    required String content,
    required int count,
    bool mixedTypes = true,
    QuestionType? preferredType,
  }) {
    final cleaned = _cleanText(content);
    final sentences = _extractSentences(cleaned);
    final validSentences = sentences.where(_isGoodSentence).toList();

    if (validSentences.isEmpty) return [];

    final topicGroups = _buildTopicGroups(validSentences, cleaned);

    final questions = <Question>[];
    var remaining = List<int>.generate(validSentences.length, (i) => i)
      ..shuffle(_random);

    final types = [
      QuestionType.multipleChoice,
      QuestionType.trueFalse,
      QuestionType.fillInTheBlank,
    ];

    for (var i = 0; i < count && i < remaining.length; i++) {
      final idx = remaining[i];
      final sentence = validSentences[idx];
      final topic = _findBestTopic(sentence, topicGroups);
      final type = (!mixedTypes && preferredType != null) ? preferredType : types[i % types.length];

      Question? q;
      switch (type) {
        case QuestionType.multipleChoice:
          q = _makeMCQ(sentence, topicGroups, topic);
        case QuestionType.trueFalse:
          q = _makeTrueFalse(sentence, topicGroups, topic);
        case QuestionType.fillInTheBlank:
          q = _makeFillBlank(sentence, topic);
        case QuestionType.mixed:
          q = _makeMCQ(sentence, topicGroups, topic);
      }

      if (q != null && _validateQuestion(q)) {
        questions.add(q);
      }
    }

    return questions;
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
        .where((s) => s.split(' ').length >= 5 && s.length >= 20)
        .toList();
  }

  bool _isGoodSentence(String s) {
    if (s.contains(RegExp(r'[^\x00-\x7F]'))) return false;
    if (s.contains(RegExp(r'\d{4,}'))) return false;
    if (s.contains(RegExp(r'[=]{3,}'))) return false;
    if (s.contains(RegExp(r'[-]{5,}'))) return false;
    if (s.contains(RegExp(r'[_]{3,}'))) return false;

    final words = s.split(RegExp(r'\W+')).where((w) => w.isNotEmpty).toList();
    final stopCount = words.where((w) => _stopwords.contains(w.toLowerCase())).length;
    if (stopCount > words.length * 0.6) return false;

    final realWords = words
        .where((w) => !_stopwords.contains(w.toLowerCase()) && w.length > 2)
        .toList();
    return realWords.length >= 3;
  }

  Map<String, List<String>> _buildTopicGroups(List<String> sentences, String fullText) {
    final lower = fullText.toLowerCase();
    final words = lower.split(RegExp(r'\W+'));
    final freq = <String, int>{};
    for (final w in words) {
      if (w.length > 3 && !_stopwords.contains(w)) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }

    final capPattern = RegExp(r'\b[A-Z][a-z]{2,}(?:\s+[A-Z][a-z]{2,}){0,2}\b');
    final properNouns = <String>{};
    for (final m in capPattern.allMatches(fullText)) {
      final term = m.group(0)!;
      if (term.split(' ').length <= 3 && !_stopwords.contains(term.toLowerCase())) {
        properNouns.add(term);
      }
    }

    final topWords = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topicKeywords = topWords.take(15).map((e) => e.key).toList();

    final topics = <String, List<String>>{};
    for (final kw in topicKeywords) {
      final label = _capitalize(kw);
      topics[label] = sentences.where((s) => s.toLowerCase().contains(kw)).toList();
    }

    for (final pn in properNouns) {
      if (!topics.containsKey(pn)) {
        topics[pn] = sentences.where((s) => s.contains(pn)).toList();
      }
    }

    topics.removeWhere((k, v) => v.isEmpty);
    if (topics.isEmpty) topics['General'] = sentences;

    return topics;
  }

  String _findBestTopic(String sentence, Map<String, List<String>> topics) {
    final lower = sentence.toLowerCase();
    String bestTopic = topics.keys.first;
    int bestScore = 0;

    for (final entry in topics.entries) {
      int score = 0;
      for (final s in entry.value) {
        if (s == sentence) score += 5;
      }
      for (final part in entry.key.toLowerCase().split(' ')) {
        if (part.length > 2 && lower.contains(part)) score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        bestTopic = entry.key;
      }
    }
    return bestTopic;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Question? _makeMCQ(String sentence, Map<String, List<String>> topics, String topic) {
    final words = _getMeaningfulWords(sentence);
    if (words.isEmpty) return null;

    final target = words[_random.nextInt(words.length)];
    final questionText = sentence.replaceAll(
      RegExp(r'\b' + RegExp.escape(target) + r'\b', caseSensitive: false),
      '________',
    );
    if (questionText == sentence) return null;

    final distractors = _getDistractors(target, topic, topics);
    if (distractors.length < 3) return null;

    final options = [target, ...distractors.take(3)];
    options.shuffle(_random);

    final explanation = _findExplanationForWord(target, sentence, topics);
    final wrongExplains = distractors.take(3).map((d) => '"$d" is incorrect because it does not fit the context of this statement').join('; ');

    return Question(
      question: questionText,
      options: options.map((o) => _capitalize(o)).toList(),
      answer: options.indexOf(target),
      topic: topic,
      type: QuestionType.multipleChoice,
      explanation: '$explanation $wrongExplains',
    );
  }

  Question? _makeTrueFalse(String sentence, Map<String, List<String>> topics, String topic) {
    final isTrue = _random.nextBool();

    if (isTrue) {
      final explanation = _findExplanationForSentence(sentence, topics);
      return Question(
        question: sentence,
        options: const ['True', 'False'],
        answer: 0,
        topic: topic,
        type: QuestionType.trueFalse,
        explanation: explanation,
      );
    }

    final words = _getMeaningfulWords(sentence);
    if (words.isEmpty) return null;

    final wordToReplace = words[_random.nextInt(words.length)];
    final alts = _getDistractors(wordToReplace, topic, topics);
    if (alts.isEmpty) return null;

    final replacement = alts[_random.nextInt(alts.length)];
    final question = sentence.replaceAll(
      RegExp(r'\b' + RegExp.escape(wordToReplace) + r'\b', caseSensitive: false),
      replacement,
    );

    final explanation = 'The statement is TRUE. $sentence '
        'It is false when "$wordToReplace" is replaced with "$replacement" because that changes the meaning of the original fact.';

    return Question(
      question: question,
      options: const ['True', 'False'],
      answer: 1,
      topic: topic,
      type: QuestionType.trueFalse,
      explanation: explanation,
    );
  }

  Question? _makeFillBlank(String sentence, String topic) {
    final words = _getMeaningfulWords(sentence);
    if (words.isEmpty) return null;

    final target = words[_random.nextInt(words.length)];
    final questionText = sentence.replaceAll(
      RegExp(r'\b' + RegExp.escape(target) + r'\b', caseSensitive: false),
      '________',
    );
    if (questionText == sentence) return null;

    final explanation = 'In the original text: "$sentence" '
        'The correct term is "$target".';

    return Question(
      question: questionText,
      options: [target],
      answer: 0,
      topic: topic,
      type: QuestionType.fillInTheBlank,
      explanation: explanation,
    );
  }

  List<String> _getMeaningfulWords(String sentence) {
    final words = sentence.split(RegExp(r'\W+'));
    return words
        .where((w) =>
            w.length > 3 &&
            !_stopwords.contains(w.toLowerCase()) &&
            !RegExp(r'^\d+$').hasMatch(w))
        .toList();
  }

  List<String> _getDistractors(String exclude, String topic, Map<String, List<String>> topics) {
    final candidates = <String>{};

    if (topics.containsKey(topic)) {
      for (final s in topics[topic]!) {
        for (final w in _getMeaningfulWords(s)) {
          if (w.toLowerCase() != exclude.toLowerCase()) {
            candidates.add(w);
          }
        }
      }
    }

    for (final entry in topics.entries) {
      if (entry.key == topic) continue;
      for (final s in entry.value.take(5)) {
        for (final w in _getMeaningfulWords(s)) {
          if (w.toLowerCase() != exclude.toLowerCase() && candidates.length < 50) {
            candidates.add(w);
          }
        }
      }
    }

    final result = candidates.toList()..shuffle(_random);
    return result;
  }

  String _findExplanationForWord(String word, String sentence, Map<String, List<String>> topics) {
    for (final entry in topics.entries) {
      for (final s in entry.value) {
        if (s.contains(word) && s != sentence) {
          return 'According to the material: "$s"';
        }
      }
    }
    return 'The correct answer is "$word" as stated in the source material.';
  }

  String _findExplanationForSentence(String sentence, Map<String, List<String>> topics) {
    return 'This statement is directly supported by the learning material. "$sentence"';
  }

  bool _validateQuestion(Question q) {
    if (q.question.trim().isEmpty) return false;
    if (q.question.length < 15) return false;
    if (!q.question.contains(RegExp(r'[a-zA-Z]{3,}'))) return false;

    if (q.type != QuestionType.trueFalse) {
      if (q.options.any((o) => o.trim().isEmpty)) return false;
      if (q.options.any((o) => o.length > 100)) return false;
    }

    return true;
  }
}
