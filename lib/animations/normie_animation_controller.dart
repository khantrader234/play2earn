import 'package:flutter/material.dart';
import '../services/sound_manager.dart';

class NormieAnimationController extends StatefulWidget {
  final double mentalStability;
  final double existentialDread;
  final bool isInMeeting;
  final bool isGlitching;
  final SoundManager soundManager;

  const NormieAnimationController({
    Key? key,
    required this.mentalStability,
    required this.existentialDread,
    required this.isInMeeting,
    required this.isGlitching,
    required this.soundManager,
  }) : super(key: key);

  @override
  State<NormieAnimationController> createState() =>
      _NormieAnimationControllerState();
}

class _NormieAnimationControllerState extends State<NormieAnimationController>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<Offset> _position;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _glitch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _updateAnimations();
  }

  @override
  void didUpdateWidget(NormieAnimationController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mentalStability != widget.mentalStability ||
        oldWidget.existentialDread != widget.existentialDread ||
        oldWidget.isInMeeting != widget.isInMeeting ||
        oldWidget.isGlitching != widget.isGlitching) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    // Update breathing sound based on mental state
    if (widget.mentalStability > 0.7) {
      widget.soundManager.playBreathingNormal();
    } else if (widget.mentalStability > 0.3) {
      widget.soundManager.playBreathingStressed();
    } else {
      widget.soundManager.playBreathingBreakdown();
    }

    // Update animations based on state
    _rotation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _position = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glitch = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..rotateZ(_rotation.value)
            ..translate(_position.value.dx, _position.value.dy)
            ..scale(_scale.value),
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/normie.png',
        width: 200,
        height: 200,
      ),
    );
  }
}
