library;

import 'package:flutter/material.dart';

class FloatingMonitorButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget Function(double)? childBuilder;

  const FloatingMonitorButton({
    super.key,
    required this.onPressed,
    this.childBuilder,
  });

  @override
  State<FloatingMonitorButton> createState() => _FloatingMonitorButtonState();
}

class _FloatingMonitorButtonState extends State<FloatingMonitorButton> {
  Offset _dragOffset = const Offset(20, 100);
  static const double _buttonSize = 48;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      top: _dragOffset.dy,
      left: _dragOffset.dx,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _dragOffset = Offset(
              _dragOffset.dx + details.delta.dx,
              _dragOffset.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (_) {
          setState(() {
            double newX = _dragOffset.dx.clamp(
              0,
              screenSize.width - _buttonSize,
            );
            double newY = _dragOffset.dy.clamp(
              kToolbarHeight,
              screenSize.height - _buttonSize - 24,
            );
            _dragOffset = Offset(newX, newY);
          });
        },
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: 0.9,
          child: _buildWidget(),
        ),
      ),
    );
  }

  Widget _buildWidget() {
    if (widget.childBuilder == null) {
      return Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: const Icon(Icons.monitor_heart, color: Colors.white),
      );
    }

    return widget.childBuilder!(_buttonSize);
  }
}
