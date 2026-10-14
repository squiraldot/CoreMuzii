import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Glassmorphic replacement for Flutter's standard AlertDialog.
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
    this.shape,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final EdgeInsets insetPadding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            decoration: BoxDecoration(
              color: (backgroundColor ?? const Color(0xE61A1A1A))
                  .withValues(alpha: 0.86),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: DefaultTextStyle(
                      style: theme.textTheme.titleLarge ??
                          const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      child: title!,
                    ),
                  ),
                if (content != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: content!,
                    ),
                  ),
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
