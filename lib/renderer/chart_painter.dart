import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import 'package:flutter_k_chart/k_chart_widget.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import '../entity/info_window_entity.dart';

import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';
import 'dart:ui' as ui;

class ChartPainter extends BaseChartPainter {
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  AnimationController? controller;
  final List<KChartOrders> orders;
  double opacity;

  ChartPainter(
      {required datas,
      required scaleX,
      required scrollX,
      required isLongPass,
      required selectX,
      this.orders = const [],
      mainState,
      volState,
      secondaryState,
      this.sink,
      bool isLine = false,
      this.controller,
      this.opacity = 0.0})
      : super(
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            selectX: selectX,
            mainState: mainState,
            volState: volState,
            secondaryState: secondaryState,
            isLine: isLine);

  @override
  void initChartRenderer() {
    mMainRenderer = MainRenderer(mMainRect, mMainMaxValue, mMainMinValue,
        ChartStyle.topPadding, mainState, isLine, scaleX);
    if (mVolRect != null) {
      mVolRenderer ??= VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          ChartStyle.childPadding, scaleX);
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer ??= SecondaryRenderer(
          mSecondaryRect!,
          mSecondaryMaxValue,
          mSecondaryMinValue,
          ChartStyle.childPadding,
          secondaryState,
          scaleX);
    }
  }

  final Paint mBgPaint = Paint()..color = ChartColors.bgColor;

  @override
  void drawBg(Canvas canvas, Size size) {
    Rect mainRect = Rect.fromLTRB(
        0, 0, mMainRect.width, mMainRect.height + ChartStyle.topPadding);
    canvas.drawRect(mainRect, mBgPaint);

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(0, mVolRect!.top - ChartStyle.childPadding,
          mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(volRect, mBgPaint);
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(
          0,
          mSecondaryRect!.top - ChartStyle.childPadding,
          mSecondaryRect!.width,
          mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect, mBgPaint);
    }
    Rect dateRect = Rect.fromLTRB(
        0, size.height - ChartStyle.bottomDateHigh, size.width, size.height);
    canvas.drawRect(dateRect, mBgPaint);
  }

  @override
  void drawGrid(canvas) {
    mMainRenderer.drawGrid(canvas, ChartStyle.gridRows, ChartStyle.gridColumns);
    mVolRenderer?.drawGrid(canvas, ChartStyle.gridRows, ChartStyle.gridColumns);
    mSecondaryRenderer?.drawGrid(
        canvas, ChartStyle.gridRows, ChartStyle.gridColumns);
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      KLineEntity curPoint = datas[i];
      KLineEntity lastPoint = i == 0 ? curPoint : datas[i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mSecondaryRenderer?.drawChart(
          lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if (isLongPress == true) drawCrossLine(canvas, size);
    canvas.restore();
  }

  @override
  void drawRightText(canvas) {
    var textStyle = getTextStyle(ChartColors.yAxisTextColor);
    mMainRenderer.drawRightText(canvas, textStyle, ChartStyle.gridRows);
    mVolRenderer?.drawRightText(canvas, textStyle, ChartStyle.gridRows);
    mSecondaryRenderer?.drawRightText(canvas, textStyle, ChartStyle.gridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    double columnSpace = size.width / ChartStyle.gridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double y = 0.0;
    for (var i = 0; i <= ChartStyle.gridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);
      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);
        TextPainter tp = getTextPainter(getDate(datas[index].id!),
            color: ChartColors.xAxisTextColor);
        y = size.height -
            (ChartStyle.bottomDateHigh - tp.height) / 2 -
            tp.height;
        tp.paint(canvas, Offset(columnSpace * i - tp.width / 2, y));
      }
    }
  }

  Paint selectPointPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..color = ChartColors.markerBgColor;
  Paint selectorBorderPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = ChartColors.markerBorderColor;

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp =
        getTextPainter(format(point.close), color: ChartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.id!), color: ChartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - ChartStyle.bottomDateHigh;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter("── ${format(mMainLowMinValue)}",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainLowMinValue)} ──",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter("── ${format(mMainHighMaxValue)}",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainHighMaxValue)} ──",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = ChartColors.crossLineWidth
      ..strokeWidth = 0.5 //ChartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k线图竖线
    canvas.drawLine(Offset(x, ChartStyle.topPadding),
        Offset(x, size.height - ChartStyle.bottomDateHigh), paintY);

    Paint paintX = Paint()
      ..color = ChartColors.crossLineHeight
      ..strokeWidth = ChartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
//    canvas.drawCircle(Offset(x, y), 2.0, paintX);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
        paintX);
  }

  final Paint realTimePaint = Paint()
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
      pointPaint = Paint();

  ///画实时价格线
  @override
  void drawRealTimePrice(Canvas canvas, Size size) {
    if (mMarginRight == 0 || datas.isEmpty == true) return;
    KLineEntity point = datas.last;

    //实时订单
    var ups = orders.where((order) => point.close >= order.price).toList();
    var dns = orders.where((order) => point.close < order.price).toList();
    dns.sort((a, b) => (b.price - a.price).toInt());
    ups.sort((a, b) => (a.price - b.price).toInt());
    var posUp = 0.00;
    var posDown = 0.00;
    ups.forEach((order) {
      drawOrdersLine(canvas, size, order, posUp);
      posUp--;
    });
    dns.forEach((order) {
      drawOrdersLine(canvas, size, order, posDown);
      posDown++;
    });

    //实时价格线
    TextPainter tp = getTextPainter(format(point.close),
        color: ChartColors.rightRealTimeTextColor);
    double y = getMainY(point.close);
    //max越往右边滑值越小
    var max = (mTranslateX.abs() +
            mMarginRight -
            getMinTranslateX().abs() +
            mPointWidth) *
        scaleX;
    double x = mWidth - max;
    if (!isLine) x += mPointWidth / 2;
    var dashWidth = 4;
    var dashSpace = 3;
    const padding = 2;
    double startX = 0;
    final space = (dashSpace + dashWidth);
    if (tp.width < max) {
      while (startX < max) {
        canvas.drawLine(
            Offset(x + startX, y),
            Offset(x + startX + dashWidth, y),
            realTimePaint..color = ChartColors.realTimeLineColor);
        startX += space;
      }
      //画一闪一闪
      if (isLine) {
        startAnimation();
        Gradient pointGradient = RadialGradient(
            colors: [Colors.white.withOpacity(opacity), Colors.transparent]);
        pointPaint.shader = pointGradient
            .createShader(Rect.fromCircle(center: Offset(x, y), radius: 14.0));
        canvas.drawCircle(Offset(x, y), 14.0, pointPaint);
        canvas.drawCircle(
            Offset(x, y), 2.0, realTimePaint..color = Colors.white);
      } else {
        stopAnimation(); //停止一闪闪
      }

      double left = mWidth - tp.width - padding * 2;
      double top = y - tp.height / 2 - padding;
      // double bottom = left + tp.width + padding * 2;
      double right = left + tp.width + padding * 2;
      double bottom = top + tp.height + padding * 2;
      // double

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
          realTimePaint..color = ChartColors.realTimeBgColor);
      Offset textOffset = Offset(left + padding, y - tp.height / 2);
      tp.paint(canvas, textOffset);
    } else {
      stopAnimation(); //停止一闪闪
      startX = 0;
      if (point.close > mMainMaxValue) {
        y = getMainY(mMainMaxValue);
      } else if (point.close < mMainMinValue) {
        y = getMainY(mMainMinValue);
      }
      while (startX < mWidth) {
        canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y),
            realTimePaint..color = ChartColors.realTimeLongLineColor);
        startX += space;
      }

      //画价格背景
      const triangleHeight = 8.0; //三角高度
      const triangleWidth = 5.0; //三角宽度
      double left =
          mWidth - mWidth / ChartStyle.gridColumns - tp.width / 2 - padding * 2;
      double top = y - tp.height / 2 - padding;
      //加上三角形的宽以及padding
      double right = left + tp.width + padding * 2 + triangleWidth + padding;
      double bottom = top + tp.height + padding * 2;
      // double radius = (bottom - top) / 2;
      //画椭圆背景
      // RRect rectBg1 =
      //     RRect.fromLTRBR(left, top, right, bottom, Radius.circular(radius));
      // RRect rectBg2 = RRect.fromLTRBR(left - 1, top - 1, right + 1, bottom + 1,
      //     Radius.circular(radius + 2));
      // canvas.drawRRect(
      //     rectBg2, realTimePaint..color = ChartColors.realTimeTextBorderColor);
      // canvas.drawRRect(
      //     rectBg1, realTimePaint..color = ChartColors.realTimeBgColor);
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
          realTimePaint..color = ChartColors.realTimeBgColor);
      //文字
      tp = getTextPainter(format(point.close),
          color: ChartColors.realTimeTextColor);
      Offset textOffset = Offset(left + padding, y - tp.height / 2);
      tp.paint(canvas, textOffset);
      //画三角
      Path path = Path();
      double dx = tp.width + textOffset.dx + padding;
      double dy = top + (bottom - top - triangleHeight) / 2;
      path.moveTo(dx, dy);
      path.lineTo(dx + triangleWidth, dy + triangleHeight / 2);
      path.lineTo(dx, dy + triangleHeight);
      path.close();
      canvas.drawPath(
          path,
          realTimePaint
            ..color = ChartColors.realTimeTextColor
            ..shader = null);
    }
  }

  void drawOrdersLine(
      Canvas canvas, Size size, KChartOrders order, double pos) {
    if (mMarginRight == 0 || datas.isEmpty == true) return;
    const _orderBadgeWidth = 30.0;
    const _orderBadgeSpace = 20;
    KLineEntity point = datas.last;
    var price = order.price;
    var text = format(price);
    TextPainter tp =
        getTextPainter(text, color: ChartColors.rightRealTimeTextColor);
    double y = getMainY(price);
    var _color =
        point.close > price ? ChartColors.upColor : ChartColors.dnColor;
    var dashWidth = 4;
    var dashSpace = 1;
    const padding = 2;
    double startX = 0;
    final space = (dashSpace + dashWidth);

    stopAnimation(); //停止一闪闪

    if (price > mMainMaxValue) {
      y = getMainY(mMainMaxValue);
      y = y + (pos * _orderBadgeSpace);
    } else if (price < mMainMinValue) {
      y = getMainY(mMainMinValue);
      y = y + (pos * _orderBadgeSpace);
    }

    //画价格背景
    double left =
        mWidth - mWidth / ChartStyle.gridColumns - tp.width / 2 - padding * 2;
    left = order.useTimeRemain ? _orderBadgeWidth : 0;
    double top = y - tp.height / 2 - padding;
    //加上三角形的宽以及padding
    double right = left + tp.width + padding * 2 + padding;
    double bottom = top + tp.height + padding * 2;
    startX = right;
    while (startX < mWidth) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        realTimePaint
          ..strokeWidth = 1
          ..color = _color.withOpacity(0.8),
      );
      startX += space;
    }
    // double radius = (bottom - top) / 2;
    //画椭圆背景
    // RRect rectBg1 =
    //     RRect.fromLTRBR(left, top, right, bottom, Radius.circular(radius));
    // RRect rectBg2 = RRect.fromLTRBR(left - 1, top - 1, right + 1, bottom + 1,
    //     Radius.circular(radius + 2));
    // canvas.drawRRect(
    //     rectBg2, realTimePaint..color = ChartColors.realTimeTextBorderColor);
    // canvas.drawRRect(
    //     rectBg1, realTimePaint..color = ChartColors.realTimeBgColor);
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
        realTimePaint..color = _color.withOpacity(1));
    // canvas.draw(Image.network(src), Offset(left + padding, y - tp.height / 2),
    //     realTimePaint);

    if (order.useTimeRemain) {
      canvas.drawRect(Rect.fromLTRB(0, top, _orderBadgeWidth, bottom),
          realTimePaint..color = Colors.black87);
      //画图标
      // final icon = Icons.alarm;
      // var builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      //   fontFamily: icon.fontFamily,
      //   fontSize: 8,
      //   // height: 16,
      //   textAlign: TextAlign.center,
      // ))
      //   ..addText(String.fromCharCode(icon.codePoint));
      // var para = builder.build();
      // para.layout(const ui.ParagraphConstraints(width: 16));
      // canvas.drawParagraph(para, Offset(0, top));

      //画倒计时
      tp =
          getTextPainter("${order.timeRemain.inSeconds}S", color: Colors.white);
      Offset textOffset = Offset(2, y - tp.height / 2);
      tp.paint(canvas, textOffset);
    }

    //文字
    tp = getTextPainter(text, color: Colors.white);
    Offset textOffset = Offset(left + padding, y - tp.height / 2);
    tp.paint(canvas, textOffset);
    //画三角
    // Path path = Path();
    // double dx = tp.width + textOffset.dx + padding;
    // double dy = top + (bottom - top - triangleHeight) / 2;
    // path.moveTo(dx, dy);
    // path.lineTo(dx + triangleWidth, dy + triangleHeight / 2);
    // path.lineTo(dx, dy + triangleHeight);
    // path.close();
    // canvas.drawPath(
    //     path,
    //     realTimePaint
    //       ..color = Colors.white
    //       ..shader = null);
  }

  TextPainter getTextPainter(text, {color = Colors.white}) {
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int date) =>
      dateFormat(DateTime.fromMillisecondsSinceEpoch(date * 1000), mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  startAnimation() {
    if (controller?.isAnimating != true) controller?.repeat(reverse: true);
  }

  stopAnimation() {
    if (controller?.isAnimating == true) controller?.stop();
  }
}
