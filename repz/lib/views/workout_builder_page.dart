import 'package:flutter/material.dart';
import 'package:repz/model/workout.dart';
import 'package:repz/model/workout_catalog.dart';
import 'package:repz/model/workout_plan.dart';
import 'package:repz/repositories/exercise_repository.dart';
import 'package:repz/repositories/workout_plan_repository.dart';
import 'package:repz/views/workout_plan_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutBuilderPage extends StatefulWidget {
  const WorkoutBuilderPage({super.key, this.initialPlan});

  final WorkoutPlan? initialPlan;

  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  final WorkoutPlanRepository _repository = WorkoutPlanRepository();
  final ExerciseRepository _exerciseRepository = ExerciseRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Map<String, bool> _expandedStates = <String, bool>{};

  bool _isSaving = false;
  bool _isLoadingLibrary = true;

  late List<WorkoutPlanExercise> _exercises;
  List<Exercise> _libraryExercises = <Exercise>[];

  bool get _isEditing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();

    final initialPlan = widget.initialPlan;
    _nameController.text =
        initialPlan?.name ?? 'Workout ${DateTime.now().month}/${DateTime.now().day}';
    _notesController.text = initialPlan?.notes ?? '';

    _exercises =
        initialPlan?.exercises
            .map((exercise) => exercise.copyWith(sets: List.of(exercise.sets)))
            .toList() ??
            <WorkoutPlanExercise>[
              WorkoutCatalog.exercises.first.createPlanExercise(sortOrder: 0),
            ];

    for (final exercise in _exercises) {
      _expandedStates[_exerciseUiKey(exercise)] = true;
    }

    _loadExerciseLibrary();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseLibrary() async {
    try {
      final data = await _exerciseRepository.fetchExercises();

      if (!mounted) return;

      setState(() {
        _libraryExercises = data;
        _isLoadingLibrary = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLibrary = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not load exercise library.')),
        );
    }
  }

  String _exerciseUiKey(WorkoutPlanExercise exercise) =>
      exercise.id ?? '${exercise.exerciseKey}_${exercise.sortOrder}';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _normalizeSortOrder() {
    _exercises = List<WorkoutPlanExercise>.generate(
      _exercises.length,
          (index) => _exercises[index].copyWith(sortOrder: index),
    );
  }

  void _updateExercise(int index, WorkoutPlanExercise exercise) {
    setState(() {
      _exercises[index] = exercise;
    });
  }

  void _addCatalogExercise(WorkoutCatalogExercise catalogExercise) {
    setState(() {
      final exercise = catalogExercise.createPlanExercise(
        sortOrder: _exercises.length,
      );
      _exercises = [..._exercises, exercise];
      _expandedStates[_exerciseUiKey(exercise)] = true;
    });
  }

  Future<void> _addDbExercise(Exercise exercise) async {
    final result = await _showAddExerciseDialog(exercise);
    if (result == null) return;

    final int setCount = result.$1;
    final int repsPerSet = result.$2;

    final newExercise = WorkoutPlanExercise(
      sortOrder: _exercises.length,
      exerciseKey: exercise.id,
      displayName: exercise.name,
      workoutType: exercise.type,
      targetJoints: exercise.targetJoints,
      sets: List<WorkoutPlanSet>.generate(
        setCount,
            (index) => WorkoutPlanSet(
          sortOrder: index,
          reps: repsPerSet,
          variation: 'Standard',
        ),
      ),
    );

    setState(() {
      _exercises = [..._exercises, newExercise];
      _expandedStates[_exerciseUiKey(newExercise)] = true;
    });
  }

  Future<(int, int)?> _showAddExerciseDialog(Exercise exercise) async {
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');

    return showDialog<(int, int)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${exercise.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of sets',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps per set',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final sets = int.tryParse(setsController.text.trim());
                final reps = int.tryParse(repsController.text.trim());

                if (sets == null || reps == null || sets <= 0 || reps <= 0) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid set and rep counts.'),
                      ),
                    );
                  return;
                }

                Navigator.of(context).pop((sets, reps));
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      _normalizeSortOrder();
    });
  }

  void _toggleExpanded(WorkoutPlanExercise exercise) {
    final key = _exerciseUiKey(exercise);
    setState(() {
      _expandedStates[key] = !(_expandedStates[key] ?? true);
    });
  }

  void _addSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final variations = _variationsForExercise(exercise);

    _updateExercise(
      exerciseIndex,
      exercise.copyWith(
        sets: [
          ...exercise.sets,
          WorkoutPlanSet(
            sortOrder: exercise.sets.length,
            reps: 12,
            variation: variations.first,
          ),
        ],
      ),
    );
  }

  void _resetDefaultSets(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final catalogExercise = WorkoutCatalog.byKey(exercise.exerciseKey);
    if (catalogExercise == null) {
      _showMessage(
        'Reset Default is only available for built-in catalogue exercises.',
      );
      return;
    }

    _updateExercise(
      exerciseIndex,
      catalogExercise.createPlanExercise(sortOrder: exercise.sortOrder),
    );
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    final updatedSets = List<WorkoutPlanSet>.from(exercise.sets)..removeAt(setIndex);

    _updateExercise(
      exerciseIndex,
      exercise.copyWith(
        sets: List<WorkoutPlanSet>.generate(
          updatedSets.length,
              (index) => updatedSets[index].copyWith(sortOrder: index),
        ),
      ),
    );
  }

  void _updateSet(int exerciseIndex, int setIndex, WorkoutPlanSet set) {
    final exercise = _exercises[exerciseIndex];
    final updatedSets = List<WorkoutPlanSet>.from(exercise.sets);
    updatedSets[setIndex] = set;
    _updateExercise(exerciseIndex, exercise.copyWith(sets: updatedSets));
  }

  IconData _iconForExercise(WorkoutPlanExercise exercise) {
    return WorkoutCatalog.byKey(exercise.exerciseKey)?.icon ??
        Icons.fitness_center;
  }

  List<String> _variationsForExercise(WorkoutPlanExercise exercise) {
    return WorkoutCatalog.byKey(exercise.exerciseKey)?.variations ??
        const <String>['Standard'];
  }

  bool _canResetDefault(WorkoutPlanExercise exercise) {
    return WorkoutCatalog.byKey(exercise.exerciseKey) != null;
  }

  WorkoutPlan _buildPlan(bool isActive) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You need to be signed in to save plans.');
    }

    final now = DateTime.now();

    return WorkoutPlan(
      id: widget.initialPlan?.id,
      userId: user.id,
      name: _nameController.text.trim(),
      notes: _notesController.text.trim(),
      isActive: isActive,
      createdAt: widget.initialPlan?.createdAt ?? now,
      updatedAt: now,
      exercises: List<WorkoutPlanExercise>.generate(
        _exercises.length,
            (exerciseIndex) => _exercises[exerciseIndex].copyWith(
          sortOrder: exerciseIndex,
          sets: List<WorkoutPlanSet>.generate(
            _exercises[exerciseIndex].sets.length,
                (setIndex) => _exercises[exerciseIndex].sets[setIndex].copyWith(
              sortOrder: setIndex,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save({required bool startAfterSave}) async {
    if (_isSaving) return;
    if (_exercises.isEmpty) {
      _showMessage('Add at least one exercise to build a workout plan.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final savedPlan = await _repository.savePlan(
        _buildPlan(startAfterSave),
        setActive: startAfterSave,
      );

      if (!mounted) return;

      if (startAfterSave) {
        final started = await WorkoutPlanHelpers.startPlan(context, savedPlan);
        if (!started) {
          return;
        }
      } else {
        _showMessage(_isEditing ? 'Plan updated.' : 'Plan saved.');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not save your workout plan.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
    isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final primaryCtaColor =
    isDarkMode ? const Color(0xFFA66CFF) : const Color(0xFFCFF500);
    final primaryCtaTextColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final outlineColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.16)
        : accentColor.withValues(alpha: 0.28);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          buildDefaultDragHandles: false,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build Your Workout',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          itemCount: _exercises.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _exercises.removeAt(oldIndex);
              _exercises.insert(newIndex, item);
              _normalizeSortOrder();
            });
          },
          itemBuilder: (context, index) {
            final exercise = _exercises[index];
            final isExpanded = _expandedStates[_exerciseUiKey(exercise)] ?? true;

            return _WorkoutBuilderCard(
              key: ValueKey(_exerciseUiKey(exercise)),
              index: index,
              exercise: exercise,
              icon: _iconForExercise(exercise),
              variations: _variationsForExercise(exercise),
              canResetDefault: _canResetDefault(exercise),
              accentColor: accentColor,
              cardColor: cardColor,
              outlineColor: outlineColor,
              isDarkMode: isDarkMode,
              secondaryTextColor: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
              isExpanded: isExpanded,
              onToggleExpanded: () => _toggleExpanded(exercise),
              onDelete: () => _removeExercise(index),
              onAddSet: () => _addSet(index),
              onResetDefault: () => _resetDefaultSets(index),
              onRemoveSet: (setIndex) => _removeSet(index, setIndex),
              onUpdateSet: (setIndex, set) => _updateSet(index, setIndex, set),
            );
          },
          footer: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryCtaColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving ? null : () => _save(startAfterSave: true),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryCtaTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                        ),
                        child: Text(
                          'Start Workout',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: primaryCtaTextColor,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.24)
                            : Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSaving ? null : () => _save(startAfterSave: true),
                        color: Colors.white,
                        iconSize: 34,
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _save(startAfterSave: false),
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isEditing ? 'Update Plan' : 'Save Plan'),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Exercise Library',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingLibrary)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_libraryExercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No exercises available.'),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _libraryExercises.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final exercise = _libraryExercises[index];
                    return InkWell(
                      onTap: () => _addDbExercise(exercise),
                      borderRadius: BorderRadius.circular(24),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accentColor, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 36,
                                color: isDarkMode ? accentColor : Colors.black,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                exercise.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutBuilderCard extends StatelessWidget {
  const _WorkoutBuilderCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.icon,
    required this.variations,
    required this.canResetDefault,
    required this.accentColor,
    required this.cardColor,
    required this.outlineColor,
    required this.isDarkMode,
    required this.secondaryTextColor,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDelete,
    required this.onAddSet,
    required this.onResetDefault,
    required this.onRemoveSet,
    required this.onUpdateSet,
  });

  final int index;
  final WorkoutPlanExercise exercise;
  final IconData icon;
  final List<String> variations;
  final bool canResetDefault;
  final Color accentColor;
  final Color cardColor;
  final Color outlineColor;
  final bool isDarkMode;
  final Color? secondaryTextColor;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDelete;
  final VoidCallback onAddSet;
  final VoidCallback onResetDefault;
  final ValueChanged<int> onRemoveSet;
  final void Function(int setIndex, WorkoutPlanSet set) onUpdateSet;

  InputDecoration _fieldDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: isDarkMode
          ? Colors.white.withValues(alpha: 0.05)
          : accentColor.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.drag_indicator_rounded),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isDarkMode ? accentColor : Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 18),
              ...List<Widget>.generate(exercise.sets.length, (setIndex) {
                final set = exercise.sets[setIndex];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.025)
                          : accentColor.withValues(alpha: 0.035),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.06)
                            : accentColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set ${setIndex + 1}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: secondaryTextColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final repsField = TextFormField(
                              initialValue:
                              set.reps == 0 ? '' : set.reps.toString(),
                              keyboardType: TextInputType.number,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              decoration: _fieldDecoration(hintText: 'Reps'),
                              onChanged: (value) {
                                onUpdateSet(
                                  setIndex,
                                  set.copyWith(reps: int.tryParse(value) ?? 0),
                                );
                              },
                            );

                            final variationField = DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                              variations.contains(set.variation)
                                  ? set.variation
                                  : variations.first,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              decoration: _fieldDecoration(
                                hintText: 'Variation',
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: secondaryTextColor,
                              ),
                              items: variations
                                  .map(
                                    (variation) => DropdownMenuItem<String>(
                                  value: variation,
                                  child: Text(
                                    variation,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                onUpdateSet(
                                  setIndex,
                                  set.copyWith(variation: value),
                                );
                              },
                            );

                            final deleteButton = IconButton(
                              onPressed: exercise.sets.length == 1
                                  ? null
                                  : () => onRemoveSet(setIndex),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              color: secondaryTextColor,
                              icon: const Icon(Icons.delete_outline),
                            );

                            if (constraints.maxWidth < 250) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: repsField),
                                      const SizedBox(width: 6),
                                      deleteButton,
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  variationField,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 3, child: repsField),
                                const SizedBox(width: 10),
                                Expanded(flex: 5, child: variationField),
                                const SizedBox(width: 4),
                                deleteButton,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (canResetDefault)
                    OutlinedButton(
                      onPressed: onResetDefault,
                      child: const Text('Reset Default'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: onAddSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}