import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'adhan_banner.dart';

class AdhanOverlayWrapper extends StatefulWidget {
  final Widget? child;

  const AdhanOverlayWrapper({super.key, this.child});

  @override
  State<AdhanOverlayWrapper> createState() => _AdhanOverlayWrapperState();
}

class _AdhanOverlayWrapperState extends State<AdhanOverlayWrapper>
    with WidgetsBindingObserver {
  bool _isVisible = false;
  bool _isDismissed = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling(); // Clear existing
    // Check every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _checkStatus();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkStatus() async {
    bool isPlaying = await NotificationService.isAdhanPlaying();

    if (mounted) {
      setState(() {
        if (!isPlaying) {
          _isVisible = false;
          _isDismissed = false; // Reset dismiss flag when adhan stops
        } else {
          // It is playing
          if (!_isDismissed) {
            _isVisible = true;
          }
        }
      });
    }
  }

  void _onStop() async {
    await NotificationService.stopAdhan();
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  void _onDismiss() {
    if (mounted) {
      setState(() {
        _isVisible = false;
        _isDismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,

        // Banner Overlay with Animated Top Entry/Exit
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedSlide(
              offset: _isVisible ? Offset.zero : const Offset(0, -1.5),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: AdhanBanner(
                  onStop: _onStop,
                  onDismiss: _onDismiss,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
