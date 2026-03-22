class ProfileData {
  final String userId;
  final double? heightCm;
  final double? weightKg;
  final int? frequency;
  final String? mode;
  final DateTime? birthday;
  final String? gender;
  final String? experience;

  const ProfileData({
    required this.userId,
    this.heightCm,
    this.weightKg,
    this.frequency,
    this.mode,
    this.birthday,
    this.gender,
    this.experience,
  });

  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  int get age {
    if (birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      userId: map['user_id'] as String,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      frequency: (map['frequency'] as num?)?.toInt(),
      mode: map['mode'] as String?,
      birthday: map['birthday'] != null
          ? DateTime.tryParse(map['birthday'] as String)
          : null,
      gender: map['gender'] as String?,
      experience: map['experience'] as String?,
    );
  }
}