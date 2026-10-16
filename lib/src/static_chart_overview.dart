import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'chart_overview_data.dart';

/// A horizontally paged, flat timeline. Only visible panels are painted;
/// the complete song never becomes one giant backing texture.
class ChartOverviewView extends StatefulWidget {
  const ChartOverviewView({
    super.key,
    required this.data,
    required this.atlas,
    this.chartZoom = 1,
    this.verticalScale = 1,
    this.noteScale = 1,
    this.longAlpha = .8,
    this.onSeek,
  });
  final ChartOverviewData data;
  final ui.Image atlas;
  final double chartZoom, verticalScale, noteScale, longAlpha;
  final ValueChanged<int>? onSeek;
  @override
  State<ChartOverviewView> createState() => _ChartOverviewViewState();
}

class _ChartOverviewViewState extends State<ChartOverviewView> {
  final _scroll = ScrollController();
  late _AtlasGlyphs _glyphs;
  @override
  void initState() {
    super.initState();
    _glyphs = _AtlasGlyphs(widget.data, widget.atlas);
  }

  @override
  void didUpdateWidget(ChartOverviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.atlas != widget.atlas) {
      _glyphs.dispose();
      _glyphs = _AtlasGlyphs(widget.data, widget.atlas);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _glyphs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxHeight.isFinite
          ? math.max(1.0, constraints.maxHeight)
          : 540.0;
      final laneWidth = 10.0 * math.max(.01, widget.chartZoom).toDouble();
      final panelWidth = 13.0 * laneWidth;
      final pixelsPerSecond =
          150.0 *
          math.max(.01, widget.verticalScale).toDouble() *
          math.max(.01, widget.chartZoom).toDouble();
      final panelMs = height / pixelsPerSecond * 1000;
      final panels = math.max(1, (widget.data.durationMs / panelMs).ceil());
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            ui.PointerDeviceKind.touch,
            ui.PointerDeviceKind.mouse,
            ui.PointerDeviceKind.stylus,
            ui.PointerDeviceKind.invertedStylus,
            ui.PointerDeviceKind.trackpad,
          },
        ),
        child: ColoredBox(
          color: Colors.black,
          child: Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              itemExtent: panelWidth,
              itemCount: panels,
              itemBuilder: (context, panel) => RepaintBoundary(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: widget.onSeek == null
                      ? null
                      : (details) {
                          final time =
                              panel * panelMs +
                              (height - details.localPosition.dy) /
                                  pixelsPerSecond *
                                  1000;
                          widget.onSeek!(
                            time.clamp(0, widget.data.durationMs).round(),
                          );
                        },
                  child: CustomPaint(
                    size: Size(panelWidth, height),
                    painter: _PanelPainter(
                      data: widget.data,
                      glyphs: _glyphs,
                      panel: panel,
                      panelMs: panelMs,
                      laneWidth: laneWidth,
                      pixelsPerSecond: pixelsPerSecond,
                      noteScale: widget.noteScale,
                      longAlpha: widget.longAlpha,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PreparedPart {
  const _PreparedPart(this.vertices, this.alpha);
  final ui.Vertices vertices;
  final double alpha;
}

class _AtlasGlyphs {
  _AtlasGlyphs(ChartOverviewData data, ui.Image image) {
    shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    );
    for (final entry in data.glyphs.entries) {
      parts[entry.key] = [
        for (final part in entry.value)
          _PreparedPart(
            ui.Vertices(
              VertexMode.triangles,
              [
                for (var i = 0; i < part.shape.positions.length; i += 3)
                  Offset(part.shape.positions[i], part.shape.positions[i + 1]),
              ],
              textureCoordinates: [
                for (var i = 0; i < part.shape.uv.length; i += 2)
                  Offset(
                    part.shape.uv[i] * image.width,
                    part.shape.uv[i + 1] * image.height,
                  ),
              ],
              indices: part.shape.indices.toList(),
            ),
            part.alpha,
          ),
      ];
    }
  }
  late final ui.ImageShader shader;
  final parts = <String, List<_PreparedPart>>{};
  void dispose() {
    for (final list in parts.values) {
      for (final part in list) {
        part.vertices.dispose();
      }
    }
    shader.dispose();
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({
    required this.data,
    required this.glyphs,
    required this.panel,
    required this.panelMs,
    required this.laneWidth,
    required this.pixelsPerSecond,
    required this.noteScale,
    required this.longAlpha,
  });
  final ChartOverviewData data;
  final _AtlasGlyphs glyphs;
  final int panel;
  final double panelMs, laneWidth, pixelsPerSecond, noteScale, longAlpha;
  double get start => panel * panelMs;
  double get end => start + panelMs;
  double y(double time, double height) =>
      height - (time - start) / 1000 * pixelsPerSecond;
  @override
  void paint(Canvas canvas, Size size) {
    final stageWidth = data.visualBands * laneWidth,
        left = (size.width - stageWidth) / 2,
        right = left + stageWidth;
    double x(double fraction) => left + fraction * stageWidth;
    final paint = Paint()..isAntiAlias = true;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Rect.fromLTWH(left, 0, stageWidth, size.height),
      paint..color = const Color(0x66000019),
    );
    paint
      ..color = const Color(0x3380ffff)
      ..strokeWidth = laneWidth / 10;
    for (var band = 1; band < data.visualBands; band++) {
      final xx = left + band * laneWidth;
      canvas.drawLine(Offset(xx, 0), Offset(xx, size.height), paint);
    }
    paint.color = const Color(0x8000ffff);
    for (final xx in [left, right]) {
      canvas.drawLine(Offset(xx, 0), Offset(xx, size.height), paint);
    }
    for (final (i, tempo) in data.tempos.indexed) {
      final begin = math.max(start, tempo.timeMs),
          stop = math.min(
            end,
            i + 1 < data.tempos.length
                ? data.tempos[i + 1].timeMs
                : double.infinity,
          );
      if (tempo.bpm <= 0 || stop <= begin) continue;
      final beatMs = 60000 / tempo.bpm;
      var beat =
          ((tempo.beat + (begin - tempo.timeMs) / beatMs) * 2).ceil() / 2;
      for (var n = 0; n < 2048; n++, beat += .5) {
        final time = tempo.timeMs + (beat - tempo.beat) * beatMs;
        if (time >= stop) break;
        final yy = y(time, size.height), whole = beat == beat.roundToDouble();
        paint.color = whole ? const Color(0x3380ffff) : const Color(0x29ff80ff);
        if (whole) {
          canvas.drawLine(Offset(left, yy), Offset(right, yy), paint);
        } else {
          for (var xx = left; xx < right; xx += 5) {
            canvas.drawLine(
              Offset(xx, yy),
              Offset(math.min(xx + 2.5, right), yy),
              paint,
            );
          }
        }
      }
    }
    void label(
      String text,
      double xx,
      double yy,
      Color color, {
      bool alignRight = false,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: laneWidth,
            color: color,
            fontFamily: 'Arial',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(alignRight ? xx - painter.width : xx, yy - painter.height / 2),
      );
      painter.dispose();
    }

    for (var time = (start / 5000).ceil() * 5000; time < end; time += 5000) {
      label(
        '${time ~/ 60000}:${((time ~/ 1000) % 60).toString().padLeft(2, '0')}',
        left - 5,
        y(time.toDouble(), size.height),
        const Color(0x80ffffff),
        alignRight: true,
      );
    }
    for (final combo in data.combos) {
      if (combo.timeMs >= start && combo.timeMs < end)
        label(
          combo.text,
          right + 5,
          y(combo.timeMs, size.height),
          const Color(0x80ffffff),
        );
    }
    for (final tempo in data.tempos) {
      if (tempo.timeMs >= start && tempo.timeMs < end) {
        final yy = y(tempo.timeMs, size.height);
        label(
          tempo.bpm == tempo.bpm.roundToDouble()
              ? tempo.bpm.toInt().toString()
              : tempo.bpm.toString(),
          right + 5,
          yy,
          const Color(0x80ff00ff),
        );
        canvas.drawLine(
          Offset(left, yy),
          Offset(right, yy),
          paint..color = const Color(0x80ff00ff),
        );
      }
    }
    for (final interval in data.intervals) {
      if (interval.startMs >= end || interval.endMs < start) continue;
      canvas.drawRect(
        Rect.fromLTRB(
          right + 10,
          y(interval.endMs, size.height),
          right + 11,
          y(interval.startMs, size.height),
        ),
        paint
          ..color = const Color(0x80ff0000)
          ..style = PaintingStyle.stroke,
      );
    }
    paint.style = PaintingStyle.fill;
    for (final skill in data.skills) {
      if (skill.timeMs >= start && skill.timeMs < end)
        label(
          skill.text,
          right + 14,
          y(skill.timeMs, size.height),
          const Color(0x99ffff00),
        );
    }
    paint.color = Colors.white;
    for (final pair in data.simultaneous) {
      if (pair.timeMs >= start && pair.timeMs < end) {
        final h = data.simultaneousThickness * stageWidth;
        canvas.drawRect(
          Rect.fromLTRB(
            x(pair.left),
            y(pair.timeMs, size.height) - h / 2,
            x(pair.right),
            y(pair.timeMs, size.height) + h / 2,
          ),
          paint,
        );
      }
    }
    for (final ribbon in data.ribbons) {
      if (ribbon.segments.isEmpty ||
          ribbon.endMs <= start ||
          ribbon.startMs >= end)
        continue;
      final top = y(ribbon.endMs, size.height),
          bottom = y(ribbon.startMs, size.height);
      for (final segment in ribbon.segments) {
        final begin = math.max(start, segment.startMs),
            stop = math.min(end, segment.endMs);
        if (stop <= begin) continue;
        final steps = math.max(2, ((stop - begin) / 50).ceil()),
            lhs = <Offset>[],
            rhs = <Offset>[];
        for (var i = 0; i <= steps; i++) {
          final time = begin + (stop - begin) * i / steps,
              edges = segment.edges(time);
          lhs.add(Offset(x(edges.$1), y(time, size.height)));
          rhs.add(Offset(x(edges.$2), y(time, size.height)));
        }
        final path = Path()..addPolygon([...lhs, ...rhs.reversed], true);
        Color tint(int argb) {
          final color = Color(argb);
          return color.withValues(alpha: color.a * longAlpha.clamp(0.0, 1.0));
        }

        paint
          ..style = PaintingStyle.fill
          ..shader = null
          ..color = Colors.white;
        if (ribbon.colors.length == 1)
          paint.color = tint(ribbon.colors.single.argb);
        else
          paint.shader = ui.Gradient.linear(
            Offset(0, bottom),
            Offset(0, top),
            [for (final c in ribbon.colors) tint(c.argb)],
            [for (final c in ribbon.colors) c.offset],
          );
        canvas.drawPath(path, paint);
        if (ribbon.strokeWidth > 0 && Color(ribbon.strokeArgb).a > 0) {
          canvas.save();
          canvas.clipPath(path);
          canvas.drawPath(
            path,
            Paint()
              ..isAntiAlias = true
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..strokeWidth = ribbon.strokeWidth * laneWidth / 10 * 2
              ..color = tint(ribbon.strokeArgb),
          );
          canvas.restore();
        }
      }
    }
    paint
      ..shader = glyphs.shader
      ..style = PaintingStyle.fill
      ..filterQuality = FilterQuality.high;
    var lo = 0, hi = data.notes.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (data.notes[mid].timeMs < start)
        lo = mid + 1;
      else
        hi = mid;
    }
    for (var i = lo; i < data.notes.length && data.notes[i].timeMs < end; i++) {
      final note = data.notes[i];
      canvas.save();
      canvas.translate(x(note.center), y(note.timeMs, size.height));
      canvas.scale(stageWidth * noteScale, -stageWidth * noteScale);
      for (final part in glyphs.parts[note.glyph] ?? const <_PreparedPart>[]) {
        paint.color = Colors.white.withValues(
          alpha: part.alpha.clamp(0.0, 1.0),
        );
        canvas.drawVertices(part.vertices, BlendMode.modulate, paint);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PanelPainter old) =>
      old.data != data ||
      old.glyphs != glyphs ||
      old.panel != panel ||
      old.panelMs != panelMs ||
      old.laneWidth != laneWidth ||
      old.noteScale != noteScale ||
      old.longAlpha != longAlpha;
}
