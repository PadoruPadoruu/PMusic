import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_ui.dart';

/// Lightweight placeholders for the initial feed. They have no image requests,
/// animation controllers or actions; the real shelves replace them as a unit.
class HomeLoadingContent extends StatelessWidget {
  const HomeLoadingContent({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final expanded = MediaQuery.sizeOf(context).width >= 700;
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var section = 0; section < 3; section++)
                _LoadingShelf(
                  artists: section == 1,
                  cardWidth: section == 1
                      ? (expanded ? 156 : 132)
                      : (expanded ? 196 : 164),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingShelf extends StatelessWidget {
  const _LoadingShelf({required this.cardWidth, required this.artists});

  final double cardWidth;
  final bool artists;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: appTabFirstSectionTopGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: appTabTitleHorizontalPadding,
            ),
            child: _LoadingBlock(
              width: artists ? 164 : 192,
              height: scaler.scale(20),
            ),
          ),
          const SizedBox(height: appSectionTitleGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final count =
                  (constraints.maxWidth / (cardWidth + 10)).ceil() + 1;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var card = 0; card < count; card++) ...[
                      if (card > 0) const SizedBox(width: 10),
                      SizedBox(
                        width: cardWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: artists
                                ? Colors.transparent
                                : AppColors.homeCardSurfaceFor(context),
                            borderRadius: BorderRadius.circular(appCardRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: artists
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                              children: [
                                _LoadingBlock(
                                  width: cardWidth - 16,
                                  height: cardWidth - 16,
                                  radius: artists ? cardWidth : 8,
                                ),
                                const SizedBox(height: 8),
                                _LoadingBlock(
                                  width: (cardWidth - 16) * 0.78,
                                  height: scaler.scale(14),
                                ),
                                const SizedBox(height: 6),
                                _LoadingBlock(
                                  width: (cardWidth - 16) * 0.52,
                                  height: scaler.scale(10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.width,
    required this.height,
    this.radius = 5,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = Color.alphaBlend(
      colors.onSurface.withValues(alpha: 0.045),
      colors.surfaceContainerHighest,
    );
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              base,
              Color.alphaBlend(colors.onSurface.withValues(alpha: 0.035), base),
              base,
            ],
          ),
        ),
      ),
    );
  }
}
