import 'package:flutter/material.dart';
import 'package:repz/model/client.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerScheduleEditorPage extends StatefulWidget {
  const TrainerScheduleEditorPage({
    super.key,
    required this.client,
    required this.isDarkMode,
  });

  final Client client;
  final bool isDarkMode;

  @override
  State<TrainerScheduleEditorPage> createState() =>
      _TrainerScheduleEditorPageState();
}

class _TrainerScheduleEditorPageState extends State<TrainerScheduleEditorPage> {
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
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  List<WorkoutPlanAssignment> _assignments = const <WorkoutPlanAssignment>[];
  List<WorkoutScheduleProfile> _profiles = const <WorkoutScheduleProfile>[];
  WorkoutScheduleProfile? _selectedProfile;
  Map<int, String?> _dayToPlanId = <int, String?>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await _repository.fetchAssignmentsForClient(
        widget.client.id,
      );
      final profiles = (await _repository.fetchScheduleProfiles(
        forUserId: widget.client.id,
      )).where((profile) => profile.trainerId != null).toList();

      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _profiles = profiles;
      });

      if (profiles.isNotEmpty) {
        _selectProfile(profiles.first);
      } else {
        _nameController.text = '${widget.client.name} Plan';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load trainer schedules.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectProfile(WorkoutScheduleProfile profile) {
    _nameController.text = profile.name;
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

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final profile = await _repository.createOrUpdateTrainerScheduleProfile(
        clientId: widget.client.id,
        name: _nameController.text,
        assignmentId: null,
        profileId: _selectedProfile?.id,
      );
      await _repository.saveScheduleProfileDays(
        profileId: profile.id,
        dayToPlanId: _dayToPlanId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Trainer schedule saved.')),
        );
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this schedule.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.client.name} Schedule')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Schedule Name',
                          ),
                        ),
                        if (_profiles.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedProfile?.id,
                            decoration: const InputDecoration(
                              labelText: 'Existing trainer schedule',
                            ),
                            items:
                                _profiles
                                    .map(
                                      (profile) => DropdownMenuItem<String>(
                                        value: profile.id,
                                        child: Text(profile.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final profile = _profiles.firstWhere(
                                (element) => element.id == value,
                              );
                              setState(() => _selectProfile(profile));
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._weekdayLabels.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String?>(
                              initialValue: _dayToPlanId[entry.key],
                              decoration: const InputDecoration(
                                labelText: 'Assigned plan',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('No plan assigned'),
                                ),
                                ..._assignments.map((assignment) {
                                  final plan = assignment.clientPlan;
                                  return DropdownMenuItem<String?>(
                                    value: plan?.id,
                                    child: Text(
                                      plan?.name ??
                                          assignment.trainerPlan?.name ??
                                          'Assigned Plan',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _dayToPlanId[entry.key] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_outlined),
          label: const Text('Save Proposed Schedule'),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
