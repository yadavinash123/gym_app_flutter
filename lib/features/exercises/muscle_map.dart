import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exercise.dart';
import 'muscle_map/body_diagram_repository.dart';

/// Normalized fallback touch regions for responsive hit testing when vector diagram is loading.
Map<String, List<Rect>> muscleRegions(bool back) => {
  'Shoulders': [
    const Rect.fromLTWH(.20, .20, .15, .11),
    const Rect.fromLTWH(.65, .20, .15, .11),
  ],
  if (!back) 'Chest': [const Rect.fromLTWH(.34, .21, .32, .14)],
  if (back) 'Back': [const Rect.fromLTWH(.34, .21, .32, .24)],
  if (!back) 'Abdominals': [const Rect.fromLTWH(.38, .35, .24, .18)],
  if (back) 'Glutes': [const Rect.fromLTWH(.34, .46, .32, .12)],
  back ? 'Triceps' : 'Biceps': [
    const Rect.fromLTWH(.18, .31, .14, .15),
    const Rect.fromLTWH(.68, .31, .14, .15),
  ],
  'Forearms': [
    const Rect.fromLTWH(.15, .46, .13, .16),
    const Rect.fromLTWH(.72, .46, .13, .16),
  ],
  back ? 'Hamstrings' : 'Quadriceps': [
    const Rect.fromLTWH(.34, .58, .15, .18),
    const Rect.fromLTWH(.51, .58, .15, .18),
  ],
  'Calves': [
    const Rect.fromLTWH(.35, .76, .13, .16),
    const Rect.fromLTWH(.52, .76, .13, .16),
  ],
};

/// 2D Vector Muscle Map implementing openGym's exact anatomical body geometry.
/// Supports Male and Female character models, Front & Back views,
/// Side-by-Side simultaneous view, and interactive SVG path hit-testing.
class MuscleMap extends StatefulWidget {
  const MuscleMap({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.onSelect,
    this.exerciseCounts,
    this.initialGender = 'male',
    this.allowGenderSwitch = true,
    this.sideBySideDefault = false,
  });

  final List<String> primary;
  final List<String> secondary;
  final ValueChanged<String>? onSelect;
  final Map<String, int>? exerciseCounts;
  final String initialGender;
  final bool allowGenderSwitch;
  final bool sideBySideDefault;

  @override
  State<MuscleMap> createState() => _MuscleMapState();
}

class _MuscleMapState extends State<MuscleMap> {
  late String _gender;
  bool _back = false;
  late bool _sideBySide;
  String? _selectedMuscle;
  Map<String, BodyDiagramData>? _allDiagrams;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender.toLowerCase() == 'female' ? 'female' : 'male';
    _sideBySide = widget.sideBySideDefault;
    if (widget.primary.isNotEmpty) {
      _selectedMuscle = widget.primary.first;
    }
    _loadDiagrams();
  }

  @override
  void didUpdateWidget(MuscleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGender != widget.initialGender) {
      _gender = widget.initialGender.toLowerCase() == 'female' ? 'female' : 'male';
    }
    if (widget.primary.isNotEmpty) {
      _selectedMuscle = widget.primary.first;
    }
  }

  Future<void> _loadDiagrams() async {
    try {
      final diagrams = await BodyDiagramRepository.instance.load();
      if (mounted) {
        setState(() {
          _allDiagrams = diagrams;
        });
      }
    } catch (_) {
      // Graceful fallback to normalized rect diagram
    }
  }

  void _handleTap(Offset localPos, Size size, bool isBack) {
    if (widget.onSelect == null) return;
    HapticFeedback.lightImpact();

    final diagramKey = '${_gender}_${isBack ? 'back' : 'front'}';
    final diagramData = _allDiagrams?[diagramKey];

    // 1. Check precise vector paths if diagram is loaded
    if (diagramData != null) {
      final vb = diagramData.viewBox;
      final scaleX = size.width / vb.$3;
      final scaleY = size.height / vb.$4;

      final diagramX = (localPos.dx / scaleX) + vb.$1;
      final diagramY = (localPos.dy / scaleY) + vb.$2;
      final diagramPoint = Offset(diagramX, diagramY);

      for (final entry in diagramData.muscles.entries) {
        for (final path in entry.value) {
          if (path.contains(diagramPoint)) {
            final standardName = BodyDiagramRepository.normalizeToStandard(
              entry.key,
            );
            setState(() => _selectedMuscle = standardName);
            widget.onSelect!(standardName);
            return;
          }
        }
      }
    }

    // 2. Fallback to normalized touch regions if vector path was missed
    final pNorm = Offset(localPos.dx / size.width, localPos.dy / size.height);
    for (final entry in muscleRegions(isBack).entries) {
      if (entry.value.any((rect) => rect.contains(pNorm))) {
        setState(() => _selectedMuscle = entry.key);
        widget.onSelect!(entry.key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFemale = _gender == 'female';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Controls Row: View Selector & Character Gender Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // View switcher: Front | Back | Both
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Front')),
                  ButtonSegment(value: 1, label: Text('Back')),
                  ButtonSegment(value: 2, label: Text('Both')),
                ],
                selected: {_sideBySide ? 2 : (_back ? 1 : 0)},
                onSelectionChanged: (values) {
                  final v = values.single;
                  setState(() {
                    if (v == 2) {
                      _sideBySide = true;
                    } else {
                      _sideBySide = false;
                      _back = (v == 1);
                    }
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              // Character selector: Male / Female
              if (widget.allowGenderSwitch)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B23),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF283241)),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGenderTab(
                        label: 'Male',
                        icon: Icons.male_rounded,
                        isSelected: !isFemale,
                        color: const Color(0xFF00D4FF),
                        onTap: () => setState(() => _gender = 'male'),
                      ),
                      _buildGenderTab(
                        label: 'Female',
                        icon: Icons.female_rounded,
                        isSelected: isFemale,
                        color: const Color(0xFFFF5288),
                        onTap: () => setState(() => _gender = 'female'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Diagram Canvas
        Semantics(
          label:
              '2D ${_gender} muscle map. ${_sideBySide ? "Front and Back views" : (_back ? "Back view" : "Front view")}. '
              'Primary: ${widget.primary.join(', ')}. Secondary: ${widget.secondary.join(', ')}.',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF12171F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF202A36)),
            ),
            child: _sideBySide
                ? _buildSideBySideViews()
                : _buildSingleView(isBack: _back, height: 320, width: 240),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle hint
        Text(
          'Exact 2D openGym anatomical geometry (${isFemale ? 'Female' : 'Male'})',
          style: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 11),
        ),
        const SizedBox(height: 8),

        // Legend Wrap
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem(color: const Color(0xFFB6FF3B), label: 'Primary'),
            _buildLegendItem(color: const Color(0xFF00D4FF), label: 'Secondary'),
            _buildLegendItem(color: const Color(0xFF1C2430), label: 'Inactive', border: true),
          ],
        ),

        // Muscle selection chips
        if (widget.onSelect != null) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final muscle in muscleGroups)
                _buildMuscleChip(
                  muscle: muscle,
                  isSelected: _selectedMuscle == muscle || widget.primary.contains(muscle),
                  count: widget.exerciseCounts?[muscle],
                  theme: theme,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGenderTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C2430) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : const Color(0xFFA7B0BF)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFFA7B0BF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleView({
    required bool isBack,
    required double width,
    required double height,
  }) {
    final diagramKey = '${_gender}_${isBack ? 'back' : 'front'}';
    final diagramData = _allDiagrams?[diagramKey];

    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onTapUp: widget.onSelect == null
              ? null
              : (event) => _handleTap(event.localPosition, Size(width, height), isBack),
          child: CustomPaint(
            key: const ValueKey('muscle-map-canvas'),
            size: Size(width, height),
            painter: _VectorMusclePainter(
              back: isBack,
              primary: widget.primary,
              secondary: widget.secondary,
              selectedMuscle: _selectedMuscle,
              diagramData: diagramData,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideBySideViews() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 20) / 2;
        final canvasWidth = halfWidth.clamp(130.0, 180.0);
        const canvasHeight = 280.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Front',
                    style: TextStyle(
                      color: Color(0xFFA7B0BF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSingleView(
                    isBack: false,
                    width: canvasWidth,
                    height: canvasHeight,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Back',
                    style: TextStyle(
                      color: Color(0xFFA7B0BF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSingleView(
                    isBack: true,
                    width: canvasWidth,
                    height: canvasHeight,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool border = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: const Color(0xFF283241)) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildMuscleChip({
    required String muscle,
    required bool isSelected,
    int? count,
    required ThemeData theme,
  }) {
    final labelText = count != null ? '$muscle ($count)' : muscle;
    return FilterChip(
      selected: isSelected,
      label: Text(labelText),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.black : const Color(0xFFFFFFFF),
      ),
      selectedColor: const Color(0xFFB6FF3B),
      backgroundColor: const Color(0xFF1C2430),
      checkmarkColor: Colors.black,
      side: BorderSide(
        color: isSelected ? const Color(0xFFB6FF3B) : const Color(0xFF283241),
      ),
      onSelected: (_) {
        setState(() => _selectedMuscle = muscle);
        widget.onSelect!(muscle);
      },
    );
  }
}

class _VectorMusclePainter extends CustomPainter {
  _VectorMusclePainter({
    required this.back,
    required this.primary,
    required this.secondary,
    this.selectedMuscle,
    this.diagramData,
  });

  final bool back;
  final List<String> primary;
  final List<String> secondary;
  final String? selectedMuscle;
  final BodyDiagramData? diagramData;

  @override
  void paint(Canvas canvas, Size size) {
    if (diagramData != null) {
      _paintVectorDiagram(canvas, size, diagramData!);
    } else {
      _paintFallbackDiagram(canvas, size);
    }
  }

  void _paintVectorDiagram(Canvas canvas, Size size, BodyDiagramData data) {
    final vb = data.viewBox;
    final scaleX = size.width / vb.$3;
    final scaleY = size.height / vb.$4;

    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.translate(-vb.$1, -vb.$2);

    // 1. Draw inert silhouette (head, hair, hands, feet, knees, ankles)
    final silhouettePaint = Paint()
      ..color = const Color(0xFF232D3B)
      ..style = PaintingStyle.fill;
    final silhouetteStroke = Paint()
      ..color = const Color(0xFF12171F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    for (final path in data.silhouette) {
      canvas.drawPath(path, silhouettePaint);
      canvas.drawPath(path, silhouetteStroke);
    }

    // 2. Draw muscle regions
    for (final entry in data.muscles.entries) {
      final slug = entry.key;
      final standardName = BodyDiagramRepository.normalizeToStandard(slug);

      final isSelected = selectedMuscle != null &&
          (BodyDiagramRepository.isMuscleMatch(slug, [selectedMuscle!]) ||
              standardName.toLowerCase() == selectedMuscle!.toLowerCase());

      final isPrimary = isSelected ||
          BodyDiagramRepository.isMuscleMatch(slug, primary) ||
          primary.contains(standardName);

      final isSecondary = !isPrimary &&
          (BodyDiagramRepository.isMuscleMatch(slug, secondary) ||
              secondary.contains(standardName));

      Color fillColor = const Color(0xFF1C2430);
      Color strokeColor = const Color(0xFF12171F);
      double strokeWidth = 2.0;

      if (isSelected) {
        fillColor = const Color(0xFFB6FF3B);
        strokeColor = Colors.white;
        strokeWidth = 4.0;
      } else if (isPrimary) {
        fillColor = const Color(0xFFB6FF3B);
        strokeColor = const Color(0xFFB6FF3B);
        strokeWidth = 3.0;
      } else if (isSecondary) {
        fillColor = const Color(0xFF00D4FF);
        strokeColor = const Color(0xFF00D4FF);
        strokeWidth = 2.5;
      }

      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round;

      for (final path in entry.value) {
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
      }
    }

    canvas.restore();
  }

  void _paintFallbackDiagram(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);

    final base = Paint()..color = const Color(0xFF334051);
    canvas.drawOval(const Rect.fromLTWH(.41, .03, .18, .14), base);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(.46, .16, .08, .07),
        const Radius.circular(.02),
      ),
      base,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(.33, .21, .34, .37),
        const Radius.circular(.06),
      ),
      base,
    );

    for (final entry in muscleRegions(back).entries) {
      final isSel = selectedMuscle == entry.key;
      final isPrim = isSel || primary.contains(entry.key);
      final isSec = !isPrim && secondary.contains(entry.key);

      final color = isPrim
          ? const Color(0xFFB6FF3B)
          : isSec
          ? const Color(0xFF00D4FF)
          : const Color(0xFF526175);

      for (final rect in entry.value) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(.025)),
          Paint()..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VectorMusclePainter oldDelegate) =>
      back != oldDelegate.back ||
      primary != oldDelegate.primary ||
      secondary != oldDelegate.secondary ||
      selectedMuscle != oldDelegate.selectedMuscle ||
      diagramData != oldDelegate.diagramData;
}
