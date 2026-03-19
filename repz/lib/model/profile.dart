enum ProfileMode {
  user('USER'),
  trainer('TRAINER');

  const ProfileMode(this.dbValue);

  final String dbValue;

  static ProfileMode? fromDbValue(String? value) {
    if (value == null) return null;
    for (final mode in ProfileMode.values) {
      if (mode.dbValue == value) return mode;
    }
    return null;
  }
}

enum ExperienceLevel {
  beginner('BEGINNER'),
  intermediate('INTERMEDIATE'),
  expert('EXPERT');

  const ExperienceLevel(this.dbValue);

  final String dbValue;

  static ExperienceLevel? fromDbValue(String? value) {
    if (value == null) return null;
    for (final level in ExperienceLevel.values) {
      if (level.dbValue == value) return level;
    }
    return null;
  }
}

class Profile {
  final String userId;
  final bool firstTime;
  final ProfileMode? mode;
  final String? userName;
  final String? userEmail;
  final String? avatarUrl;
  final DateTime? birthday;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final ExperienceLevel? experience;
  final int? frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.userId,
    required this.firstTime,
    this.mode,
    this.userName,
    this.userEmail,
    this.avatarUrl,
    this.birthday,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.experience,
    this.frequency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'] as String,
      firstTime: map['first_time'] as bool,
      mode: ProfileMode.fromDbValue(map['mode'] as String?),
      userName: (map['user_name'] ?? map['full_name']) as String?,
      userEmail: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      birthday:
          map['birthday'] == null
              ? null
              : DateTime.parse(map['birthday'] as String),
      gender: map['gender'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      experience: ExperienceLevel.fromDbValue(map['experience'] as String?),
      frequency: map['frequency'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Profile copyWith({
    String? userId,
    bool? firstTime,
    ProfileMode? mode,
    String? userName,
    String? userEmail,
    String? avatarUrl,
    DateTime? birthday,
    String? gender,
    double? heightCm,
    double? weightKg,
    ExperienceLevel? experience,
    int? frequency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      firstTime: firstTime ?? this.firstTime,
      mode: mode ?? this.mode,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      experience: experience ?? this.experience,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'first_time': firstTime,
      'mode': mode?.dbValue,
      'birthday': birthday?.toIso8601String(),
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'experience': experience?.dbValue,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
