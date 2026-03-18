import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  const AnimatedBackground({super.key, this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Gradient Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(AppTheme.lightBrand, const Color(0xFFF5F7FA), _controller.value)!,
                    Color.lerp(const Color(0xFFBBDEFB), AppTheme.lightBrand, _controller.value)!,
                    Color.lerp(const Color(0xFFF5F7FA), const Color(0xFFE3F2FD), _controller.value)!,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Moving Blobs
        ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                  final random = Random(index);
                  // Create a pseudo-random movement based on controller
                  final dx = sin(_controller.value * 2 * pi + index) * 100 + (index * 50);
                  final dy = cos(_controller.value * 2 * pi + index) * 100 + (index * 50);
                  
                  return Positioned(
                      top: 100.0 + (index * 200) + dy,
                      left: (index % 2 == 0 ? -50 : 200) + dx,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           gradient: RadialGradient(
                             colors: [
                               AppTheme.primaryBrand.withOpacity(0.08),
                               AppTheme.primaryBrand.withOpacity(0.0),
                             ],
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: AppTheme.primaryBrand.withOpacity(0.05),
                               blurRadius: 50,
                               spreadRadius: 20,
                             )
                           ]
                        ),
                      ),
                  );
              },
            );
        }),
        
        // Content with Glass Effect
        if (widget.child != null)
          Positioned.fill(
             child: widget.child!,
          ),
      ],
    );
  }
}
