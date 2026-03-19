import 'package:flutter/material.dart';
import 'package:repz/config/app_colors.dart';
import 'package:repz/model/profile.dart';
import 'package:repz/ui_components/buttons/wide_proceed_button.dart';

class OnboardingFormData {
  const OnboardingFormData({
    required this.birthday,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.experience,
    required this.frequency,
  });

  final DateTime birthday;
  final String gender;
  final double heightCm;
  final double weightKg;
  final ExperienceLevel experience;
  final int frequency;
}

class ProfileOnboardingPage extends StatefulWidget {
  const ProfileOnboardingPage({
    super.key,
    required this.onSubmit,
    this.userName,
    this.avatarUrl,
    this.isLoading = false,
    this.onBack,
  });

  final Future<void> Function(OnboardingFormData data) onSubmit;
  final String? userName;
  final String? avatarUrl;
  final bool isLoading;
  final VoidCallback? onBack;

  @override
  State<ProfileOnboardingPage> createState() => _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends State<ProfileOnboardingPage> {
  int _step = 0;

  DateTime? _birthday;
  String _gender = 'Man';
  double _heightCm = 175;
  double _weightKg = 70;
  ExperienceLevel _experience = ExperienceLevel.expert;
  int _frequency = 3;

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 25, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() => _birthday = selected);
    }
  }

  Future<void> _pickGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const options = <String>[
          'Man',
          'Woman',
          'Non-binary',
          'Prefer not to say',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(
                      option,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _gender = selected);
    }
  }

  Future<void> _pickNumber({
    required String title,
    required String initialValue,
    required String unit,
    required int min,
    required int max,
    required ValueChanged<int> onSaved,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              autofocus: true,
              decoration: InputDecoration(hintText: '$min - $max $unit'),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null) {
                  return 'Enter a number';
                }
                if (parsed < min || parsed > max) {
                  return 'Use $min-$max $unit';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final parsed = int.tryParse(controller.text.trim());
      if (parsed != null) {
        setState(() => onSaved(parsed));
      }
    }
  }

  Future<void> _pickExperience() async {
    final selected = await showModalBottomSheet<ExperienceLevel>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in ExperienceLevel.values)
                  ListTile(
                    title: Text(
                      _experienceLabel(option),
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _experience = selected);
    }
  }

  Future<void> _submit() async {
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    final birthday = _birthday;
    if (birthday == null) {
      return;
    }

    await widget.onSubmit(
      OnboardingFormData(
        birthday: birthday,
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        experience: _experience,
        frequency: _frequency,
      ),
    );
  }

  bool get _canContinue {
    if (_step == 0) {
      return _birthday != null && _gender.trim().isNotEmpty;
    }
    if (_step == 1) {
      return _heightCm > 0 && _weightKg > 0;
    }
    return _frequency >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = _step == 2 ? 'Let\'s Go' : 'Next';
    final titleName = _firstName(widget.userName) ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          if (_step > 0) {
                            setState(() => _step -= 1);
                            return;
                          }
                          widget.onBack?.call();
                        },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF34446B),
                  size: 34,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Getting Started',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        height: 1,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.white,
                    backgroundImage:
                        widget.avatarUrl != null
                            ? NetworkImage(widget.avatarUrl!)
                            : null,
                    child:
                        widget.avatarUrl == null
                            ? Text(
                              titleName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            )
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Expanded(child: _buildStepContent()),
              WideProceedButton(
                text: buttonText,
                backgroundColor: AppColors.black,
                textColor: AppColors.white,
                arrowBackgroundColor: AppColors.accent,
                arrowIconColor: AppColors.black,
                enabled: !widget.isLoading && _canContinue,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionValueRow(
            title: 'Your birthday?',
            value: _birthday != null ? _formatDate(_birthday!) : 'Select Date',
            valueSize: 40,
            onTap: _pickBirthday,
          ),
          const SizedBox(height: 80),
          _SectionValueRow(
            title: 'Who are you?',
            value: _gender,
            valueSize: _textValueSize(_gender),
            onTap: _pickGender,
          ),
        ],
      );
    }

    if (_step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionValueRow(
            title: 'Your Height?',
            value: _heightCm.round().toString(),
            trailingText: 'CM',
            valueSize: 90,
            onTap:
                () => _pickNumber(
                  title: 'Height (cm)',
                  initialValue: _heightCm.round().toString(),
                  unit: 'cm',
                  min: 50,
                  max: 260,
                  onSaved: (value) => _heightCm = value.toDouble(),
                ),
          ),
          const SizedBox(height: 80),
          _SectionValueRow(
            title: 'Your Weight?',
            value: _weightKg.round().toString(),
            valueSize: 90,
            trailingText: 'KG',
            onTap:
                () => _pickNumber(
                  title: 'Weight (kg)',
                  initialValue: _weightKg.round().toString(),
                  unit: 'kg',
                  min: 20,
                  max: 300,
                  onSaved: (value) => _weightKg = value.toDouble(),
                ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionValueRow(
          title: 'I am an',
          value: _experienceLabel(_experience),
          valueSize: _textValueSize(_experienceLabel(_experience)),
          onTap: _pickExperience,
        ),
        const SizedBox(height: 80),
        _SectionValueRow(
          title: 'Frequency',
          valueSize: _textValueSize(_frequency.toString()),
          value: _frequency.toString(),
          trailingText: 'days/week',
          onTap:
              () => _pickNumber(
                title: 'Workout frequency',
                initialValue: _frequency.toString(),
                unit: 'days/week',
                min: 1,
                max: 7,
                onSaved: (value) => _frequency = value,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _experienceLabel(ExperienceLevel value) {
    switch (value) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.expert:
        return 'Expert';
    }
  }

  double _textValueSize(String text) {
    if (text.length <= 3) {
      return 72;
    }
    if (text.length <= 7) {
      return 65;
    }
    if (text.length <= 9) {
      return 55;
    }
    if (text.length <= 10) {
      return 45;
    }
    if (text.length <= 12) {
      return 40;
    }
    return 30;
  }

  String? _firstName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }
    return name.trim().split(' ').first;
  }
}

class _SectionValueRow extends StatelessWidget {
  const _SectionValueRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.trailingText,
    this.valueSize = 120,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final String? trailingText;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 36,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 22),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: valueSize,
                            letterSpacing: -1,
                            height: 0.95,
                            color: AppColors.black,
                          ),
                        ),
                        if (trailingText != null)
                          TextSpan(
                            text: ' $trailingText',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: valueSize * 0.42,
                              color: AppColors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  size: 82,
                  color: Color(0xFF34446B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
