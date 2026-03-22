import 'package:flutter/material.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/prebuilt_workout_plans_page.dart';
import 'package:repz/views/workout_builder_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklySchedulePage extends StatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  State<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends State<WeeklySchedulePage> {
  static const Map<int, String> _weekdayLabels = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  bool _isLoading = true;
  List<WorkoutPlan> _plans = const <WorkoutPlan>[];
  List<WorkoutScheduleProfile> _profiles = const <WorkoutScheduleProfile>[];
  WorkoutScheduleProfile? _selectedProfile;
  Map<int, String?> _dayToPlanId = <int, String?>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final selfProfile = await _repository.ensureSelfScheduleProfile();
      final plans = await _repository.fetchPlans();
      final profiles = await _repository.fetchScheduleProfiles();

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _profiles = profiles;
      });

      final selected =
          _selectedProfile == null
              ? profiles.firstWhere(
                (profile) => profile.id == selfProfile.id,
                orElse: () => selfProfile,
              )
              : profiles.firstWhere(
                (profile) => profile.id == _selectedProfile!.id,
                orElse: () => selfProfile,
              );
      _selectProfile(selected);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not load your weekly schedule.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectProfile(WorkoutScheduleProfile profile) {
    _selectedProfile = profile;
    _dayToPlanId = {
      for (final day in _weekdayLabels.keys)
        day: profile.days
            .where((entry) => entry.dayOfWeek == day)
            .map((entry) => entry.workoutPlanId)
            .cast<String?>()
            .firstOrNull,
    };
  }

  bool get _canEditSelectedProfile =>
      _selectedProfile?.sourceType == ScheduleProfileSourceType.self;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveSelfSchedule() async {
    final profile = _selectedProfile;
    if (profile == null || !_canEditSelectedProfile) return;

    try {
      await _repository.saveScheduleProfileDays(
        profileId: profile.id,
        dayToPlanId: _dayToPlanId,
      );
      await _load();
      _showMessage('Schedule updated.');
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not update the schedule.');
    }
  }

  Future<void> _activateSelectedProfile() async {
    final profile = _selectedProfile;
    if (profile == null) return;

    try {
      await _repository.activateScheduleProfile(profile.id);
      await _load();
      _showMessage('"${profile.name}" is now your active schedule.');
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not activate this schedule.');
    }
  }

  Future<void> _openBuilder() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const WorkoutBuilderPage()),
    );
    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final today = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose the schedule you want to follow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your Home tab always follows the schedule profile marked active below.',
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _profiles.map((profile) {
                                  final isSelected =
                                      _selectedProfile?.id == profile.id;
                                  final isActive = profile.isActive;
                                  return ChoiceChip(
                                    selected: isSelected,
                                    label: Text(
                                      isActive
                                          ? '${profile.name} • Active'
                                          : profile.name,
                                    ),
                                    onSelected: (_) {
                                      setState(() => _selectProfile(profile));
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _activateSelectedProfile,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Set Active Schedule'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const PrebuiltWorkoutPlansPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Pre-built Plans'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._weekdayLabels.entries.map((entry) {
                      final assignedPlanId = _dayToPlanId[entry.key];
                      final assignedPlan = _selectedProfile?.days
                          .where((day) => day.dayOfWeek == entry.key)
                          .map((day) => day.plan)
                          .firstOrNull;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  entry.key == today
                                      ? accentColor
                                      : accentColor.withValues(alpha: 0.16),
                              width: entry.key == today ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.value,
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  if (entry.key == today) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Today',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? accentColor
                                              : Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_canEditSelectedProfile)
                                DropdownButtonFormField<String?>(
                                  initialValue: assignedPlanId,
                                  decoration: const InputDecoration(
                                    labelText: 'Assigned plan',
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('No plan assigned'),
                                    ),
                                    ..._plans.map(
                                      (plan) => DropdownMenuItem<String?>(
                                        value: plan.id,
                                        child: Text(
                                          plan.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _dayToPlanId[entry.key] = value);
                                  },
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: accentColor.withValues(alpha: 0.08),
                                  ),
                                  child: Text(
                                    assignedPlan?.name ?? 'No plan assigned',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_canEditSelectedProfile)
                      FilledButton.icon(
                        onPressed: _saveSelfSchedule,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save My Schedule'),
                      ),
                  ],
                ),
              ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
