import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/platform/app_platform.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_ui.dart';
import 'playback_gradient_background.dart';
import 'playback_dark_theme.dart';
import 'scrolled_under_tab_frame.dart';
import '../providers/app_strings.dart';
import '../providers/player_style.dart';
import 'player_controls_capsule.dart';
import 'player_lyrics_icon.dart';

const _previewCoverAsset = 'assets/icons/4.0x/bstream_icon.png';
const _styleCaptionHorizontalPadding = 10.0;

/// Full settings page with complete, lightweight layout illustrations.
class PlayerStyleGalleryPage extends StatefulWidget {
  const PlayerStyleGalleryPage({
    required this.style,
    required this.strings,
    required this.header,
    required this.onChanged,
    this.bottomContentPadding = 0,
    super.key,
  });

  final PlayerStyle style;
  final AppStrings strings;
  final Widget header;
  final Future<void> Function(PlayerStyle) onChanged;
  final double bottomContentPadding;

  @override
  State<PlayerStyleGalleryPage> createState() => _PlayerStyleGalleryPageState();
}

class _PlayerStyleGalleryPageState extends State<PlayerStyleGalleryPage> {
  late PlayerStyle selected = widget.style;
  bool applying = false;

  Future<void> _select(PlayerStyle style) async {
    if (applying || style == selected) return;
    final previous = selected;
    setState(() {
      selected = style;
      applying = true;
    });
    try {
      await widget.onChanged(style);
    } catch (_) {
      if (mounted) {
        setState(() => selected = previous);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.strings.error)));
      }
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return LayoutBuilder(
      builder: (context, viewport) {
        final maximumPreviewHeight =
            (viewport.maxHeight - widget.bottomContentPadding - 210).clamp(
              180.0,
              400.0,
            );
        return ScrolledUnderTabFrame(
          key: const ValueKey('settings-player-style-gallery'),
          surfaceKey: const ValueKey(
            'settings-detail-header-surface-playerStyles',
          ),
          scrollKey: const ValueKey('settings-detail-scroll-playerStyles'),
          header: widget.header,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  16,
                  12,
                  widget.bottomContentPadding + 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(strings.playerStyleGalleryHint),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 12.0;
                            final textScale = math.max(
                              1.0,
                              MediaQuery.textScalerOf(context).scale(14) / 14,
                            );
                            final minimumCardWidth =
                                (constraints.maxWidth / 4).clamp(140.0, 220.0) *
                                textScale;
                            final columns =
                                ((constraints.maxWidth + spacing) /
                                        (minimumCardWidth + spacing))
                                    .floor()
                                    .clamp(1, PlayerStyle.values.length);
                            final width = math.min(
                              220.0 * textScale,
                              (constraints.maxWidth - spacing * (columns - 1)) /
                                  columns,
                            );
                            final previewHeight = math.min(
                              maximumPreviewHeight,
                              width * 800 / 380,
                            );
                            final titleStyle =
                                Theme.of(context).textTheme.titleSmall ??
                                const TextStyle(fontSize: 14);
                            final titlePainter = TextPainter(
                              textAlign: TextAlign.center,
                              textDirection: Directionality.of(context),
                              textScaler: MediaQuery.textScalerOf(context),
                              locale: Localizations.maybeLocaleOf(context),
                            );
                            var titleHeight = 0.0;
                            try {
                              // Reserve the tallest translated label at this
                              // width so previews and selection marks align.
                              for (final style in PlayerStyle.values) {
                                titlePainter.text = TextSpan(
                                  text: strings.playerStyleLabel(style),
                                  style: titleStyle,
                                );
                                titlePainter.layout(
                                  maxWidth: math.max(
                                    0.0,
                                    width - _styleCaptionHorizontalPadding * 2,
                                  ),
                                );
                                titleHeight = math.max(
                                  titleHeight,
                                  titlePainter.height,
                                );
                              }
                            } finally {
                              titlePainter.dispose();
                            }
                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: 16,
                              children: [
                                for (final style in PlayerStyle.values)
                                  SizedBox(
                                    width: width,
                                    child: _StylePreviewCard(
                                      key: ValueKey(
                                        'settings-player-style-option-${_optionCode(style)}',
                                      ),
                                      style: style,
                                      label: strings.playerStyleLabel(style),
                                      previewLabel: strings.playerStylePreview,
                                      selected: selected == style,
                                      previewHeight: previewHeight,
                                      titleStyle: titleStyle,
                                      titleHeight: titleHeight,
                                      onTap: () => _select(style),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _optionCode(PlayerStyle style) => switch (style) {
  PlayerStyle.bstreamMusic => 'bstream-music',
  PlayerStyle.appleMusic => 'apple-music',
  PlayerStyle.classicVinyl => 'classic-vinyl',
  PlayerStyle.spotifyMusic => 'spotify-music',
};

class _StylePreviewCard extends StatelessWidget {
  const _StylePreviewCard({
    required this.style,
    required this.label,
    required this.previewLabel,
    required this.selected,
    required this.previewHeight,
    required this.titleStyle,
    required this.titleHeight,
    required this.onTap,
    super.key,
  });
  final PlayerStyle style;
  final String label;
  final String previewLabel;
  final bool selected;
  final double previewHeight;
  final TextStyle titleStyle;
  final double titleHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final caption = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _styleCaptionHorizontalPadding,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: titleHeight),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            previewLabel,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? colors.primary : colors.outline,
            size: 22,
          ),
        ],
      ),
    );
    final preview = ExcludeSemantics(
      child: IgnorePointer(
        child: MediaQuery.withNoTextScaling(
          child: PlayerStylePreview(style: style),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: previewHeight,
                child: Center(child: preview),
              ),
              caption,
            ],
          ),
        ),
      ),
    );
  }
}

/// Portrait illustrations keep each layout's artwork, spacing and controls at
/// the same relative scale as the full player, without starting playback.
class PlayerStylePreview extends StatelessWidget {
  const PlayerStylePreview({required this.style, super.key});
  final PlayerStyle style;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isMobileTargetPlatform(Theme.of(context).platform)) {
      return Theme(
        data: alwaysDarkPlaybackTheme(Theme.of(context)),
        child: Builder(builder: _buildPreview),
      );
    }
    return _buildPreview(context);
  }

  Widget _buildPreview(BuildContext context) {
    final foreground = AppColors.playbackControlForegroundFor(context);
    final apple = style == PlayerStyle.appleMusic;
    final spotify = style == PlayerStyle.spotifyMusic;
    final vinyl = style == PlayerStyle.classicVinyl;
    final utilities = _PreviewUtilityRow(apple: apple);
    return AspectRatio(
      key: ValueKey('player-style-preview-${style.code}'),
      aspectRatio: 380 / 800,
      child: RepaintBoundary(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Image.asset(
                  _previewCoverAsset,
                  fit: BoxFit.cover,
                  cacheWidth: 256,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: playerPlaybackOverlayGradient(context),
                ),
              ),
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 380,
                  height: 800,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: IconTheme(
                      data: IconThemeData(color: foreground, size: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: foreground.withValues(alpha: .4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 332,
                            child: vinyl
                                ? const _VinylPreview()
                                : _PreviewCover(
                                    radius: spotify ? 6 : appArtworkRadius,
                                  ),
                          ),
                          _PreviewMetadata(style: style),
                          _PreviewProgress(showThumb: spotify),
                          _PreviewTransport(style: style),
                          if (apple) const _PreviewVolume(),
                          if (spotify)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: utilities,
                            )
                          else
                            PlayerControlsCapsule(child: utilities),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewMetadata extends StatelessWidget {
  const _PreviewMetadata({required this.style});
  final PlayerStyle style;

  @override
  Widget build(BuildContext context) {
    final circular =
        style == PlayerStyle.appleMusic || style == PlayerStyle.classicVinyl;
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BStream Music',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Theme.of(
                      context,
                    ).textTheme.titleLarge?.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.playbackTitleFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BStream Music',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: Theme.of(
                      context,
                    ).textTheme.titleMedium?.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.contentSubtitleFor(context),
                  ),
                ),
              ],
            ),
          ),
          _PreviewAction(
            icon: Icons.favorite_border_rounded,
            circular: circular,
          ),
          const SizedBox(width: 8),
          _PreviewAction(
            icon: circular ? Icons.more_horiz_rounded : Icons.more_vert_rounded,
            circular: circular,
          ),
        ],
      ),
    );
  }
}

class _PreviewAction extends StatelessWidget {
  const _PreviewAction({required this.icon, required this.circular});
  final IconData icon;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final action = SizedBox.square(
      dimension: 40,
      child: Icon(icon, size: circular ? 22 : 28),
    );
    return circular ? PlayerActionSurface(child: action) : action;
  }
}

class _PreviewTransport extends StatelessWidget {
  const _PreviewTransport({required this.style});
  final PlayerStyle style;

  @override
  Widget build(BuildContext context) {
    final apple = style == PlayerStyle.appleMusic;
    final spotify = style == PlayerStyle.spotifyMusic;
    final foreground = AppColors.playbackControlForegroundFor(context);
    return SizedBox(
      height: spotify ? 72 : 92,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!apple) const Icon(Icons.shuffle_rounded, size: 26),
          Icon(
            apple ? Icons.fast_rewind_rounded : Icons.skip_previous_rounded,
            size: apple ? 48 : 42,
          ),
          if (spotify)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.surface,
                size: 42,
              ),
            )
          else
            const Icon(Icons.play_arrow_rounded, size: 82),
          Icon(
            apple ? Icons.fast_forward_rounded : Icons.skip_next_rounded,
            size: apple ? 48 : 42,
          ),
          if (!apple) const Icon(Icons.repeat_rounded, size: 26),
        ],
      ),
    );
  }
}

class _PreviewUtilityRow extends StatelessWidget {
  const _PreviewUtilityRow({required this.apple});
  final bool apple;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox.square(
          dimension: 28,
          child: IconTheme.merge(
            data: const IconThemeData(size: 28),
            child: const PlayerLyricsIcon(),
          ),
        ),
        Icon(apple ? Icons.shuffle_rounded : Icons.volume_up_rounded, size: 28),
        Icon(apple ? Icons.repeat_rounded : Icons.speaker_rounded, size: 28),
        const Icon(Icons.format_list_bulleted_rounded, size: 28),
      ],
    ),
  );
}

class _PreviewProgress extends StatelessWidget {
  const _PreviewProgress({this.showThumb = false});
  final bool showThumb;
  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.playbackControlForegroundFor(context);
    final active = showThumb
        ? foreground
        : AppColors.downloadAccentFor(context);
    return SizedBox(
      height: 38,
      child: Column(
        children: [
          SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: .38,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: active,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (showThumb)
                    Positioned(
                      left: constraints.maxWidth * .38 - 3.5,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final text in ['1:24', '3:42'])
                Text(
                  text,
                  style: TextStyle(
                    color: AppColors.contentSubtitleFor(context),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewVolume extends StatelessWidget {
  const _PreviewVolume();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Row(
      children: [
        const Icon(Icons.volume_mute_rounded, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.playbackControlForegroundFor(
                context,
              ).withValues(alpha: .25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.volume_up_rounded, size: 24),
      ],
    ),
  );
}

class _PreviewCover extends StatelessWidget {
  const _PreviewCover({this.radius = appArtworkRadius});
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(_previewCoverAsset, fit: BoxFit.cover, cacheWidth: 512),
  );
}

class _VinylPreview extends StatelessWidget {
  const _VinylPreview();
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 0,
        top: 9,
        width: 306,
        height: 306,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFF101010),
                Color(0xFF424242),
                Color(0xFF171717),
                Color(0xFF333333),
                Color(0xFF101010),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final extent in [288.0, 266.0, 244.0, 222.0, 200.0])
                Container(
                  width: extent,
                  height: extent,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .035),
                    ),
                  ),
                ),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: const _PreviewCover(radius: 0),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF999999),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 20,
        right: 14,
        child: Transform.rotate(
          angle: .26,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Container(
                width: 7,
                height: 174,
                decoration: BoxDecoration(
                  color: const Color(0xFFBABABA),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Transform.rotate(
                angle: -.5,
                child: Container(
                  width: 14,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D6D6D),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 12,
        right: 9,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF999999),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ],
  );
}
