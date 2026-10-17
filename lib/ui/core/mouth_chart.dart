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
    path = original.shift(-rect.topLeft);
  }

  final int fdi;
  late final Rect rect;
  late final Path path;
}

class _ToothBorder extends ShapeBorder {
  const _ToothBorder(this.path, {required this.color});

  final Path path;
  final Color color;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return rect.topLeft == Offset.zero ? path : path.shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = color,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
