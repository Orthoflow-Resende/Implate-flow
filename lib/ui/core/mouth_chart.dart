import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'odontogram_svg.dart';

import '../../domain/models.dart';

class MouthChart extends StatelessWidget {
  const MouthChart({
    super.key,
    required this.selected,
    required this.onToothTap,
    this.disabledArch,
  });

  final Set<int> selected;
  final ValueChanged<int> onToothTap;
  final Arch? disabledArch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chart = _permanentTeeth;
    return FittedBox(
      child: SizedBox.fromSize(
        size: chart.size,
        child: Stack(
          children: [
            for (final tooth in chart.teeth.values)
              Positioned.fromRect(
                rect: tooth.rect,
                child: Semantics(
                  button: true,
                  selected: selected.contains(tooth.fdi),
                  enabled: !_disabled(tooth.fdi),
                  label: 'Dente ${tooth.fdi}',
                  child: GestureDetector(
                    onTap: _disabled(tooth.fdi) ? null : () => onToothTap(tooth.fdi),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: _fill(scheme, tooth.fdi),
                        shape: _ToothBorder(
                          tooth.silhouette,
                          tooth.path,
                          color: _stroke(scheme, tooth.fdi),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _disabled(int fdi) {
    if (disabledArch == null) return false;
    final upper = upperArch.contains(fdi);
    return (disabledArch == Arch.superior && upper) ||
        (disabledArch == Arch.inferior && !upper);
  }

  Color _fill(ColorScheme scheme, int fdi) {
    if (_disabled(fdi)) return scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    if (selected.contains(fdi)) return scheme.primary.withValues(alpha: 0.28);
    return scheme.surface;
  }

  Color _stroke(ColorScheme scheme, int fdi) {
    if (_disabled(fdi)) return scheme.outline.withValues(alpha: 0.25);
    if (selected.contains(fdi)) return scheme.primary;
    return scheme.onSurface.withValues(alpha: 0.72);
  }
}

final _permanentTeeth = _loadPermanentTeeth();

({Size size, Map<int, _ParsedTooth> teeth}) _loadPermanentTeeth() {
  final doc = XmlDocument.parse(svgString);
  final viewBox = doc.rootElement.getAttribute('viewBox')!.split(' ');
  final teeth = <int, _ParsedTooth>{};
  for (final node in doc.rootElement.findAllElements('path')) {
    final fdi = int.tryParse(node.getAttribute('id') ?? '');
    final d = node.getAttribute('d');
    if (fdi == null || d == null || fdi >= 50) continue;
    teeth[fdi] = _ParsedTooth(fdi, parseSvgPathData(d));
  }
  return (
    size: Size(double.parse(viewBox[2]), double.parse(viewBox[3])),
    teeth: teeth,
  );
}

class _ParsedTooth {
  _ParsedTooth(this.fdi, Path original) {
    rect = original.getBounds();
    final shift = -rect.topLeft;
    path = original.shift(shift);
    silhouette = _outerContour(original).shift(shift);
  }

  final int fdi;
  late final Rect rect;
  late final Path path;
  late final Path silhouette;
}

/// Outer silhouette of a compound tooth path. Groove subpaths punch holes in
/// the fill, so a tap in the middle of the tooth used to miss.
Path _outerContour(Path source) {
  Path? outer;
  var largest = -1.0;
  for (final metric in source.computeMetrics()) {
    final contour = metric.extractPath(0, metric.length);
    if (metric.isClosed) contour.close();
    final area = _sampledArea(metric);
    if (area > largest) {
      largest = area;
      outer = contour;
    }
  }
  return Path.from(outer ?? source)..fillType = PathFillType.nonZero;
}

double _sampledArea(PathMetric metric) {
  if (metric.length == 0) return 0;
  final points = <Offset>[];
  const step = 1.5;
  for (var distance = 0.0; distance < metric.length; distance += step) {
    final tangent = metric.getTangentForOffset(distance);
    if (tangent != null) points.add(tangent.position);
  }
  if (points.length < 3) return 0;
  var sum = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum.abs() / 2;
}

class _ToothBorder extends ShapeBorder {
  const _ToothBorder(this.silhouette, this.detail, {required this.color});

  final Path silhouette;
  final Path detail;
  final Color color;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return rect.topLeft == Offset.zero ? silhouette : silhouette.shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final outline = rect.topLeft == Offset.zero ? detail : detail.shift(rect.topLeft);
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = color,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
