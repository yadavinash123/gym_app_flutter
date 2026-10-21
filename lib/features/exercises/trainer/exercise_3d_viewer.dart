import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'exercise_asset_repository.dart';

class Exercise3DViewer extends ConsumerStatefulWidget {
  const Exercise3DViewer({
    super.key,
    required this.asset,
    this.fullscreen = false,
    this.startTime = 0,
  });
  final Exercise3DAsset asset;
  final bool fullscreen;
  final double startTime;
  @override
  ConsumerState<Exercise3DViewer> createState() => _Exercise3DViewerState();
}

class _Exercise3DViewerState extends ConsumerState<Exercise3DViewer>
    with WidgetsBindingObserver {
  WebViewController? controller;
  Timer? timeout;
  String? error;
  bool ready = false, loadingModel = false, reduced = false;
  bool foreground = true, routeVisible = true;
  int generation = 0;

  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (supported) unawaited(initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    routeVisible = TickerMode.valuesOf(context).enabled;
    if (ready) {
      unawaited(command('setReduced', reduced));
      unawaited(command('setActive', routeVisible && foreground));
    }
  }

  Future<void> initialize() async {
    final ticket = ++generation;
    timeout?.cancel();
    if (mounted) {
      setState(() {
        error = null;
        ready = false;
        loadingModel = false;
      });
    }
    try {
      final view = WebViewController();
      await view.setJavaScriptMode(JavaScriptMode.unrestricted);
      await view.setBackgroundColor(const Color(0xFF101C28));
      await view.addJavaScriptChannel(
        'TrainerBridge',
        onMessageReceived: (message) {
          if (!mounted || ticket != generation) return;
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            switch (data['type']) {
              case 'boot':
                unawaited(loadModel(ticket));
              case 'ready':
                timeout?.cancel();
                setState(() => ready = true);
                unawaited(command('setReduced', reduced));
                unawaited(command('setActive', foreground && routeVisible));
              case 'error':
                showError(
                  'Unable to display this 3D model. You can retry or use the written guide.',
                );
              case 'fullscreen':
                if (!widget.fullscreen) {
                  unawaited(
                    openFullscreen((data['time'] as num?)?.toDouble() ?? 0),
                  );
                }
            }
          } catch (_) {
            showError(
              'The 3D viewer returned an invalid response. Please retry.',
            );
          }
        },
      );
      await view.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              request.url.startsWith('file:') || request.url == 'about:blank'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageFinished: (_) {
            if (ticket == generation && !loadingModel) {
              unawaited(loadModel(ticket));
            }
          },
          onWebResourceError: (e) {
            if (ticket == generation && e.isForMainFrame != false) {
              showError('The offline viewer could not open. Please retry.');
            }
          },
        ),
      );
      if (!mounted || ticket != generation) return;
      setState(() => controller = view);
      timeout = Timer(const Duration(seconds: 35), () {
        if (mounted && !ready && ticket == generation) {
          showError(
            '3D loading took too long. Check that Android System WebView is up to date, then retry.',
          );
        }
      });
      await view.loadFlutterAsset('assets/trainer/index.html');
    } catch (_) {
      if (ticket == generation) {
        showError(
          '3D is unavailable on this device. The written exercise guide remains available.',
        );
      }
    }
  }

  Future<void> loadModel(int ticket) async {
    if (loadingModel || controller == null || ticket != generation) return;
    loadingModel = true;
    try {
      final bytes = await ref
          .read(exerciseAssetRepositoryProvider)
          .load(widget.asset);
      if (!mounted || ticket != generation) return;
      final encoded = base64Encode(bytes);
      final view = controller!;
      await view.runJavaScript('window.fitforgeChunks = [];');
      // Bound each platform-channel message; no HTTP server or remote CDN.
      for (var offset = 0; offset < encoded.length; offset += 96000) {
        if (!mounted || ticket != generation) return;
        final end = (offset + 96000).clamp(0, encoded.length);
        await view.runJavaScript(
          'window.fitforgeChunks.push(${jsonEncode(encoded.substring(offset, end))});',
        );
      }
      final options = widget.asset.options(
        startTime: widget.startTime,
        fullscreen: widget.fullscreen,
      );
      await view.runJavaScript(
        'window.fitforge.load(window.fitforgeChunks.join(""), ${jsonEncode(options)}); window.fitforgeChunks = [];',
      );
    } catch (_) {
      if (ticket == generation) {
        showError('The installed model could not be loaded. Please retry.');
      }
    }
  }

  void showError(String value) {
    timeout?.cancel();
    if (mounted) {
      setState(() {
        error = value;
        ready = false;
      });
    }
  }

  Future<void> command(String name, Object value) async {
    try {
      await controller?.runJavaScript(
        'window.fitforge?.$name(${jsonEncode(value)});',
      );
    } catch (_) {
      /* A disposed platform view cannot receive commands. */
    }
  }

  Future<void> openFullscreen(double time) async {
    await command('setActive', false);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(widget.asset.label)),
          body: SafeArea(
            child: Exercise3DViewer(
              asset: widget.asset,
              fullscreen: true,
              startTime: time,
            ),
          ),
        ),
      ),
    );
    if (mounted) await command('setActive', foreground && routeVisible);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    unawaited(command('setActive', foreground && routeVisible));
  }

  @override
  void dispose() {
    ++generation;
    timeout?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      controller
              ?.runJavaScript('window.fitforge?.dispose();')
              .catchError((Object _) {}) ??
          Future<void>.value(),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supported) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'The 3D trainer is available in the Android and iOS app. The exercise guide below remains available.',
        ),
      );
    }
    final body = Stack(
      children: [
        if (controller != null)
          Positioned.fill(child: WebViewWidget(controller: controller!)),
        if (!ready || error != null)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF101C28),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (error == null) const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        error ?? 'Loading offline 3D trainer…',
                        textAlign: TextAlign.center,
                      ),
                      if (error != null)
                        TextButton(
                          onPressed: () async {
                            try {
                              await controller?.runJavaScript(
                                'window.fitforge?.dispose();',
                              );
                            } catch (_) {}
                            await initialize();
                          },
                          child: const Text('Retry 3D trainer'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return widget.fullscreen
        ? body
        : SizedBox(
            height: 680,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: body,
            ),
          );
  }
}
