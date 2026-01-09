/// Workout editor screen - create/edit workouts
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echelon_connect/core/models/workout.dart';
import 'package:echelon_connect/core/services/workout_storage.dart';
import 'package:echelon_connect/core/bluetooth/echelon_protocol.dart';
import 'package:echelon_connect/theme/app_theme.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final Workout? workout;

  const WorkoutEditorScreen({super.key, this.workout});

  @override
  ConsumerState<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late TextEditingController _nameController;
  late List<WorkoutStep> _steps;
  bool get _isEditing => widget.workout != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout?.name ?? '');
    _steps = List.from(widget.workout?.steps ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          _isEditing ? 'EDIT WORKOUT' : 'NEW WORKOUT',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 2),
        ),
        actions: [
          TextButton(
            onPressed: _canSave ? _saveWorkout : null,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: _canSave ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout name input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: AppTypography.titleMedium,
              decoration: InputDecoration(
                hintText: 'Workout Name',
                hintStyle: AppTypography.titleMedium.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Steps header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('STEPS', style: AppTypography.labelLarge),
                if (_steps.isNotEmpty)
                  Text(
                    'Total: ${_formatTotalDuration()}',
                    style: AppTypography.bodyMedium,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Steps list
          Expanded(
            child: _steps.isEmpty
                ? _buildEmptySteps()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _steps.length,
                    onReorder: _reorderStep,
                    itemBuilder: (context, index) {
                      return _buildStepCard(index, key: ValueKey(_steps[index].hashCode));
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStep,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add),
      ),
    );
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && _steps.isNotEmpty;

  String _formatTotalDuration() {
    final total = _steps.fold(0, (sum, step) => sum + step.durationSeconds);
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildEmptySteps() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Add your first step', style: AppTypography.bodyLarge),
          const SizedBox(height: 8),
          Text('Tap the + button below', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, {Key? key}) {
    final step = _steps[index];
    return Card(
      key: key,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: AppTypography.titleMedium.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
        title: Text(
          step.name ?? 'Step ${index + 1}',
          style: AppTypography.bodyLarge,
        ),
        subtitle: Text(
          'R${step.resistance} • ${step.formattedDuration}',
          style: AppTypography.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editStep(index),
              color: AppColors.textMuted,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteStep(index),
              color: AppColors.error,
            ),
            const Icon(Icons.drag_handle, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _addStep() {
    _showStepEditor(null, (step) {
      setState(() {
        _steps.add(step);
      });
    });
  }

  void _editStep(int index) {
    _showStepEditor(_steps[index], (step) {
      setState(() {
        _steps[index] = step;
      });
    });
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _reorderStep(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  void _showStepEditor(WorkoutStep? existingStep, Function(WorkoutStep) onSave) {
    String? name = existingStep?.name;
    int resistance = existingStep?.resistance ?? 15;
    int minutes = existingStep != null ? existingStep.durationSeconds ~/ 60 : 1;
    int seconds = existingStep != null ? existingStep.durationSeconds % 60 : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existingStep != null ? 'Edit Step' : 'Add Step',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Step name (optional)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Step Name (optional)',
                  hintText: 'e.g., Warmup, Push, Recovery',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) => name = value.isEmpty ? null : value,
                controller: TextEditingController(text: name),
              ),
              const SizedBox(height: 16),

              // Resistance slider
              Text('Resistance: $resistance', style: AppTypography.labelLarge),
              Slider(
                value: resistance.toDouble(),
                min: 1,
                max: EchelonProtocol.maxResistance.toDouble(),
                divisions: EchelonProtocol.maxResistance - 1,
                activeColor: AppColors.secondary,
                onChanged: (value) => setModalState(() => resistance = value.round()),
              ),
              const SizedBox(height: 16),

              // Duration pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Minutes', style: AppTypography.labelMedium),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: minutes > 0
                                    ? () => setModalState(() => minutes--)
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  '$minutes',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.titleLarge,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setModalState(() => minutes++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seconds', style: AppTypography.labelMedium),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: seconds > 0
                                    ? () => setModalState(() => seconds -= 5)
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  '$seconds',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.titleLarge,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: seconds < 55
                                    ? () => setModalState(() => seconds += 5)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: (minutes > 0 || seconds > 0)
                    ? () {
                        final step = WorkoutStep(
                          name: name,
                          resistance: resistance,
                          durationSeconds: minutes * 60 + seconds,
                        );
                        onSave(step);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(existingStep != null ? 'UPDATE STEP' : 'ADD STEP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveWorkout() {
    final workout = _isEditing
        ? widget.workout!.copyWith(
            name: _nameController.text.trim(),
            steps: _steps,
          )
        : Workout.create(
            name: _nameController.text.trim(),
            steps: _steps,
          );

    if (_isEditing) {
      ref.read(workoutStorageProvider.notifier).updateWorkout(workout);
    } else {
      ref.read(workoutStorageProvider.notifier).addWorkout(workout);
    }

    Navigator.pop(context);
  }
}
