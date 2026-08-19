class Folder {
  final String id;
  final String name;
  final int colorIndex;
  final DateTime createdAt;

  const Folder({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    required this.createdAt,
  });

  Folder copyWith({String? name, int? colorIndex}) {
    return Folder(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorIndex: map['colorIndex'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
