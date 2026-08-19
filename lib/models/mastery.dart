import 'dart:convert';

class Mastery {
  final String id;
  final String materialTitle;
  final String sourceText;
  final List<String> concepts;
  final String notes;
  final String? folderId;
  final double masteryPercent;
  final int totalCorrect;
  final int totalAttempted;
  final int challenge1Score;
  final int challenge2Score;
  final bool challenge1Unlocked;
  final bool challenge2Unlocked;
  final bool fullyMastered;
  final int stars;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Mastery({
    required this.id,
    required this.materialTitle,
    required this.sourceText,
    required this.concepts,
    this.notes = '',
    this.folderId,
    this.masteryPercent = 0.0,
    this.totalCorrect = 0,
    this.totalAttempted = 0,
    this.challenge1Score = 0,
    this.challenge2Score = 0,
    this.challenge1Unlocked = false,
    this.challenge2Unlocked = false,
    this.fullyMastered = false,
    this.stars = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Mastery copyWith({
    double? masteryPercent,
    int? totalCorrect,
    int? totalAttempted,
    int? challenge1Score,
    int? challenge2Score,
    bool? challenge1Unlocked,
    bool? challenge2Unlocked,
    bool? fullyMastered,
    int? stars,
    String? notes,
    String? folderId,
    DateTime? updatedAt,
  }) {
    return Mastery(
      id: id,
      materialTitle: materialTitle,
      sourceText: sourceText,
      concepts: concepts,
      notes: notes ?? this.notes,
      folderId: folderId ?? this.folderId,
      masteryPercent: masteryPercent ?? this.masteryPercent,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalAttempted: totalAttempted ?? this.totalAttempted,
      challenge1Score: challenge1Score ?? this.challenge1Score,
      challenge2Score: challenge2Score ?? this.challenge2Score,
      challenge1Unlocked: challenge1Unlocked ?? this.challenge1Unlocked,
      challenge2Unlocked: challenge2Unlocked ?? this.challenge2Unlocked,
      fullyMastered: fullyMastered ?? this.fullyMastered,
      stars: stars ?? this.stars,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialTitle': materialTitle,
      'sourceText': sourceText,
      'concepts': jsonEncode(concepts),
      'notes': notes,
      'folderId': folderId,
      'masteryPercent': masteryPercent,
      'totalCorrect': totalCorrect,
      'totalAttempted': totalAttempted,
      'challenge1Score': challenge1Score,
      'challenge2Score': challenge2Score,
      'challenge1Unlocked': challenge1Unlocked ? 1 : 0,
      'challenge2Unlocked': challenge2Unlocked ? 1 : 0,
      'fullyMastered': fullyMastered ? 1 : 0,
      'stars': stars,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Mastery.fromMap(Map<String, dynamic> map) {
    return Mastery(
      id: map['id'] ?? '',
      materialTitle: map['materialTitle'] ?? '',
      sourceText: map['sourceText'] ?? '',
      concepts: List<String>.from(jsonDecode(map['concepts'] ?? '[]')),
      notes: map['notes'] ?? '',
      folderId: map['folderId'],
      masteryPercent: (map['masteryPercent'] ?? 0.0).toDouble(),
      totalCorrect: map['totalCorrect'] ?? 0,
      totalAttempted: map['totalAttempted'] ?? 0,
      challenge1Score: map['challenge1Score'] ?? 0,
      challenge2Score: map['challenge2Score'] ?? 0,
      challenge1Unlocked: (map['challenge1Unlocked'] ?? 0) == 1,
      challenge2Unlocked: (map['challenge2Unlocked'] ?? 0) == 1,
      fullyMastered: (map['fullyMastered'] ?? 0) == 1,
      stars: map['stars'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
