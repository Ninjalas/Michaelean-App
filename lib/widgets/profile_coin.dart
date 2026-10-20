import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// Profile photo on the front, QR on the back, flipped like a coin around the
/// vertical axis (spec §10.1). Tap or swipe sideways to flip.
class ProfileCoin extends StatefulWidget {
  final String name;
  final String? photoAsset;
  final String qrData; // mock token only — never personal data
  final double size;

  const ProfileCoin({
    super.key,
    required this.name,
    required this.photoAsset,
    required this.qrData,
    this.size = 180,
  });

  @override
  State<ProfileCoin> createState() => _ProfileCoinState();
}

class _ProfileCoinState extends State<ProfileCoin> with SingleTickerProviderStateMixin {
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  bool _showingQr = false;

  void _toggle() {
    if (_flip.isAnimating) return; // ignore taps mid-flip: no accidental double flips
    setState(() => _showingQr = !_showingQr);
    _showingQr ? _flip.forward() : _flip.reverse();
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size;
    return Semantics(
      button: true,
      label: _showingQr ? 'QR code. Tap to show photo' : 'Profile photo. Tap to show QR code',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _toggle,
        onHorizontalDragEnd: (e) {
          if (e.primaryVelocity != null && e.primaryVelocity!.abs() > 200) _toggle();
        },
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final angle = Curves.easeInOutCubic.transform(_flip.value) * pi;
            final backVisible = angle > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // perspective, so it reads as 3D
                ..rotateY(angle),
              child: backVisible
                  // Counter-rotate the back so the QR isn't mirrored.
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(pi),
                      child: _qrFace(d),
                    )
                  : UserAvatar(name: widget.name, imageAsset: widget.photoAsset, size: d),
            );
          },
        ),
      ),
    );
  }

  Widget _qrFace(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline, width: 1.5),
        ),
        alignment: Alignment.center,
        // Largest square that fits inside the circle, so no module is clipped.
        child: QrImageView(
          data: widget.qrData,
          size: d * 0.68,
          padding: EdgeInsets.zero,
          semanticsLabel: 'QR code',
        ),
      );
}
