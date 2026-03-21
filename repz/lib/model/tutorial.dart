enum TutorialSource {
  youtube('youtube'),
  instagram('instagram'),
  facebook('facebook'),
  tiktok('tiktok');

  const TutorialSource(this.dbValue);

  final String dbValue;

  static TutorialSource? fromDbValue(String? value) {
    if (value == null) return null;
    for (final source in TutorialSource.values) {
      if (source.dbValue == value) return source;
    }
    return null;
  }
}

class Tutorial {
  final String id;
  final String equipmentId;
  final String description;
  final String tutorialLink;
  final TutorialSource source;

  const Tutorial({
    required this.id,
    required this.equipmentId,
    required this.description,
    required this.tutorialLink,
    required this.source,
  });

  factory Tutorial.fromMap(Map<String, dynamic> map) {
    final source = TutorialSource.fromDbValue(map['source'] as String?);
    if (source == null) {
      throw ArgumentError('Invalid tutorial source: ${map['source']}');
    }

    return Tutorial(
      id: map['id'] as String,
      equipmentId: map['equipment_id'] as String,
      description: map['description'] as String,
      tutorialLink: map['tutorial_link'] as String,
      source: source,
    );
  }

  Tutorial copyWith({
    String? id,
    String? equipmentId,
    String? description,
    String? tutorialLink,
    TutorialSource? source,
  }) {
    return Tutorial(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      description: description ?? this.description,
      tutorialLink: tutorialLink ?? this.tutorialLink,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'description': description,
      'tutorial_link': tutorialLink,
      'source': source.dbValue,
    };
  }
}

