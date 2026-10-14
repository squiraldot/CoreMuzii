import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Shared glass surface for the app's custom dialogs.
///
/// Keeps dialog content and sizing owned by the existing feature widgets while
/// applying a consistent translucent, blurred surface.
class CommonDialog extends StatelessWidget {
  const CommonDialog({super.key, this.child, this.maxWidth = 500});

  final double maxWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Align(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accent.withValues(alpha: 0.28), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
