// coverage:ignore-file
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_painter.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/material.dart';

/// This is the base class for axis base charts data
/// that contains a [FlGridData] that holds data for showing grid lines,
/// also we have [minX], [maxX], [minY], [maxY] values
/// we use them to determine how much is the scale of chart,
/// and calculate x and y according to the scale.
/// each child have to set it in their constructor.
abstract class AxisChartData extends BaseChartData with EquatableMixin {
  final FlGridData gridData;
  final FlTitlesData titlesData;
  final RangeAnnotations rangeAnnotations;

  double minX, maxX, baselineX;
  double minY, maxY, baselineY;

  /// clip the chart to the border (prevent draw outside the border)
  FlClipData clipData;

  /// A background color which is drawn behind th chart.
  Color backgroundColor;

  /// Difference of [maxY] and [minY]
  double get verticalDiff => maxY - minY;

  /// Difference of [maxX] and [minX]
  double get horizontalDiff => maxX - minX;

  AxisChartData({
    FlGridData? gridData,
    required FlTitlesData titlesData,
    RangeAnnotations? rangeAnnotations,
    required double minX,
    required double maxX,
    double? baselineX,
    required double minY,
    required double maxY,
    double? baselineY,
    FlClipData? clipData,
    Color? backgroundColor,
    FlBorderData? borderData,
    required FlTouchData touchData,
  })  : gridData = gridData ?? FlGridData(),
        titlesData = titlesData,
        rangeAnnotations = rangeAnnotations ?? RangeAnnotations(),
        minX = minX,
        maxX = maxX,
        baselineX = baselineX ?? 0,
        minY = minY,
        maxY = maxY,
        baselineY = baselineY ?? 0,
        clipData = clipData ?? FlClipData.none(),
        backgroundColor = backgroundColor ?? Colors.transparent,
        super(borderData: borderData, touchData: touchData);

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        gridData,
        titlesData,
        rangeAnnotations,
        minX,
        maxX,
        baselineX,
        minY,
        maxY,
        baselineY,
        clipData,
        backgroundColor,
        borderData,
        touchData,
      ];
}

/// Represents a side of the chart
enum AxisSide { left, top, right, bottom }

/// Contains meta information about the drawing title.
class TitleMeta {
  /// min axis value
  final double min;

  /// max axis value
  final double max;

  /// The interval that applied to this drawing title
  final double appliedInterval;

  /// Reference of [SideTitles] object.
  final SideTitles sideTitles;

  /// Formatted value that is suitable to show, for example 100, 2k, 5m, ...
  final String formattedValue;

  /// Determines the axis side of titles (left, top, right, bottom)
  final AxisSide axisSide;

  TitleMeta({
    required this.min,
    required this.max,
    required this.appliedInterval,
    required this.sideTitles,
    required this.formattedValue,
    required this.axisSide,
  });
}

/// It gives you the axis value and gets a String value based on it.
typedef GetTitleWidgetFunction = Widget Function(double value, TitleMeta meta);

/// The default [SideTitles.getTitlesWidget] function.
///
/// formats the axis number to a shorter string using [formatNumber].
Widget defaultGetTitle(double value, TitleMeta meta) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      meta.formattedValue,
    ),
  );
}

/// Holds data for showing label values on axis numbers
class SideTitles with EquatableMixin {
  /// Determines showing or hiding this side titles
  final bool showTitles;

  /// You can override it to pass your custom widget to show in each axis value
  /// We recommend you to use [SideTitleWidget].
  final GetTitleWidgetFunction getTitlesWidget;

  /// It determines the maximum space that your titles need,
  /// (All titles will stretch using this value)
  final double reservedSize;

  /// Texts are showing with provided [interval]. If you don't provide anything,
  /// we try to find a suitable value to set as [interval] under the hood.
  final double? interval;

  /// It draws some title on an axis, per axis values,
  /// [showTitles] determines showing or hiding this side,
  ///
  /// Texts are depend on the axis value, you can override [getTitles],
  /// it gives you an axis value (double value) and a [TitleMeta] which contains
  /// additional information about the axis.
  /// Then you should return a [Widget] to show.
  /// It allows you to do anything you want, For example you can show icons
  /// instead of texts, because it accepts a [Widget]
  ///
  /// [reservedSize] determines the maximum space that your titles need,
  /// (All titles will stretch using this value)
  ///
  /// Texts are showing with provided [interval]. If you don't provide anything,
  /// we try to find a suitable value to set as [interval] under the hood.
  SideTitles({
    bool? showTitles,
    GetTitleWidgetFunction? getTitlesWidget,
    double? reservedSize,
    double? interval,
  })  : showTitles = showTitles ?? false,
        getTitlesWidget = getTitlesWidget ?? defaultGetTitle,
        reservedSize = reservedSize ?? 22,
        interval = interval {
    if (interval == 0) {
      throw ArgumentError("SideTitles.interval couldn't be zero");
    }
  }

  /// Lerps a [SideTitles] based on [t] value, check [Tween.lerp].
  static SideTitles lerp(SideTitles a, SideTitles b, double t) {
    return SideTitles(
      showTitles: b.showTitles,
      getTitlesWidget: b.getTitlesWidget,
      reservedSize: lerpDouble(a.reservedSize, b.reservedSize, t),
      interval: lerpDouble(a.interval, b.interval, t),
    );
  }

  /// Copies current [SideTitles] to a new [SideTitles],
  /// and replaces provided values.
  SideTitles copyWith({
    bool? showTitles,
    GetTitleWidgetFunction? getTitlesWidget,
    double? reservedSize,
    double? interval,
  }) {
    return SideTitles(
      showTitles: showTitles ?? this.showTitles,
      getTitlesWidget: getTitlesWidget ?? this.getTitlesWidget,
      reservedSize: reservedSize ?? this.reservedSize,
      interval: interval ?? this.interval,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        showTitles,
        getTitlesWidget,
        reservedSize,
        interval,
      ];
}

/// Holds data for showing each side titles (left, top, right, bottom)
class AxisTitles with EquatableMixin {
  /// Determines the size of [axisName]
  final double axisNameSize;

  /// It shows the name of axis, for example your x-axis shows year,
  /// then you might want to show it using [axisNameWidget] property as a widget
  final Widget? axisNameWidget;

  /// It is responsible to show your axis side labels.
  final SideTitles sideTitles;

  /// If titles are showing on top of your tooltip, you can draw them below everything.
  ///
  /// In the future, we will convert tooltips to a widget, that would solve this problem.
  final bool drawBelowEverything;

  /// If there is something to show as axisTitles, it returns true
  bool get showAxisTitles => axisNameWidget != null && axisNameSize != 0;

  /// If there is something to show as sideTitles, it returns true
  bool get showSideTitles =>
      sideTitles.showTitles && sideTitles.reservedSize != 0;

  /// you can provide [axisName] if you want to show a general
  /// label on this axis,
  ///
  /// [axisNameSize] determines the maximum size that [axisName] can use
  ///
  /// [sideTitles] property is responsible to show your axis side labels
  AxisTitles({
    Widget? axisNameWidget,
    double? axisNameSize,
    SideTitles? sideTitles,
    bool? drawBehindEverything,
  })  : axisNameWidget = axisNameWidget,
        axisNameSize = axisNameSize ?? 16,
        sideTitles = sideTitles ?? SideTitles(),
        drawBelowEverything = drawBehindEverything ?? false;

  /// Lerps a [AxisTitles] based on [t] value, check [Tween.lerp].
  static AxisTitles lerp(AxisTitles a, AxisTitles b, double t) {
    return AxisTitles(
      axisNameWidget: b.axisNameWidget,
      axisNameSize: lerpDouble(a.axisNameSize, b.axisNameSize, t),
      sideTitles: SideTitles.lerp(a.sideTitles, b.sideTitles, t),
      drawBehindEverything: b.drawBelowEverything,
    );
  }

  /// Copies current [SideTitles] to a new [SideTitles],
  /// and replaces provided values.
  AxisTitles copyWith({
    Widget? axisNameWidget,
    double? axisNameSize,
    SideTitles? sideTitles,
    bool? drawBelowEverything,
  }) {
    return AxisTitles(
      axisNameWidget: axisNameWidget ?? this.axisNameWidget,
      axisNameSize: axisNameSize ?? this.axisNameSize,
      sideTitles: sideTitles ?? this.sideTitles,
      drawBehindEverything: drawBelowEverything ?? this.drawBelowEverything,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        axisNameWidget,
        axisNameSize,
        sideTitles,
        drawBelowEverything,
      ];
}

/// Holds data for showing titles on each side of charts.
class FlTitlesData with EquatableMixin {
  final bool show;

  final AxisTitles leftTitles, topTitles, rightTitles, bottomTitles;

  /// [show] determines showing or hiding all titles,
  /// [leftTitles], [topTitles], [rightTitles], [bottomTitles] defines
  /// side titles of left, top, right, bottom sides respectively.
  FlTitlesData({
    bool? show,
    AxisTitles? leftTitles,
    AxisTitles? topTitles,
    AxisTitles? rightTitles,
    AxisTitles? bottomTitles,
  })  : show = show ?? true,
        leftTitles = leftTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 44,
                showTitles: true,
              ),
            ),
        topTitles = topTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 30,
                showTitles: true,
              ),
            ),
        rightTitles = rightTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 44,
                showTitles: true,
              ),
            ),
        bottomTitles = bottomTitles ??
            AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 30,
                showTitles: true,
              ),
            );

  /// Lerps a [FlTitlesData] based on [t] value, check [Tween.lerp].
  static FlTitlesData lerp(FlTitlesData a, FlTitlesData b, double t) {
    return FlTitlesData(
      show: b.show,
      leftTitles: AxisTitles.lerp(a.leftTitles, b.leftTitles, t),
      rightTitles: AxisTitles.lerp(a.rightTitles, b.rightTitles, t),
      bottomTitles: AxisTitles.lerp(a.bottomTitles, b.bottomTitles, t),
      topTitles: AxisTitles.lerp(a.topTitles, b.topTitles, t),
    );
  }

  /// Copies current [FlTitlesData] to a new [FlTitlesData],
  /// and replaces provided values.
  FlTitlesData copyWith({
    bool? show,
    AxisTitles? leftTitles,
    AxisTitles? topTitles,
    AxisTitles? rightTitles,
    AxisTitles? bottomTitles,
  }) {
    return FlTitlesData(
      show: show ?? this.show,
      leftTitles: leftTitles ?? this.leftTitles,
      topTitles: topTitles ?? this.topTitles,
      rightTitles: rightTitles ?? this.rightTitles,
      bottomTitles: bottomTitles ?? this.bottomTitles,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        leftTitles,
        topTitles,
        rightTitles,
        bottomTitles,
      ];
}

/// Represents a conceptual position in cartesian (axis based) space.
class FlSpot with EquatableMixin {
  final double x;
  final double y;

  /// [x] determines cartesian (axis based) horizontally position
  /// 0 means most left point of the chart
  ///
  /// [y] determines cartesian (axis based) vertically position
  /// 0 means most bottom point of the chart
  const FlSpot(double x, double y)
      : x = x,
        y = y;

  /// Copies current [FlSpot] to a new [FlSpot],
  /// and replaces provided values.
  FlSpot copyWith({
    double? x,
    double? y,
  }) {
    return FlSpot(
      x ?? this.x,
      y ?? this.y,
    );
  }

  ///Prints x and y coordinates of FlSpot list
  @override
  String toString() => '($x, $y)';

  /// Used for splitting lines, or maybe other concepts.
  static const FlSpot nullSpot = FlSpot(double.nan, double.nan);

  /// Sets zero for x and y
  static const FlSpot zero = FlSpot(0, 0);

  /// Determines if [x] or [y] is null.
  bool isNull() => this == nullSpot;

  /// Determines if [x] and [y] is not null.
  bool isNotNull() => !isNull();

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        x,
        y,
      ];

  /// Lerps a [FlSpot] based on [t] value, check [Tween.lerp].
  static FlSpot lerp(FlSpot a, FlSpot b, double t) {
    if (a == FlSpot.nullSpot) {
      return b;
    }

    if (b == FlSpot.nullSpot) {
      return a;
    }

    return FlSpot(
      lerpDouble(a.x, b.x, t)!,
      lerpDouble(a.y, b.y, t)!,
    );
  }
}

/// Responsible to hold grid data,
class FlGridData with EquatableMixin {
  /// Determines showing or hiding all horizontal and vertical lines.
  final bool show;

  /// Determines showing or hiding all horizontal lines.
  final bool drawHorizontalLine;

  /// Determines interval between horizontal lines, left it null to be auto calculated.
  final double? horizontalInterval;

  /// Gives you a y value, and gets a [FlLine] that represents specified line.
  final GetDrawingGridLine getDrawingHorizontalLine;

  /// Gives you a y value, and gets a boolean that determines showing or hiding specified line.
  final CheckToShowGrid checkToShowHorizontalLine;

  /// Determines showing or hiding all vertical lines.
  final bool drawVerticalLine;

  /// Determines interval between vertical lines, left it null to be auto calculated.
  final double? verticalInterval;

  /// Gives you a x value, and gets a [FlLine] that represents specified line.
  final GetDrawingGridLine getDrawingVerticalLine;

  /// Gives you a x value, and gets a boolean that determines showing or hiding specified line.
  final CheckToShowGrid checkToShowVerticalLine;

  /// Responsible for rendering grid lines behind the content of charts,
  /// [show] determines showing or hiding all grids,
  ///
  /// [AxisChartPainter] draws horizontal lines from left to right of the chart,
  /// with increasing y value, it increases by [horizontalInterval].
  /// Representation of each line determines by [getDrawingHorizontalLine] callback,
  /// it gives you a double value (in the y axis), and you should return a [FlLine] that represents
  /// a horizontal line.
  /// You are allowed to show or hide any horizontal line, using [checkToShowHorizontalLine] callback,
  /// it gives you a double value (in the y axis), and you should return a boolean that determines
  /// showing or hiding specified line.
  /// or you can hide all horizontal lines by setting [drawHorizontalLine] false.
  ///
  /// [AxisChartPainter] draws vertical lines from bottom to top of the chart,
  /// with increasing x value, it increases by [verticalInterval].
  /// Representation of each line determines by [getDrawingVerticalLine] callback,
  /// it gives you a double value (in the x axis), and you should return a [FlLine] that represents
  /// a horizontal line.
  /// You are allowed to show or hide any vertical line, using [checkToShowVerticalLine] callback,
  /// it gives you a double value (in the x axis), and you should return a boolean that determines
  /// showing or hiding specified line.
  /// or you can hide all vertical lines by setting [drawVerticalLine] false.
  FlGridData({
    bool? show,
    bool? drawHorizontalLine,
    double? horizontalInterval,
    GetDrawingGridLine? getDrawingHorizontalLine,
    CheckToShowGrid? checkToShowHorizontalLine,
    bool? drawVerticalLine,
    double? verticalInterval,
    GetDrawingGridLine? getDrawingVerticalLine,
    CheckToShowGrid? checkToShowVerticalLine,
  })  : show = show ?? true,
        drawHorizontalLine = drawHorizontalLine ?? true,
        horizontalInterval = horizontalInterval,
        getDrawingHorizontalLine = getDrawingHorizontalLine ?? defaultGridLine,
        checkToShowHorizontalLine = checkToShowHorizontalLine ?? showAllGrids,
        drawVerticalLine = drawVerticalLine ?? true,
        verticalInterval = verticalInterval,
        getDrawingVerticalLine = getDrawingVerticalLine ?? defaultGridLine,
        checkToShowVerticalLine = checkToShowVerticalLine ?? showAllGrids {
    if (horizontalInterval == 0) {
      throw ArgumentError("FlGridData.horizontalInterval couldn't be zero");
    }
    if (verticalInterval == 0) {
      throw ArgumentError("FlGridData.verticalInterval couldn't be zero");
    }
  }

  /// Lerps a [FlGridData] based on [t] value, check [Tween.lerp].
  static FlGridData lerp(FlGridData a, FlGridData b, double t) {
    return FlGridData(
      show: b.show,
      drawHorizontalLine: b.drawHorizontalLine,
      horizontalInterval:
          lerpDouble(a.horizontalInterval, b.horizontalInterval, t),
      getDrawingHorizontalLine: b.getDrawingHorizontalLine,
      checkToShowHorizontalLine: b.checkToShowHorizontalLine,
      drawVerticalLine: b.drawVerticalLine,
      verticalInterval: lerpDouble(a.verticalInterval, b.verticalInterval, t),
      getDrawingVerticalLine: b.getDrawingVerticalLine,
      checkToShowVerticalLine: b.checkToShowVerticalLine,
    );
  }

  /// Copies current [FlGridData] to a new [FlGridData],
  /// and replaces provided values.
  FlGridData copyWith({
    bool? show,
    bool? drawHorizontalLine,
    double? horizontalInterval,
    GetDrawingGridLine? getDrawingHorizontalLine,
    CheckToShowGrid? checkToShowHorizontalLine,
    bool? drawVerticalLine,
    double? verticalInterval,
    GetDrawingGridLine? getDrawingVerticalLine,
    CheckToShowGrid? checkToShowVerticalLine,
  }) {
    return FlGridData(
      show: show ?? this.show,
      drawHorizontalLine: drawHorizontalLine ?? this.drawHorizontalLine,
      horizontalInterval: horizontalInterval ?? this.horizontalInterval,
      getDrawingHorizontalLine:
          getDrawingHorizontalLine ?? this.getDrawingHorizontalLine,
      checkToShowHorizontalLine:
          checkToShowHorizontalLine ?? this.checkToShowHorizontalLine,
      drawVerticalLine: drawVerticalLine ?? this.drawVerticalLine,
      verticalInterval: verticalInterval ?? this.verticalInterval,
      getDrawingVerticalLine:
          getDrawingVerticalLine ?? this.getDrawingVerticalLine,
      checkToShowVerticalLine:
          checkToShowVerticalLine ?? this.checkToShowVerticalLine,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        drawHorizontalLine,
        horizontalInterval,
        getDrawingHorizontalLine,
        checkToShowHorizontalLine,
        drawVerticalLine,
        verticalInterval,
        getDrawingVerticalLine,
        checkToShowVerticalLine,
      ];
}

/// Determines showing or hiding specified line.
typedef CheckToShowGrid = bool Function(double value);

/// Shows all lines.
bool showAllGrids(double value) {
  return true;
}

/// Determines the appearance of specified line.
///
/// It gives you an axis [value] (horizontal or vertical),
/// you should pass a [FlLine] that represents style of specified line.
typedef GetDrawingGridLine = FlLine Function(double value);

/// Returns a grey line for all values.
FlLine defaultGridLine(double value) {
  return FlLine(
    color: Colors.blueGrey,
    strokeWidth: 0.4,
    dashArray: [8, 4],
  );
}

/// Defines style of a line.
class FlLine with EquatableMixin {
  /// Defines color of the line.
  final Color color;

  /// Defines thickness of the line.
  final double strokeWidth;

  /// Defines dash effect of the line.
  ///
  /// it is a circular array of dash offsets and lengths.
  /// For example, the array `[5, 10]` would result in dashes 5 pixels long
  /// followed by blank spaces 10 pixels long.
  final List<int>? dashArray;

  /// Renders a line, color it by [color],
  /// thickness is defined by [strokeWidth],
  /// and if you want to have dashed line, you should fill [dashArray],
  /// it is a circular array of dash offsets and lengths.
  /// For example, the array `[5, 10]` would result in dashes 5 pixels long
  /// followed by blank spaces 10 pixels long.
  FlLine({
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
  })  : color = color ?? Colors.black,
        strokeWidth = strokeWidth ?? 2,
        dashArray = dashArray;

  /// Lerps a [FlLine] based on [t] value, check [Tween.lerp].
  static FlLine lerp(FlLine a, FlLine b, double t) {
    return FlLine(
      color: Color.lerp(a.color, b.color, t),
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t),
      dashArray: lerpIntList(a.dashArray, b.dashArray, t),
    );
  }

  /// Copies current [FlLine] to a new [FlLine],
  /// and replaces provided values.
  FlLine copyWith({
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
  }) {
    return FlLine(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dashArray: dashArray ?? this.dashArray,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        color,
        strokeWidth,
        dashArray,
      ];
}

/// holds information about touched spot on the axis based charts.
abstract class TouchedSpot with EquatableMixin {
  /// Represents the spot inside our axis based chart,
  /// 0, 0 is bottom left, and 1, 1 is top right.
  final FlSpot spot;

  /// Represents the touch position in device pixels,
  /// 0, 0 is top, left, and 1, 1 is bottom right.
  final Offset offset;

  /// [spot]  represents the spot inside our axis based chart,
  /// 0, 0 is bottom left, and 1, 1 is top right.
  ///
  /// [offset] is the touch position in device pixels,
  /// 0, 0 is top, left, and 1, 1 is bottom right.
  TouchedSpot(
    FlSpot spot,
    Offset offset,
  )   : spot = spot,
        offset = offset;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        spot,
        offset,
      ];
}

/// Holds data for rendering horizontal and vertical range annotations.
class RangeAnnotations with EquatableMixin {
  final List<HorizontalRangeAnnotation> horizontalRangeAnnotations;
  final List<VerticalRangeAnnotation> verticalRangeAnnotations;

  /// Axis based charts can annotate some horizontal and vertical regions,
  /// using [horizontalRangeAnnotations], and [verticalRangeAnnotations] respectively.
  RangeAnnotations({
    List<HorizontalRangeAnnotation>? horizontalRangeAnnotations,
    List<VerticalRangeAnnotation>? verticalRangeAnnotations,
  })  : horizontalRangeAnnotations = horizontalRangeAnnotations ?? const [],
        verticalRangeAnnotations = verticalRangeAnnotations ?? const [];

  /// Lerps a [RangeAnnotations] based on [t] value, check [Tween.lerp].
  static RangeAnnotations lerp(
      RangeAnnotations a, RangeAnnotations b, double t) {
    return RangeAnnotations(
      horizontalRangeAnnotations: lerpHorizontalRangeAnnotationList(
          a.horizontalRangeAnnotations, b.horizontalRangeAnnotations, t),
      verticalRangeAnnotations: lerpVerticalRangeAnnotationList(
          a.verticalRangeAnnotations, b.verticalRangeAnnotations, t),
    );
  }

  /// Copies current [RangeAnnotations] to a new [RangeAnnotations],
  /// and replaces provided values.
  RangeAnnotations copyWith({
    List<HorizontalRangeAnnotation>? horizontalRangeAnnotations,
    List<VerticalRangeAnnotation>? verticalRangeAnnotations,
  }) {
    return RangeAnnotations(
      horizontalRangeAnnotations:
          horizontalRangeAnnotations ?? this.horizontalRangeAnnotations,
      verticalRangeAnnotations:
          verticalRangeAnnotations ?? this.verticalRangeAnnotations,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        horizontalRangeAnnotations,
        verticalRangeAnnotations,
      ];
}

/// Defines an annotation region in y (vertical) axis.
class HorizontalRangeAnnotation with EquatableMixin {
  /// Determines starting point in vertical (y) axis.
  final double y1;

  /// Determines ending point in vertical (y) axis.
  final double y2;

  /// Fills the area with this color.
  final Color color;

  /// Annotates a horizontal region from most left to most right point of the chart, and
  /// from [y1] to [y2], and fills the area with [color].
  HorizontalRangeAnnotation({
    required double y1,
    required double y2,
    Color? color,
  })  : y1 = y1,
        y2 = y2,
        color = color ?? Colors.white;

  /// Lerps a [HorizontalRangeAnnotation] based on [t] value, check [Tween.lerp].
  static HorizontalRangeAnnotation lerp(
      HorizontalRangeAnnotation a, HorizontalRangeAnnotation b, double t) {
    return HorizontalRangeAnnotation(
      y1: lerpDouble(a.y1, b.y1, t)!,
      y2: lerpDouble(a.y2, b.y2, t)!,
      color: Color.lerp(a.color, b.color, t),
    );
  }

  /// Copies current [HorizontalRangeAnnotation] to a new [HorizontalRangeAnnotation],
  /// and replaces provided values.
  HorizontalRangeAnnotation copyWith({
    double? y1,
    double? y2,
    Color? color,
  }) {
    return HorizontalRangeAnnotation(
      y1: y1 ?? this.y1,
      y2: y2 ?? this.y2,
      color: color ?? this.color,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        y1,
        y2,
        color,
      ];
}

/// Defines an annotation region in x (horizontal) axis.
class VerticalRangeAnnotation with EquatableMixin {
  /// Determines starting point in horizontal (x) axis.
  final double x1;

  /// Determines ending point in horizontal (x) axis.
  final double x2;

  /// Fills the area with this color.
  final Color color;

  /// Annotates a vertical region from most bottom to most top point of the chart, and
  /// from [x1] to [x2], and fills the area with [color].
  VerticalRangeAnnotation({
    required double x1,
    required double x2,
    Color? color,
  })  : x1 = x1,
        x2 = x2,
        color = color ?? Colors.white;

  /// Lerps a [VerticalRangeAnnotation] based on [t] value, check [Tween.lerp].
  static VerticalRangeAnnotation lerp(
      VerticalRangeAnnotation a, VerticalRangeAnnotation b, double t) {
    return VerticalRangeAnnotation(
      x1: lerpDouble(a.x1, b.x1, t)!,
      x2: lerpDouble(a.x2, b.x2, t)!,
      color: Color.lerp(a.color, b.color, t),
    );
  }

  /// Copies current [VerticalRangeAnnotation] to a new [VerticalRangeAnnotation],
  /// and replaces provided values.
  VerticalRangeAnnotation copyWith({
    double? x1,
    double? x2,
    Color? color,
  }) {
    return VerticalRangeAnnotation(
      x1: x1 ?? this.x1,
      x2: x2 ?? this.x2,
      color: color ?? this.color,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        x1,
        x2,
        color,
      ];
}

/// Holds data for drawing each individual line in the [LineChart]
class LineChartBarData with EquatableMixin {
  /// This line goes through this spots.
  ///
  /// You can have multiple lines by splitting them,
  /// put a [FlSpot.nullSpot] between each section.
  final List<FlSpot> spots;

  /// We keep the most left spot to prevent redundant calculations
  late final FlSpot mostLeftSpot;

  /// We keep the most top spot to prevent redundant calculations
  late final FlSpot mostTopSpot;

  /// We keep the most right spot to prevent redundant calculations
  late final FlSpot mostRightSpot;

  /// We keep the most bottom spot to prevent redundant calculations
  late final FlSpot mostBottomSpot;

  /// Determines to show or hide the line.
  final bool show;

  /// If provided, this [LineChartBarData] draws with this [color]
  /// Otherwise we use  [gradient] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Color? color;

  /// If provided, this [LineChartBarData] draws with this [gradient].
  /// Otherwise we use [color] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Gradient? gradient;

  /// Determines thickness of drawing line.
  final double barWidth;

  /// If it's true, [LineChart] draws the line with curved edges,
  /// otherwise it draws line with hard edges.
  final bool isCurved;

  /// If [isCurved] is true, it determines smoothness of the curved edges.
  final double curveSmoothness;

  /// Prevent overshooting when draw curve line with high value changes.
  /// check this [issue](https://github.com/imaNNeoFighT/fl_chart/issues/25)
  final bool preventCurveOverShooting;

  /// Applies threshold for [preventCurveOverShooting] algorithm.
  final double preventCurveOvershootingThreshold;

  /// Determines the style of line's cap.
  final bool isStrokeCapRound;

  /// Determines the style of line joins.
  final bool isStrokeJoinRound;

  /// Fills the space blow the line, using a color or gradient.
  final BarAreaData belowBarData;

  /// Fills the space above the line, using a color or gradient.
  final BarAreaData aboveBarData;

  /// Responsible to showing [spots] on the line as a circular point.
  final FlDotData dotData;

  /// Show indicators based on provided indexes
  final List<int> showingIndicators;

  /// Determines the dash length and space respectively, fill it if you want to have dashed line.
  final List<int>? dashArray;

  /// Drops a shadow behind the bar line.
  final Shadow shadow;

  /// If sets true, it draws the chart in Step Line Chart style, using [LineChartBarData.lineChartStepData].
  final bool isStepLineChart;

  /// Holds data for representing a Step Line Chart, and works only if [isStepChart] is true.
  final LineChartStepData lineChartStepData;

  /// [BarChart] draws some lines and overlaps them in the chart's view,
  /// You can have multiple lines by splitting them,
  /// put a [FlSpot.nullSpot] between each section.
  /// each line passes through [spots], with hard edges by default,
  /// [isCurved] makes it curve for drawing, and [curveSmoothness] determines the curve smoothness.
  ///
  /// [show] determines the drawing, if set to false, it draws nothing.
  ///
  /// [mainColors] determines the color of drawing line, if one color provided it applies a solid color,
  /// otherwise it gradients between provided colors for drawing the line.
  /// Gradient happens using provided [colorStops], [gradientFrom], [gradientTo].
  /// if you want it draw normally, don't touch them,
  /// check [LinearGradient] for understanding [colorStops]
  ///
  /// [barWidth] determines the thickness of drawing line,
  ///
  /// if [isCurved] is true, in some situations if the spots changes are in high values,
  /// an overshooting will happen, we don't have any idea to solve this at the moment,
  /// but you can set [preventCurveOverShooting] true, and update the threshold
  /// using [preventCurveOvershootingThreshold] to achieve an acceptable curve,
  /// check this [issue](https://github.com/imaNNeoFighT/fl_chart/issues/25)
  /// to overshooting understand the problem.
  ///
  /// [isStrokeCapRound] determines the shape of line's cap.
  ///
  /// [isStrokeJoinRound] determines the shape of the line joins.
  ///
  /// [belowBarData], and  [aboveBarData] used to fill the space below or above the drawn line,
  /// you can fill with a solid color or a linear gradient.
  ///
  /// [LineChart] draws points that the line is going through [spots],
  /// you can customize it's appearance using [dotData].
  ///
  /// there are some indicators with a line and bold point on each spot,
  /// you can show them by filling [showingIndicators] with indices
  /// you want to show indicator on them.
  ///
  /// [LineChart] draws the lines with dashed effect if you fill [dashArray].
  ///
  /// If you want to have a Step Line Chart style, just set [isStepLineChart] true,
  /// also you can tweak the [LineChartBarData.lineChartStepData].
  LineChartBarData({
    List<FlSpot>? spots,
    bool? show,
    Color? color,
    Gradient? gradient,
    double? barWidth,
    bool? isCurved,
    double? curveSmoothness,
    bool? preventCurveOverShooting,
    double? preventCurveOvershootingThreshold,
    bool? isStrokeCapRound,
    bool? isStrokeJoinRound,
    BarAreaData? belowBarData,
    BarAreaData? aboveBarData,
    FlDotData? dotData,
    List<int>? showingIndicators,
    List<int>? dashArray,
    Shadow? shadow,
    bool? isStepLineChart,
    LineChartStepData? lineChartStepData,
  })  : spots = spots ?? const [],
        show = show ?? true,
        color =
            color ?? ((color == null && gradient == null) ? Colors.cyan : null),
        gradient = gradient,
        barWidth = barWidth ?? 2.0,
        isCurved = isCurved ?? false,
        curveSmoothness = curveSmoothness ?? 0.35,
        preventCurveOverShooting = preventCurveOverShooting ?? false,
        preventCurveOvershootingThreshold =
            preventCurveOvershootingThreshold ?? 10.0,
        isStrokeCapRound = isStrokeCapRound ?? false,
        isStrokeJoinRound = isStrokeJoinRound ?? false,
        belowBarData = belowBarData ?? BarAreaData(),
        aboveBarData = aboveBarData ?? BarAreaData(),
        dotData = dotData ?? FlDotData(),
        showingIndicators = showingIndicators ?? const [],
        dashArray = dashArray,
        shadow = shadow ?? const Shadow(color: Colors.transparent),
        isStepLineChart = isStepLineChart ?? false,
        lineChartStepData = lineChartStepData ?? LineChartStepData() {
    FlSpot? mostLeft, mostTop, mostRight, mostBottom;

    FlSpot? firstValidSpot;
    try {
      firstValidSpot =
          this.spots.firstWhere((element) => element != FlSpot.nullSpot);
    } catch (e) {
      // There is no valid spot
    }
    if (firstValidSpot != null) {
      for (var spot in this.spots) {
        if (spot.isNull()) {
          continue;
        }
        if (mostLeft == null || spot.x < mostLeft.x) {
          mostLeft = spot;
        }

        if (mostRight == null || spot.x > mostRight.x) {
          mostRight = spot;
        }

        if (mostTop == null || spot.y > mostTop.y) {
          mostTop = spot;
        }

        if (mostBottom == null || spot.y < mostBottom.y) {
          mostBottom = spot;
        }
      }
      mostLeftSpot = mostLeft!;
      mostTopSpot = mostTop!;
      mostRightSpot = mostRight!;
      mostBottomSpot = mostBottom!;
    }
  }

  /// Lerps a [LineChartBarData] based on [t] value, check [Tween.lerp].
  static LineChartBarData lerp(
      LineChartBarData a, LineChartBarData b, double t) {
    return LineChartBarData(
      show: b.show,
      barWidth: lerpDouble(a.barWidth, b.barWidth, t),
      belowBarData: BarAreaData.lerp(a.belowBarData, b.belowBarData, t),
      aboveBarData: BarAreaData.lerp(a.aboveBarData, b.aboveBarData, t),
      curveSmoothness: b.curveSmoothness,
      isCurved: b.isCurved,
      isStrokeCapRound: b.isStrokeCapRound,
      isStrokeJoinRound: b.isStrokeJoinRound,
      preventCurveOverShooting: b.preventCurveOverShooting,
      preventCurveOvershootingThreshold: lerpDouble(
          a.preventCurveOvershootingThreshold,
          b.preventCurveOvershootingThreshold,
          t),
      dotData: FlDotData.lerp(a.dotData, b.dotData, t),
      dashArray: lerpIntList(a.dashArray, b.dashArray, t),
      color: Color.lerp(a.color, b.color, t),
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
      spots: lerpFlSpotList(a.spots, b.spots, t),
      showingIndicators: b.showingIndicators,
      shadow: Shadow.lerp(a.shadow, b.shadow, t),
      isStepLineChart: b.isStepLineChart,
      lineChartStepData:
          LineChartStepData.lerp(a.lineChartStepData, b.lineChartStepData, t),
    );
  }

  /// Copies current [LineChartBarData] to a new [LineChartBarData],
  /// and replaces provided values.
  LineChartBarData copyWith({
    List<FlSpot>? spots,
    bool? show,
    Color? color,
    Gradient? gradient,
    double? barWidth,
    bool? isCurved,
    double? curveSmoothness,
    bool? preventCurveOverShooting,
    double? preventCurveOvershootingThreshold,
    bool? isStrokeCapRound,
    bool? isStrokeJoinRound,
    BarAreaData? belowBarData,
    BarAreaData? aboveBarData,
    FlDotData? dotData,
    List<int>? dashArray,
    List<int>? showingIndicators,
    Shadow? shadow,
    bool? isStepLineChart,
    LineChartStepData? lineChartStepData,
  }) {
    return LineChartBarData(
      spots: spots ?? this.spots,
      show: show ?? this.show,
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      barWidth: barWidth ?? this.barWidth,
      isCurved: isCurved ?? this.isCurved,
      curveSmoothness: curveSmoothness ?? this.curveSmoothness,
      preventCurveOverShooting:
          preventCurveOverShooting ?? this.preventCurveOverShooting,
      preventCurveOvershootingThreshold: preventCurveOvershootingThreshold ??
          this.preventCurveOvershootingThreshold,
      isStrokeCapRound: isStrokeCapRound ?? this.isStrokeCapRound,
      isStrokeJoinRound: isStrokeJoinRound ?? this.isStrokeJoinRound,
      belowBarData: belowBarData ?? this.belowBarData,
      aboveBarData: aboveBarData ?? this.aboveBarData,
      dashArray: dashArray ?? this.dashArray,
      dotData: dotData ?? this.dotData,
      showingIndicators: showingIndicators ?? this.showingIndicators,
      shadow: shadow ?? this.shadow,
      isStepLineChart: isStepLineChart ?? this.isStepLineChart,
      lineChartStepData: lineChartStepData ?? this.lineChartStepData,
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        spots,
        show,
        color,
        gradient,
        barWidth,
        isCurved,
        curveSmoothness,
        preventCurveOverShooting,
        preventCurveOvershootingThreshold,
        isStrokeCapRound,
        isStrokeJoinRound,
        belowBarData,
        aboveBarData,
        dotData,
        showingIndicators,
        dashArray,
        shadow,
        isStepLineChart,
        lineChartStepData,
      ];
}
