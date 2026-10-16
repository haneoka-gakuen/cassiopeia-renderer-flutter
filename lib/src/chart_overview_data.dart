import 'package:render_contracts/render_contracts.dart';

/// Backend-neutral sprite geometry: XY offsets are fractions of the stage width,
/// UVs use image coordinates with the origin at the top-left.
final class ChartOverviewSpritePart {
  const ChartOverviewSpritePart(this.shape, {this.alpha = 1});
  final GeometryShape shape;
  final double alpha;
}

final class ChartOverviewNote {
  const ChartOverviewNote({
    required this.timeMs,
    required this.center,
    required this.glyph,
  });
  final double timeMs, center;
  final String glyph;
}

/// A normalized polynomial ease supplied by the format adapter.
final class ChartOverviewCurve {
  const ChartOverviewCurve(
    this.cubic,
    this.quadratic,
    this.linear,
    this.constant,
  );
  static const identity = ChartOverviewCurve(0, 0, 1, 0);
  final double cubic, quadratic, linear, constant;
  double value(double t) =>
      ((cubic * t + quadratic) * t + linear) * t + constant;
}

final class ChartOverviewRibbonSegment {
  const ChartOverviewRibbonSegment({
    required this.startMs,
    required this.endMs,
    required this.leftStart,
    required this.rightStart,
    required this.leftEnd,
    required this.rightEnd,
    this.leftCurve = ChartOverviewCurve.identity,
    this.rightCurve = ChartOverviewCurve.identity,
  });
  final double startMs, endMs, leftStart, rightStart, leftEnd, rightEnd;
  final ChartOverviewCurve leftCurve, rightCurve;
  (double, double) edges(double timeMs) {
    final t = endMs > startMs
        ? ((timeMs - startMs) / (endMs - startMs)).clamp(0.0, 1.0)
        : 1.0;
    return (
      leftStart + (leftEnd - leftStart) * leftCurve.value(t),
      rightStart + (rightEnd - rightStart) * rightCurve.value(t),
    );
  }
}

final class ChartOverviewColorStop {
  const ChartOverviewColorStop(this.offset, this.argb);
  final double offset;
  final int argb;
}

final class ChartOverviewRibbon {
  ChartOverviewRibbon({
    required List<ChartOverviewRibbonSegment> segments,
    required List<ChartOverviewColorStop> colors,
    this.strokeArgb = 0,
    this.strokeWidth = 1,
  }) : segments = List.unmodifiable(segments),
       colors = List.unmodifiable(colors);
  final List<ChartOverviewRibbonSegment> segments;
  final List<ChartOverviewColorStop> colors;
  final int strokeArgb;
  final double strokeWidth;
  double get startMs => segments.first.startMs;
  double get endMs => segments.last.endMs;
}

final class ChartOverviewTempo {
  const ChartOverviewTempo(this.timeMs, this.beat, this.bpm);
  final double timeMs, beat, bpm;
}

final class ChartOverviewLabel {
  const ChartOverviewLabel(this.timeMs, this.text);
  final double timeMs;
  final String text;
}

final class ChartOverviewInterval {
  const ChartOverviewInterval(this.startMs, this.endMs);
  final double startMs, endMs;
}

final class ChartOverviewSimultaneous {
  const ChartOverviewSimultaneous(this.timeMs, this.left, this.right);
  final double timeMs, left, right;
}

final class ChartOverviewData {
  ChartOverviewData({
    required this.durationMs,
    required List<ChartOverviewNote> notes,
    required Map<String, List<ChartOverviewSpritePart>> glyphs,
    required List<ChartOverviewRibbon> ribbons,
    required List<ChartOverviewTempo> tempos,
    required List<ChartOverviewLabel> skills,
    required List<ChartOverviewLabel> combos,
    required List<ChartOverviewInterval> intervals,
    required List<ChartOverviewSimultaneous> simultaneous,
    this.visualBands = 6,
    this.simultaneousThickness = .0026,
    this.judgedCount = 0,
  }) : notes = List.unmodifiable(notes),
       glyphs = Map.unmodifiable({
         for (final entry in glyphs.entries)
           entry.key: List<ChartOverviewSpritePart>.unmodifiable(entry.value),
       }),
       ribbons = List.unmodifiable(ribbons),
       tempos = List.unmodifiable(tempos),
       skills = List.unmodifiable(skills),
       combos = List.unmodifiable(combos),
       intervals = List.unmodifiable(intervals),
       simultaneous = List.unmodifiable(simultaneous);
  final double durationMs, simultaneousThickness;
  final int visualBands, judgedCount;
  final List<ChartOverviewNote> notes;
  final Map<String, List<ChartOverviewSpritePart>> glyphs;
  final List<ChartOverviewRibbon> ribbons;
  final List<ChartOverviewTempo> tempos;
  final List<ChartOverviewLabel> skills, combos;
  final List<ChartOverviewInterval> intervals;
  final List<ChartOverviewSimultaneous> simultaneous;
}
