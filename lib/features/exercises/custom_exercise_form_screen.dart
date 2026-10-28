import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widgets/toast.dart';
import 'custom_exercise_repository.dart';
import 'exercise.dart';

class CustomExerciseFormScreen extends ConsumerStatefulWidget {
  const CustomExerciseFormScreen({super.key, this.existing});
  final Exercise? existing;

  @override
  ConsumerState<CustomExerciseFormScreen> createState() =>
      _CustomExerciseFormScreenState();
}

class _CustomExerciseFormScreenState
    extends ConsumerState<CustomExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cueController;
  late final TextEditingController _urlController;
  late final TextEditingController _instructionsController;

  late String _bodyPart;
  late String _equipment;
  late String _level;
  late List<String> _primaryMuscles;
  late List<String> _secondaryMuscles;

  String? _pickedMediaPath;
  String? _mediaType; // 'image', 'video', 'gif'
  String? _mediaFileName;
  int? _mediaFileSizeBytes;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  static const List<String> _bodyParts = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Cardio',
    'Full body',
  ];

  static const List<String> _equipmentList = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
    'Bands',
    'Kettlebell',
    'Plate',
    'Other',
  ];

  static const List<String> _levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _descriptionController = TextEditingController(text: ex?.description ?? '');
    _cueController = TextEditingController(text: ex?.cue ?? '');
    _urlController = TextEditingController(text: ex?.videoUrl ?? ex?.url ?? '');
    _instructionsController = TextEditingController(
      text: ex?.instructions.join('\n') ?? '',
    );

    _bodyPart = ex?.bodyPart.isNotEmpty == true
        ? ex!.bodyPart
        : (ex?.group ?? 'Chest');
    if (!_bodyParts.contains(_bodyPart)) {
      _bodyPart = 'Chest';
    }

    _equipment = (ex?.equipment.isNotEmpty ?? false)
        ? ex!.equipment.first
        : 'Dumbbell';
    if (!_equipmentList.contains(_equipment)) {
      _equipment = 'Dumbbell';
    }

    _level = ex?.level ?? 'Intermediate';
    _primaryMuscles = List<String>.from(ex?.primary ?? [_bodyPart]);
    _secondaryMuscles = List<String>.from(ex?.secondary ?? []);

    _pickedMediaPath = ex?.mediaPath;
    _mediaType = ex?.mediaType;
    if (_pickedMediaPath != null && File(_pickedMediaPath!).existsSync()) {
      final f = File(_pickedMediaPath!);
      _mediaFileName = f.path.split(Platform.pathSeparator).last;
      _mediaFileSizeBytes = f.lengthSync();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cueController.dispose();
    _urlController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 88,
      );
      if (file != null) {
        final f = File(file.path);
        final isGif = file.path.toLowerCase().endsWith('.gif');
        setState(() {
          _pickedMediaPath = file.path;
          _mediaType = isGif ? 'gif' : 'image';
          _mediaFileName = file.name;
          _mediaFileSizeBytes = f.existsSync() ? f.lengthSync() : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (file != null) {
        final f = File(file.path);
        setState(() {
          _pickedMediaPath = file.path;
          _mediaType = 'video';
          _mediaFileName = file.name;
          _mediaFileSizeBytes = f.existsSync() ? f.lengthSync() : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick video: $e')),
        );
      }
    }
  }

  void _clearMedia() {
    setState(() {
      _pickedMediaPath = null;
      _mediaType = null;
      _mediaFileName = null;
      _mediaFileSizeBytes = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final customExercises = ref.read(customExercisesProvider).value ?? [];
    final catalog = ref.read(exerciseCatalogProvider).value ?? [];

    // Duplicate check
    final duplicate = [...customExercises, ...catalog].where((e) {
      final sameName = e.name.trim().toLowerCase() == name.toLowerCase();
      final hasExistingId =
          widget.existing != null && widget.existing!.id.isNotEmpty;
      final isSelf = hasExistingId && e.id == widget.existing!.id;
      return sameName && !isSelf;
    }).firstOrNull;

    if (duplicate != null) {
      AppToast.show(
        context,
        title: 'Duplicate Exercise',
        message: '“$name” already exists in your library.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final instructions = _instructionsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final urlText = _urlController.text.trim();

      final exerciseToSave = Exercise(
        id: widget.existing?.id ?? '',
        name: name,
        rawName: name.toLowerCase(),
        group: _bodyPart,
        bodyPart: _bodyPart,
        target: _primaryMuscles.isNotEmpty ? _primaryMuscles.first : _bodyPart,
        primary: _primaryMuscles.isNotEmpty ? _primaryMuscles : [_bodyPart],
        secondary: _secondaryMuscles,
        equipment: [_equipment],
        rawEquipment: _equipment.toLowerCase(),
        level: _level,
        movement: _bodyPart == 'Cardio' ? 'Cardio' : 'Strength',
        category: _bodyPart == 'Cardio' ? 'Cardio' : 'Strength',
        description: _descriptionController.text.trim(),
        instructions: instructions,
        steps: instructions,
        cue: _cueController.text.trim(),
        source: 'Custom',
        url: urlText,
        videoUrl: urlText.isNotEmpty ? urlText : null,
        isCustom: true,
        mediaPath: _pickedMediaPath,
        mediaType: _mediaType,
      );

      final saved = await ref
          .read(customExercisesProvider.notifier)
          .saveExercise(exerciseToSave);

      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.show(
          context,
          message: widget.existing == null
              ? '“$name” created successfully!'
              : '“$name” updated successfully!',
          type: ToastType.success,
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(saved);
        } else if (context.mounted) {
          context.go('/exercises');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.show(
          context,
          title: 'Save Failed',
          message: 'Error saving exercise: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B23),
        title: Text(
          'Delete “${widget.existing!.name}”?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This exercise will be permanently deleted from your custom exercises. Completed workout logs will keep their recorded sets.',
          style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(customExercisesProvider.notifier)
            .deleteExercise(widget.existing!.id);
        if (mounted) {
          setState(() => _isSaving = false);
          AppToast.show(
            context,
            message: '“${widget.existing!.name}” deleted',
            type: ToastType.delete,
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop('deleted');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          AppToast.show(
            context,
            title: 'Delete Failed',
            message: 'Error deleting exercise: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Custom Exercise' : 'Create Exercise'),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Delete exercise',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
              onPressed: _isSaving ? null : _delete,
            ),
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFB6FF3B),
                    ),
                  )
                : const Icon(Icons.check, size: 16),
            label: Text(isEditing ? 'Save' : 'Create'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB6FF3B),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Intro header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF283241)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB6FF3B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFFB6FF3B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Name it, pick a body part and equipment, and attach a photo or video. It integrates seamlessly into your workout routines and plans.',
                      style: TextStyle(
                        color: Color(0xFFA7B0BF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Exercise Name Input
            const Text(
              'Exercise Name *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Bulgarian Split Squat, Decline Pushup',
                prefixIcon: const Icon(Icons.edit_note),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _nameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Body Part Chips
            const Text(
              'Target Body Part *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final bp in _bodyParts)
                  ChoiceChip(
                    label: Text(bp),
                    selected: _bodyPart == bp,
                    selectedColor: const Color(0xFFB6FF3B),
                    labelStyle: TextStyle(
                      color: _bodyPart == bp ? Colors.black : Colors.white,
                      fontWeight: _bodyPart == bp
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: const Color(0xFF151B23),
                    side: BorderSide(
                      color: _bodyPart == bp
                          ? const Color(0xFFB6FF3B)
                          : const Color(0xFF283241),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _bodyPart = bp;
                          if (!_primaryMuscles.contains(bp)) {
                            _primaryMuscles = [bp];
                          }
                        });
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Equipment Chips
            const Text(
              'Equipment *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final eq in _equipmentList)
                  ChoiceChip(
                    label: Text(eq),
                    selected: _equipment == eq,
                    selectedColor: const Color(0xFF00D4FF),
                    labelStyle: TextStyle(
                      color: _equipment == eq ? Colors.black : Colors.white,
                      fontWeight: _equipment == eq
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: const Color(0xFF151B23),
                    side: BorderSide(
                      color: _equipment == eq
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFF283241),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _equipment = eq);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Level Chips
            const Text(
              'Experience Level',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final lvl in _levels)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lvl),
                      selected: _level == lvl,
                      selectedColor: const Color(0xFFB6FF3B),
                      labelStyle: TextStyle(
                        color: _level == lvl ? Colors.black : Colors.white,
                        fontWeight: _level == lvl
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0xFF151B23),
                      side: BorderSide(
                        color: _level == lvl
                            ? const Color(0xFFB6FF3B)
                            : const Color(0xFF283241),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _level = lvl);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary Muscles
            const Text(
              'Primary Muscle Groups',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in muscleGroups)
                  FilterChip(
                    label: Text(m),
                    selected: _primaryMuscles.contains(m),
                    selectedColor: const Color(0xFFB6FF3B),
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(
                      color: _primaryMuscles.contains(m)
                          ? Colors.black
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: _primaryMuscles.contains(m)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: const Color(0xFF151B23),
                    side: BorderSide(
                      color: _primaryMuscles.contains(m)
                          ? const Color(0xFFB6FF3B)
                          : const Color(0xFF283241),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _primaryMuscles.add(m);
                        } else {
                          _primaryMuscles.remove(m);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Media attachment section (Photo / Video / GIF)
            _buildMediaPickerSection(),
            const SizedBox(height: 20),

            // Description / Cues
            const Text(
              'Overview & Description (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Setup, key focus, and overall technique guidelines...',
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Form Cues & Breathing (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cueController,
              decoration: const InputDecoration(
                hintText: 'e.g. Inhale on descent, explode through heel',
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Step-by-step Instructions (One per line)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _instructionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    '1. Stand tall with core engaged\n2. Hinge hips back\n3. Drive forward with power',
              ),
            ),
            const SizedBox(height: 28),


            if (isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B6B),
                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'Delete Exercise',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPickerSection() {
    final hasMedia = _pickedMediaPath != null &&
        File(_pickedMediaPath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF283241)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.perm_media_outlined,
                color: Color(0xFF00D4FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Photo, GIF, or Video',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (hasMedia)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _mediaType?.toUpperCase() ?? 'MEDIA',
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasMedia
                ? '${_mediaFileName ?? "Media attached"} ${_mediaFileSizeBytes != null ? "• ${_formatFileSize(_mediaFileSizeBytes!)}" : ""}'
                : 'Optional. An image, animated GIF, or video demonstration makes it easy to follow in your workouts.',
            style: const TextStyle(
              color: Color(0xFFA7B0BF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          // Preview Area
          if (hasMedia)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF283241)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _mediaType == 'video'
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill,
                                  size: 48,
                                  color: Color(0xFFB6FF3B),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _mediaFileName ?? 'Video file attached',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.file(
                            File(_pickedMediaPath!),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Color(0xFFA7B0BF),
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black87,
                      radius: 16,
                      child: IconButton(
                        iconSize: 16,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _clearMedia,
                        tooltip: 'Remove media',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Media Pick Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2430),
                  side: const BorderSide(color: Color(0xFF283241)),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(hasMedia ? 'Change Photo/GIF' : 'Pick Photo/GIF'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2430),
                  side: const BorderSide(color: Color(0xFF283241)),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Camera'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2430),
                  side: const BorderSide(color: Color(0xFF283241)),
                ),
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam_outlined, size: 16),
                label: Text(hasMedia ? 'Change Video' : 'Pick Video'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // URL link field
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Video or guide link (optional)',
              hintText: 'https://youtube.com/watch?v=... or guide URL',
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ],
      ),
    );
  }
}
