import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Vip3DLogo extends StatefulWidget {
  final double size;
  final bool rotate;

  const Vip3DLogo({super.key, this.size = 80, this.rotate = true});

  @override
  State<Vip3DLogo> createState() => _Vip3DLogoState();
}

class _Vip3DLogoState extends State<Vip3DLogo> with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    if (widget.rotate) _rotateCtrl.repeat();

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(_glow.value * 0.15), blurRadius: 30, spreadRadius: 4)],
        ),
        child: AnimatedBuilder(
          animation: _rotateCtrl,
          builder: (_, child) {
            final angle = _rotateCtrl.value * 2 * 3.14159265;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(angle),
              child: child,
            );
          },
          child: _buildDiamond(),
        ),
      ),
    );
  }

  Widget _buildDiamond() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF333333), Color(0xFF0A0A0A)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 12, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.diamond_outlined, size: widget.size * 0.5, color: AppTheme.primary),
            Padding(
              padding: EdgeInsets.only(top: widget.size * 0.15),
              child: Text('VIP', style: TextStyle(
                fontSize: widget.size * 0.18, fontWeight: FontWeight.w900,
                color: Colors.black, letterSpacing: 1,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
