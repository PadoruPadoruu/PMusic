import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Extends a cover below its lower edge by reflecting the same decoded image.
///
/// [artworkRect] matches the unreflected foreground cover and must cover the
/// viewport horizontally. The caller owns [image] and the surrounding backdrop
/// supplies its blur; painting the reflection performs no image loading.
class ReflectedArtworkImage extends StatelessWidget {
  const ReflectedArtworkImage({
    required this.image,
    required this.artworkRect,
    this.filterQuality = FilterQuality.medium,
    super.key,
  });

  final ui.Image image;
  final Rect artworkRect;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _ReflectedArtworkPainter(
      image: image,
      artworkRect: artworkRect,
      filterQuality: filterQuality,
    ),
  );
}

/// A retained, small raster with a soft reflection that blurs further below
/// the cover. The two blur passes run only when the image or geometry changes;
/// ordinary paints draw the resulting bitmap once.
class ProgressiveReflectedArtworkImage extends StatefulWidget {
  const ProgressiveReflectedArtworkImage({
    required this.image,
    required this.artworkRect,
    this.filterQuality = FilterQuality.medium,
    super.key,
  });

  final ui.Image image;
  final Rect artworkRect;
  final FilterQuality filterQuality;

  @override
  State<ProgressiveReflectedArtworkImage> createState() =>
      _ProgressiveReflectedArtworkImageState();
}

class _ProgressiveReflectedArtworkImageState
    extends State<ProgressiveReflectedArtworkImage> {
  ui.Image? _raster;
  ui.Image? _source;
  Rect? _artworkRect;
  Size? _viewport;
  FilterQuality? _filterQuality;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = constraints.biggest;
      if (!viewport.isFinite ||
          viewport.isEmpty ||
          !widget.artworkRect.isFinite ||
          widget.artworkRect.isEmpty) {
        return const SizedBox.shrink();
      }
      if (_raster == null ||
          !identical(_source, widget.image) ||
          _artworkRect != widget.artworkRect ||
          _viewport != viewport ||
          _filterQuality != widget.filterQuality) {
        final raster = _rasterizeProgressiveReflection(
          image: widget.image,
          artworkRect: widget.artworkRect,
          viewport: viewport,
          filterQuality: widget.filterQuality,
        );
        final previous = _raster;
        _raster = raster;
        _source = widget.image;
        _artworkRect = widget.artworkRect;
        _viewport = viewport;
        _filterQuality = widget.filterQuality;
        previous?.dispose();
      }
      return RawImage(
        key: const ValueKey('progressive-reflected-artwork-raster'),
        image: _raster,
        fit: BoxFit.fill,
        filterQuality: widget.filterQuality,
      );
    },
  );

  @override
  void dispose() {
    _raster?.dispose();
    super.dispose();
  }
}

ui.Image _rasterizeProgressiveReflection({
  required ui.Image image,
  required Rect artworkRect,
  required Size viewport,
  required FilterQuality filterQuality,
}) {
  final ratio = math.min(
    1.0,
    math.min(240 / viewport.width, 2048 / viewport.height),
  );
  final width = math.max(1, (viewport.width * ratio).round());
  final height = math.max(1, (viewport.height * ratio).round());
  final scaleX = width / viewport.width;
  final scaleY = height / viewport.height;
  final rasterSize = Size(width.toDouble(), height.toDouble());
  final rasterBounds = Offset.zero & rasterSize;
  final rasterRect = Rect.fromLTRB(
    artworkRect.left * scaleX,
    artworkRect.top * scaleY,
    artworkRect.right * scaleX,
    artworkRect.bottom * scaleY,
  );
  final painter = _ReflectedArtworkPainter(
    image: image,
    artworkRect: rasterRect,
    filterQuality: filterQuality,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  void paintBlur(double sigma) {
    canvas.saveLayer(
      rasterBounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma * scaleX,
          sigmaY: sigma * scaleY,
          tileMode: TileMode.clamp,
          bounds: rasterBounds,
        ),
    );
    painter.paint(canvas, rasterSize);
    canvas.restore();
  }

  paintBlur(18);

  final start = (rasterRect.top + rasterRect.height * 0.62).clamp(
    0.0,
    rasterSize.height,
  );
  final end = (rasterRect.bottom + rasterRect.height * 0.42).clamp(
    0.0,
    rasterSize.height,
  );
  if (start < rasterSize.height) {
    canvas.saveLayer(rasterBounds, Paint());
    paintBlur(64);
    if (end > start) {
      const intervals = 16;
      final stops = <double>[];
      final colors = <Color>[];
      for (var index = 0; index <= intervals; index += 1) {
        final t = index / intervals;
        stops.add(t);
        colors.add(Colors.white.withValues(alpha: t * t * (3 - 2 * t)));
      }
      final mask = ui.Gradient.linear(
        Offset(0, start),
        Offset(0, end),
        colors,
        stops,
      );
      canvas.drawRect(
        rasterBounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = mask,
      );
      mask.dispose();
    }
    canvas.restore();
  }

  final picture = recorder.endRecording();
  try {
    // The handle is immediate; the engine rasterizes this small picture on its
    // raster thread. No asynchronous listener or per-frame blur is needed.
    return picture.toImageSync(width, height);
  } finally {
    picture.dispose();
  }
}

class _ReflectedArtworkPainter extends CustomPainter {
  const _ReflectedArtworkPainter({
    required this.image,
    required this.artworkRect,
    required this.filterQuality,
  });

  final ui.Image image;
  final Rect artworkRect;
  final FilterQuality filterQuality;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        artworkRect.isEmpty ||
        !artworkRect.left.isFinite ||
        !artworkRect.top.isFinite ||
        !artworkRect.width.isFinite ||
        !artworkRect.height.isFinite) {
      return;
    }

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, imageSize, artworkRect.size);
    final source = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final destination = Offset.zero & artworkRect.size;
    final tileHeight = artworkRect.height;
    final firstTile = (-artworkRect.top / tileHeight).floor();
    final lastTile = ((size.height - artworkRect.top) / tileHeight).ceil() - 1;
    final paint = Paint()..filterQuality = filterQuality;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var tile = firstTile; tile <= lastTile; tile += 1) {
      final top = artworkRect.top + tile * tileHeight;
      canvas.save();
      canvas.translate(artworkRect.left, tile.isOdd ? top + tileHeight : top);
      if (tile.isOdd) canvas.scale(1, -1);
      canvas.drawImageRect(image, source, destination, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ReflectedArtworkPainter oldDelegate) =>
      !identical(image, oldDelegate.image) ||
      artworkRect != oldDelegate.artworkRect ||
      filterQuality != oldDelegate.filterQuality;
}
