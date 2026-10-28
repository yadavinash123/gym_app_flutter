import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'exercise.dart';
import 'muscle_map.dart';

/// Production-ready HD Exercise Video Demonstration Player.
/// Plays genuine looping MP4 video animations directly from openGym
/// with offline asset bundling, streaming fallback, WebP poster preview,
/// and responsive playback controls.
class ExerciseAnimationPlayer extends StatefulWidget {
  const ExerciseAnimationPlayer({
    super.key,
    this.exercise,
    this.animationId,
    this.primary = const [],
    this.secondary = const [],
    this.exerciseName,
    this.preferredFigure,
  });

  final Exercise? exercise;
  final String? animationId;
  final List<String> primary;
  final List<String> secondary;
  final String? exerciseName;
  final String? preferredFigure;

  @override
  State<ExerciseAnimationPlayer> createState() =>
      _ExerciseAnimationPlayerState();
}

class _ExerciseAnimationPlayerState extends State<ExerciseAnimationPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;
  late String _activeFigure; // 'male' or 'female'

  String get _currentExerciseId {
    if (widget.exercise != null) {
      if (_activeFigure == 'female' && widget.exercise!.femaleVariant != null) {
        return widget.exercise!.femaleVariant!;
      }
      if (widget.exercise!.clip != null && widget.exercise!.clip!.isNotEmpty) {
        return widget.exercise!.clip!
            .replaceAll('.mp4', '')
            .replaceAll('.webp', '');
      }
      return widget.exercise!.id;
    }
    final anim = widget.animationId ?? '0662';
    return anim.replaceAll('.mp4', '').replaceAll('.webp', '');
  }

  String get _currentClipName => '$_currentExerciseId.mp4';
  String get _currentStillName => '$_currentExerciseId.webp';

  String get _localAssetClipPath =>
      'assets/exercises/media/clip/$_currentClipName';
  String get _localAssetStillPath =>
      'assets/exercises/media/still/$_currentStillName';

  String get _remoteVideoUrl =>
      'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/$_currentClipName';
  String get _remoteStillUrl =>
      'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/$_currentStillName';

  @override
  void initState() {
    super.initState();
    _activeFigure = widget.preferredFigure?.toLowerCase() == 'female' ? 'female' : 'male';
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ExerciseAnimationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferredFigure != widget.preferredFigure && widget.preferredFigure != null) {
      _activeFigure = widget.preferredFigure!.toLowerCase() == 'female' ? 'female' : 'male';
      _initializePlayer();
    } else if (oldWidget.exercise?.id != widget.exercise?.id ||
        oldWidget.animationId != widget.animationId) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;

    if (!mounted) return;
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _isPlaying = true;
    });

    try {
      final ex = widget.exercise;
      if (ex != null && ex.isCustom) {
        if (ex.mediaType == 'image' || ex.mediaType == 'gif') {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
          }
          return;
        }

        if (ex.mediaType == 'video') {
          if (ex.mediaPath != null && File(ex.mediaPath!).existsSync()) {
            _controller = VideoPlayerController.file(File(ex.mediaPath!));
          } else if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty) {
            _controller = VideoPlayerController.networkUrl(
              Uri.parse(ex.videoUrl!),
            );
          }

          if (_controller != null) {
            await _controller!.initialize();
            await _controller!.setLooping(true);
            await _controller!.setVolume(0.0);
            await _controller!.play();
            if (mounted) setState(() => _isInitialized = true);
            return;
          }
        }

        // Custom exercise without media or with non-video media:
        // do not attempt to load catalogue GitHub video
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
        }
        return;
      }

      // 1. Try local bundled asset first
      bool assetExists = false;
      try {
        await rootBundle.load(_localAssetClipPath);
        assetExists = true;
      } catch (_) {
        assetExists = false;
      }

      if (assetExists) {
        _controller = VideoPlayerController.asset(_localAssetClipPath);
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(_remoteVideoUrl),
        );
      }

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0.0);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF0B0F14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B0F14),
            elevation: 0,
            title: Text(
              widget.exercise?.name ??
                  widget.exerciseName ??
                  'Exercise Demonstration',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              child: _controller != null && _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : _buildPosterWidget(fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterWidget({BoxFit fit = BoxFit.cover}) {
    final ex = widget.exercise;
    if (ex != null && ex.isCustom) {
      if (ex.mediaPath != null && File(ex.mediaPath!).existsSync()) {
        return Image.file(
          File(ex.mediaPath!),
          fit: fit,
          errorBuilder: (_, __, ___) => _buildAnatomicalFallback(),
        );
      }
      if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty) {
        return Image.network(
          ex.videoUrl!,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildAnatomicalFallback(),
        );
      }
      return _buildAnatomicalFallback();
    }
    return Image.asset(
      _localAssetStillPath,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.network(
        _remoteStillUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildAnatomicalFallback(),
      ),
    );
  }

  Widget _buildAnatomicalFallback() {
    return Container(
      color: const Color(0xFF151B23),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MuscleMap(
                primary: widget.exercise?.primary ?? widget.primary,
                secondary: widget.exercise?.secondary ?? widget.secondary,
                initialGender: _activeFigure,
              ),
              const SizedBox(height: 6),
              const Text(
                'Target Anatomy (Front / Back)',
                style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  bool get _isCustomExercise =>
      (widget.exercise?.isCustom ?? false) ||
      (widget.exercise?.id.startsWith('c_') ?? false);

  bool get _isCustomPhotoOrGif =>
      _isCustomExercise &&
      (widget.exercise?.mediaType == 'image' ||
          widget.exercise?.mediaType == 'gif');

  bool get _isCustomVideo =>
      _isCustomExercise && widget.exercise?.mediaType == 'video';

  @override
  Widget build(BuildContext context) {
    final hasFemaleVariant = widget.exercise?.femaleVariant != null;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF283241)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background / Video / Photo display
          if (_isCustomPhotoOrGif)
            GestureDetector(
              onTap: _openFullScreen,
              child: SizedBox.expand(
                child: _buildPosterWidget(fit: BoxFit.contain),
              ),
            )
          else if (_isInitialized && _controller != null)
            GestureDetector(
              onTap: _togglePlayPause,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            )
          else if (_isCustomExercise)
            // Custom exercise without active video playback: show poster or anatomical fallback directly, NEVER a loading spinner
            SizedBox.expand(
              child: _buildPosterWidget(fit: BoxFit.contain),
            )
          else if (!_hasError)
            SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPosterWidget(fit: BoxFit.contain),
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB6FF3B),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildPosterWidget(fit: BoxFit.contain),

          // Header badges / Figure switcher
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F14).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF283241)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (widget.exercise?.isCustom ?? false)
                            ? (widget.exercise?.mediaType == 'image'
                                  ? Icons.image_rounded
                                  : widget.exercise?.mediaType == 'gif'
                                  ? Icons.gif_box_rounded
                                  : Icons.videocam_rounded)
                            : Icons.hd_rounded,
                        size: 14,
                        color: const Color(0xFFB6FF3B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (widget.exercise?.isCustom ?? false)
                            ? (widget.exercise?.mediaType == 'image'
                                  ? 'PHOTO'
                                  : widget.exercise?.mediaType == 'gif'
                                  ? 'ANIMATED GIF'
                                  : 'CUSTOM VIDEO')
                            : 'HD VIDEO',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB6FF3B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFemaleVariant) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F14).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF283241)),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            if (_activeFigure != 'male') {
                              setState(() => _activeFigure = 'male');
                              _initializePlayer();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _activeFigure == 'male'
                                  ? const Color(0xFF1C2430)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.male_rounded,
                              size: 16,
                              color: _activeFigure == 'male'
                                  ? const Color(0xFF00D4FF)
                                  : const Color(0xFFA7B0BF),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (_activeFigure != 'female') {
                              setState(() => _activeFigure = 'female');
                              _initializePlayer();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _activeFigure == 'female'
                                  ? const Color(0xFF1C2430)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.female_rounded,
                              size: 16,
                              color: _activeFigure == 'female'
                                  ? const Color(0xFFFF69B4)
                                  : const Color(0xFFA7B0BF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Controls
          if (_controller != null && _isInitialized)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F14).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF283241)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 20,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFFB6FF3B),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 18,
                      tooltip: 'Fullscreen',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.fullscreen_rounded),
                      onPressed: _openFullScreen,
                    ),
                  ],
                ),
              ),
            )
          else if (_isCustomPhotoOrGif)
            Positioned(
              bottom: 12,
              right: 12,
              child: InkWell(
                onTap: _openFullScreen,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F14).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF283241)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 16,
                        color: Color(0xFFB6FF3B),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tap to Zoom',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
