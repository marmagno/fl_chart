import 'package:fl_chart/src/chart/bar_chart/bar_chart_painter.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_extensions.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_helper.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_painter.dart';
import 'package:fl_chart/src/extensions/paint_extension.dart';
import 'package:fl_chart/src/extensions/path_extension.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';

import 'axis_chart_data.dart';

/// This class is responsible to draw the grid behind all axis base charts.
/// also we have two useful function [getPixelX] and [getPixelY] that used
/// in child classes -> [BarChartPainter], [LineChartPainter]
/// [dataList] is the currently showing data (it may produced by an animation using lerp function),
/// [targetData] is the target data, that animation is going to show (if animating)
abstract class AxisChartPainter<D extends AxisChartData>
    extends BaseChartPainter<D> {
  late Paint _gridPaint, _backgroundPaint, _lineBarPaint;

  /// [_rangeAnnotationPaint] draws range annotations;
  late Paint _rangeAnnotationPaint;

  AxisChartPainter() : super() {
    _gridPaint = Paint()..style = PaintingStyle.stroke;

    _backgroundPaint = Paint()..style = PaintingStyle.fill;

    _rangeAnnotationPaint = Paint()..style = PaintingStyle.fill;

    _lineBarPaint = Paint()..style = PaintingStyle.stroke;
  }

  /// Paints [AxisChartData] into the provided canvas.
  @override
  void paint(BuildContext context, CanvasWrapper canvasWrapper,
      PaintHolder<D> holder) {
    super.paint(context, canvasWrapper, holder);
    drawBackground(canvasWrapper, holder);
    drawRangeAnnotation(canvasWrapper, holder);
    drawGrid(canvasWrapper, holder);
  }

  @visibleForTesting
  void drawGrid(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    if (!data.gridData.show) {
      return;
    }
    final viewSize = canvasWrapper.size;
    // Show Vertical Grid
    if (data.gridData.drawVerticalLine) {
      final verticalInterval = data.gridData.verticalInterval ??
          Utils().getEfficientInterval(
            viewSize.width,
            data.horizontalDiff,
          );
      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: data.minX,
        minIncluded: false,
        max: data.maxX,
        maxIncluded: false,
        baseLine: data.baselineX,
        interval: verticalInterval,
      );
      for (double axisValue in axisValues) {
        if (!data.gridData.checkToShowVerticalLine(axisValue)) {
          continue;
        }
        final flLineStyle = data.gridData.getDrawingVerticalLine(axisValue);
        _gridPaint.color = flLineStyle.color;
        _gridPaint.strokeWidth = flLineStyle.strokeWidth;
        _gridPaint.transparentIfWidthIsZero();

        final bothX = getPixelX(axisValue, viewSize, holder);
        final x1 = bothX;
        const y1 = 0.0;
        final x2 = bothX;
        final y2 = viewSize.height;
        canvasWrapper.drawDashedLine(
            Offset(x1, y1), Offset(x2, y2), _gridPaint, flLineStyle.dashArray);
      }
    }

    // Show Horizontal Grid
    if (data.gridData.drawHorizontalLine) {
      final horizontalInterval = data.gridData.horizontalInterval ??
          Utils().getEfficientInterval(viewSize.height, data.verticalDiff);

      final axisValues = AxisChartHelper().iterateThroughAxis(
        min: data.minY,
        minIncluded: false,
        max: data.maxY,
        maxIncluded: false,
        baseLine: data.baselineY,
        interval: horizontalInterval,
      );
      for (double axisValue in axisValues) {
        if (!data.gridData.checkToShowHorizontalLine(axisValue)) {
          continue;
        }
        final flLine = data.gridData.getDrawingHorizontalLine(axisValue);
        _gridPaint.color = flLine.color;
        _gridPaint.strokeWidth = flLine.strokeWidth;
        _gridPaint.transparentIfWidthIsZero();

        final bothY = getPixelY(axisValue, viewSize, holder);
        const x1 = 0.0;
        final y1 = bothY;
        final x2 = viewSize.width;
        final y2 = bothY;
        canvasWrapper.drawDashedLine(
            Offset(x1, y1), Offset(x2, y2), _gridPaint, flLine.dashArray);
      }
    }
  }

  /// This function draws a colored background behind the chart.
  @visibleForTesting
  void drawBackground(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    if (data.backgroundColor.opacity == 0.0) {
      return;
    }

    final viewSize = canvasWrapper.size;
    _backgroundPaint.color = data.backgroundColor;
    canvasWrapper.drawRect(
      Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
      _backgroundPaint,
    );
  }

  @visibleForTesting
  void drawRangeAnnotation(CanvasWrapper canvasWrapper, PaintHolder<D> holder) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    if (data.rangeAnnotations.verticalRangeAnnotations.isNotEmpty) {
      for (var annotation in data.rangeAnnotations.verticalRangeAnnotations) {
        final from = Offset(getPixelX(annotation.x1, viewSize, holder), 0.0);
        final to = Offset(
          getPixelX(annotation.x2, viewSize, holder),
          viewSize.height,
        );

        final rect = Rect.fromPoints(from, to);

        _rangeAnnotationPaint.color = annotation.color;

        canvasWrapper.drawRect(rect, _rangeAnnotationPaint);
      }
    }

    if (data.rangeAnnotations.horizontalRangeAnnotations.isNotEmpty) {
      for (var annotation in data.rangeAnnotations.horizontalRangeAnnotations) {
        final from = Offset(0.0, getPixelY(annotation.y1, viewSize, holder));
        final to = Offset(
          viewSize.width,
          getPixelY(annotation.y2, viewSize, holder),
        );

        final rect = Rect.fromPoints(from, to);

        _rangeAnnotationPaint.color = annotation.color;

        canvasWrapper.drawRect(rect, _rangeAnnotationPaint);
      }
    }
  }

  /// With this function we can convert our [FlSpot] x
  /// to the view base axis x .
  /// the view 0, 0 is on the top/left, but the spots is bottom/left
  double getPixelX(double spotX, Size viewSize, PaintHolder<D> holder) {
    final data = holder.data;
    final deltaX = data.maxX - data.minX;
    if (deltaX == 0.0) {
      return 0.0;
    }
    return ((spotX - data.minX) / deltaX) * viewSize.width;
  }

  /// With this function we can convert our [FlSpot] y
  /// to the view base axis y.
  double getPixelY(double spotY, Size viewSize, PaintHolder<D> holder) {
    final data = holder.data;
    final deltaY = data.maxY - data.minY;
    if (deltaY == 0.0) {
      return viewSize.height;
    }
    var y = ((spotY - data.minY) / deltaY) * viewSize.height;
    y = viewSize.height - y;
    return y;
  }

  void drawBarLine(CanvasWrapper canvasWrapper, LineChartBarData barData,
      PaintHolder<D> holder) {
    final viewSize = canvasWrapper.size;
    final barList = barData.spots.splitByNullSpots();

    // paint each sublist that was built above
    // bar is passed in separately from barData
    // because barData is the whole line
    // and bar is a piece of that line
    for (var bar in barList) {
      final barPath = generateBarPath(viewSize, barData, bar, holder);
      drawBarShadow(canvasWrapper, barPath, barData);
      drawBar(canvasWrapper, barPath, barData, holder);
    }
  }

  /// Generates a path, based on [LineChartBarData.isStepChart] for step style, and normal style.
  Path generateBarPath(Size viewSize, LineChartBarData barData,
      List<FlSpot> barSpots, PaintHolder<D> holder,
      {Path? appendToPath}) {
    if (barData.isStepLineChart) {
      return generateStepBarPath(viewSize, barData, barSpots, holder,
          appendToPath: appendToPath);
    } else {
      return generateNormalBarPath(viewSize, barData, barSpots, holder,
          appendToPath: appendToPath);
    }
  }

  /// firstly we generate the bar line that we should draw,
  /// then we reuse it to fill below bar space.
  /// there is two type of barPath that generate here,
  /// first one is the sharp corners line on spot connections
  /// second one is curved corners line on spot connections,
  /// and we use isCurved to find out how we should generate it,
  /// If you want to concatenate paths together for creating an area between
  /// multiple bars for example, you can pass the appendToPath
  @visibleForTesting
  Path generateNormalBarPath(Size viewSize, LineChartBarData barData,
      List<FlSpot> barSpots, PaintHolder<D> holder,
      {Path? appendToPath}) {
    final path = appendToPath ?? Path();
    final size = barSpots.length;

    var temp = const Offset(0.0, 0.0);

    final x = getPixelX(barSpots[0].x, viewSize, holder);
    final y = getPixelY(barSpots[0].y, viewSize, holder);
    if (appendToPath == null) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
    for (var i = 1; i < size; i++) {
      /// CurrentSpot
      final current = Offset(
        getPixelX(barSpots[i].x, viewSize, holder),
        getPixelY(barSpots[i].y, viewSize, holder),
      );

      /// previous spot
      final previous = Offset(
        getPixelX(barSpots[i - 1].x, viewSize, holder),
        getPixelY(barSpots[i - 1].y, viewSize, holder),
      );

      /// next point
      final next = Offset(
        getPixelX(barSpots[i + 1 < size ? i + 1 : i].x, viewSize, holder),
        getPixelY(barSpots[i + 1 < size ? i + 1 : i].y, viewSize, holder),
      );

      final controlPoint1 = previous + temp;

      /// if the isCurved is false, we set 0 for smoothness,
      /// it means we should not have any smoothness then we face with
      /// the sharped corners line
      final smoothness = barData.isCurved ? barData.curveSmoothness : 0.0;
      temp = ((next - previous) / 2) * smoothness;

      if (barData.preventCurveOverShooting) {
        if ((next - current).dy <= barData.preventCurveOvershootingThreshold ||
            (current - previous).dy <=
                barData.preventCurveOvershootingThreshold) {
          temp = Offset(temp.dx, 0);
        }

        if ((next - current).dx <= barData.preventCurveOvershootingThreshold ||
            (current - previous).dx <=
                barData.preventCurveOvershootingThreshold) {
          temp = Offset(0, temp.dy);
        }
      }

      final controlPoint2 = current - temp;

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }

    return path;
  }

  /// generates a `Step Line Chart` bar style path.
  @visibleForTesting
  Path generateStepBarPath(Size viewSize, LineChartBarData barData,
      List<FlSpot> barSpots, PaintHolder<D> holder,
      {Path? appendToPath}) {
    final path = appendToPath ?? Path();
    final size = barSpots.length;

    final x = getPixelX(barSpots[0].x, viewSize, holder);
    final y = getPixelY(barSpots[0].y, viewSize, holder);
    if (appendToPath == null) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
    for (var i = 0; i < size; i++) {
      /// CurrentSpot
      final current = Offset(
        getPixelX(barSpots[i].x, viewSize, holder),
        getPixelY(barSpots[i].y, viewSize, holder),
      );

      /// next point
      final next = Offset(
        getPixelX(barSpots[i + 1 < size ? i + 1 : i].x, viewSize, holder),
        getPixelY(barSpots[i + 1 < size ? i + 1 : i].y, viewSize, holder),
      );

      final stepDirection = barData.lineChartStepData.stepDirection;

      // middle
      if (current.dy == next.dy) {
        path.lineTo(next.dx, next.dy);
      } else {
        final deltaX = next.dx - current.dx;

        path.lineTo(current.dx + deltaX - (deltaX * stepDirection), current.dy);
        path.lineTo(current.dx + deltaX - (deltaX * stepDirection), next.dy);
        path.lineTo(next.dx, next.dy);
      }
    }

    return path;
  }

  /// draw the main bar line's shadow by the [barPath]
  @visibleForTesting
  void drawBarShadow(
      CanvasWrapper canvasWrapper, Path barPath, LineChartBarData barData) {
    if (!barData.show || barData.shadow.color.opacity == 0.0) {
      return;
    }

    _lineBarPaint.strokeCap =
        barData.isStrokeCapRound ? StrokeCap.round : StrokeCap.butt;
    _lineBarPaint.strokeJoin =
        barData.isStrokeJoinRound ? StrokeJoin.round : StrokeJoin.miter;
    _lineBarPaint.color = barData.shadow.color;
    _lineBarPaint.shader = null;
    _lineBarPaint.strokeWidth = barData.barWidth;
    _lineBarPaint.color = barData.shadow.color;
    _lineBarPaint.maskFilter = MaskFilter.blur(BlurStyle.normal,
        Utils().convertRadiusToSigma(barData.shadow.blurRadius));

    barPath = barPath.toDashedPath(barData.dashArray);

    barPath = barPath.shift(barData.shadow.offset);

    canvasWrapper.drawPath(
      barPath,
      _lineBarPaint,
    );
  }

  /// draw the main bar line by the [barPath]
  @visibleForTesting
  void drawBar(
    CanvasWrapper canvasWrapper,
    Path barPath,
    LineChartBarData barData,
    PaintHolder<D> holder,
  ) {
    if (!barData.show) {
      return;
    }
    final viewSize = canvasWrapper.size;

    _lineBarPaint.strokeCap =
        barData.isStrokeCapRound ? StrokeCap.round : StrokeCap.butt;
    _lineBarPaint.strokeJoin =
        barData.isStrokeJoinRound ? StrokeJoin.round : StrokeJoin.miter;

    final rectAroundTheLine = Rect.fromLTRB(
      getPixelX(barData.mostLeftSpot.x, viewSize, holder),
      getPixelY(barData.mostTopSpot.y, viewSize, holder),
      getPixelX(barData.mostRightSpot.x, viewSize, holder),
      getPixelY(barData.mostBottomSpot.y, viewSize, holder),
    );
    _lineBarPaint.setColorOrGradient(
      barData.color,
      barData.gradient,
      rectAroundTheLine,
    );

    _lineBarPaint.maskFilter = null;
    _lineBarPaint.strokeWidth = barData.barWidth;
    _lineBarPaint.transparentIfWidthIsZero();

    barPath = barPath.toDashedPath(barData.dashArray);
    canvasWrapper.drawPath(barPath, _lineBarPaint);
  }
}
