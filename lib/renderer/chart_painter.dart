import 'dart:async' show StreamSink;
// import 'dart:math' as math;

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
import 'dart:math';

class ChartPainter extends BaseChartPainter {
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  AnimationController? controller;
  final List<KChartOrder> orders;
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
    //??????????????????????????????
    sink?.add(InfoWindowEntity(point, isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //???????????????????????????
    if (isLongPress) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //??????????????????????????????
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //???????????????????????????
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //?????????
      TextPainter tp = getTextPainter("?????? ${format(mMainLowMinValue)}",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainLowMinValue)} ??????",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //?????????
      TextPainter tp = getTextPainter("?????? ${format(mMainHighMaxValue)}",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainHighMaxValue)} ??????",
          color: ChartColors.maxMinTextColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  ///????????????
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = ChartColors.crossLineWidth
      ..strokeWidth = 0.5 //ChartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k????????????
    canvas.drawLine(Offset(x, ChartStyle.topPadding),
        Offset(x, size.height - ChartStyle.bottomDateHigh), paintY);

    Paint paintX = Paint()
      ..color = ChartColors.crossLineHeight
      ..strokeWidth = ChartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k????????????
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

  ///??????????????????
  @override
  void drawRealTimePrice(Canvas canvas, Size size) {
    if (mMarginRight == 0 || datas.isEmpty == true) return;
    drawOrdersLine(canvas, size);
    KLineEntity point = datas.last;
    //???????????????
    double y = getMainY(point.close);
    TextPainter tp = getTextPainter(format(point.close),
        color: ChartColors.rightRealTimeTextColor);

    //max????????????????????????
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
      //???????????????
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
        stopAnimation(); //???????????????
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
      stopAnimation(); //???????????????
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

      //???????????????
      const triangleHeight = 8.0; //????????????
      const triangleWidth = 5.0; //????????????
      double left =
          mWidth - mWidth / ChartStyle.gridColumns - tp.width / 2 - padding * 2;
      double top = y - tp.height / 2 - padding;
      //???????????????????????????padding
      double right = left + tp.width + padding * 2 + triangleWidth + padding;
      double bottom = top + tp.height + padding * 2;
      // double radius = (bottom - top) / 2;
      //???????????????
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
      //??????
      tp = getTextPainter(format(point.close),
          color: ChartColors.realTimeTextColor);
      Offset textOffset = Offset(left + padding, y - tp.height / 2);
      tp.paint(canvas, textOffset);
      //?????????
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

  void drawOrdersLine(Canvas canvas, Size size) {
    if (mMarginRight == 0 || datas.isEmpty == true) return;
    KLineEntity point = datas.last;

    //????????????
    var ups =
        orders.where((order) => order.price > mMainMaxValue).toList(); //????????????
    var dns =
        orders.where((order) => order.price < mMainMinValue).toList(); //?????????
    var nms = orders
        .where((order) =>
            order.price >= mMainMinValue && order.price <= mMainMaxValue)
        .toList();
    dns.sort((a, b) => (a.price - b.price).toInt());
    ups.sort((a, b) => (b.price - a.price).toInt());
    nms.sort((a, b) => (b.price - a.price).toInt());
    const _height = 17;
    var baseTop = getMainY(mMainMaxValue);
    var baseBottom = getMainY(mMainMinValue);
    // print("baseTop:$baseTop");

    for (var i = 0; i < ups.length; i++) {
      drawOrdersLineItem(canvas, size, ups[i], baseTop + (i * _height));
    }
    for (var i = 0; i < dns.length; i++) {
      drawOrdersLineItem(canvas, size, dns[i], baseBottom - i * _height);
    }
    List<double> ys = [];
    List<double> _rys = [];

    var _min = 0.0;
    var _max = 0.0;
    for (var i = 0; i < nms.length; i++) {
      var _price = nms[i].price;
      var _offY = getMainY(_price);
      if (ys.isEmpty) {
        _min = _price;
        _max = _price;
      } else {
        //?????????min Max
        _min = _rys.reduce(min);
        _max = _rys.reduce(max);
        if (_price >= _max) {
          _offY = min(_offY, ys.reduce(min) - _height); //????????????????????????????????????
        } else if (_price <= _min) {
          // print("?????????$_price ??????????????????: $_min");
          // print("??????_offY:$_offY,???????????????${ys.reduce(min)}");
          _offY = max(_offY, ys.reduce(max) + _height); //????????????????????????????????????
          // print("??????_offY:$_offY,???????????????${ys.reduce(min)}");
        }
      }
      // print("$i=>_yy:$_offY  pri:$_price min$_min max:$_max");
      _offY = _offY.clamp(baseTop, baseBottom);
      // print("_yy:$_yy");
      ys.add(_offY); //??????????????????
      _rys.add(_price); //????????????

      drawOrdersLineItem(canvas, size, nms[i], _offY);
    }
    // orders.forEach((order) {});
    // var yRealLine = yLine;
    // var posUp = 0;
    // var posDn = 0;

    // ups.forEach((order) {
    //   double yLine = getMainY(order.price);
    //   if (order.price > mMainMaxValue) {
    //     yLine = getMainY(mMainMaxValue);
    //   } else if (order.price < mMainMinValue) {
    //     yLine = getMainY(mMainMinValue);
    //   }
    //   drawOrdersLine(canvas, size, order, yLine);
    //   // if (order.price > mMainMaxValue) {
    //   //   yLine = getMainY(mMainMaxValue);
    //   //   drawOrdersLine(canvas, size, order, yLine + (posUp * 16));
    //   //   posUp--;
    //   // } else if (order.price < mMainMinValue) {
    //   //   yLine = getMainY(mMainMinValue);
    //   //   posDn++;
    //   //   drawOrdersLine(canvas, size, order, yLine + (posDn * 16));
    //   // } else {
    //   //   drawOrdersLine(canvas, size, order, yLine);
    //   // }
    // });
    // dns.forEach((order) {
    //   double yLine = getMainY(order.price);
    //   if (order.price > mMainMaxValue) {
    //     yLine = getMainY(mMainMaxValue);
    //   } else if (order.price < mMainMinValue) {
    //     yLine = getMainY(mMainMinValue);
    //   }
    //   drawOrdersLine(canvas, size, order, yLine);
    //   // if (order.price > mMainMaxValue) {
    //   //   yLine = getMainY(mMainMaxValue);
    //   //   drawOrdersLine(canvas, size, order, yLine + (posUp * 16));
    //   //   posUp--;
    //   // } else if (order.price < mMainMinValue) {
    //   //   yLine = getMainY(mMainMinValue);
    //   //   posDn++;
    //   //   drawOrdersLine(canvas, size, order, yLine + (posDn * 16));
    //   // } else {
    //   //   drawOrdersLine(canvas, size, order, yLine);
    //   // }
    // });

    // double yLine = getMainY(point.close);
    // if (point.close > mMainMaxValue) {
    //   yLine = getMainY(mMainMaxValue);
    // } else if (point.close < mMainMinValue) {
    //   yLine = getMainY(mMainMinValue);
    // }
    // var posMinTop = getMainY(mMainMaxValue); //????????????
    // var posMaxbottom = getMainY(mMainMinValue); //????????????

    // var posTop = posMinTop; //????????????
    // var posBottom = posMaxbottom; //????????????

    // orders.forEach((order) {
    //   var yRealLine = yLine;
    //   print("yRealLine:$yRealLine posTop:$posTop posBottom:$posBottom");
    //   if (point.close > mMainMaxValue) {
    //     //????????????
    //     yRealLine = posTop;
    //     posTop = posTop + 16; //????????????
    //   } else if (point.close < mMainMinValue) {
    //     yRealLine = posBottom;
    //     posBottom = posBottom - 16; //????????????
    //   }

    //   if (posTop > posMaxbottom) {
    //     posTop = posMaxbottom;
    //   } else if (posBottom < posMinTop) {
    //     posBottom = posMinTop;
    //   }
    //   // yRealLine = yRealLine.clamp(posTop, posBottom);
    //   // print("posMinTop:$posMinTop posMaxbottom:$posMaxbottom");
    //   // print("yLine: $yLine mMainMaxValue:$mMainMaxValue mMainMinValue:$mMainMinValue");
    //   print("yRealLine:$yRealLine posTop:$posTop posMinTop:$posMinTop");
    //   // print(
    //   //     "yRealLine:$yRealLine \n yLine:$yLine \n posMinTop:$posMinTop \n posMaxbottom:$posMaxbottom \n posTop:$posTop \n posBottom:$posBottom");
    //   drawOrdersLine(canvas, size, order, yRealLine);
    // });
  }

  void drawOrdersLineItem(
      Canvas canvas, Size size, KChartOrder order, double y) {
    if (mMarginRight == 0 || datas.isEmpty == true) return;

    // const _orderBadgeSpace = 20;
    KLineEntity point = datas.last;
    var price = order.price;
    // var text = format(price);
    // var tip = order.
    // TextPainter tp =
    //     getTextPainter(text, color: ChartColors.rightRealTimeTextColor);
    // TextPainter tptip = getTextPainter(order.tip, color: Colors.white);
    // double y = getMainY(price);
    // print("y:$y");
    const _height = 16;

    stopAnimation();

    double left = 0;
    double top = y - _height / 2;
    //???????????????????????????padding
    // double right = left + tp.width + padding * 2;
    double right = left;
    double bottom = top + _height;
    var _color = (point.close > price && !order.isShot) ||
            (point.close < price && order.isShot)
        ? ChartColors.upColor
        : ChartColors.dnColor;
    if (order.icon != null) {
      TextPainter tp = getTextPainterStyle(
        String.fromCharCode(order.icon!.codePoint),
        style: TextStyle(
          fontFamily: order.icon!.fontFamily,
          color: _color,
          fontSize: 12,
        ).merge(order.iconStyle),
      );
      var _width = _height;
      right = left + _width;
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
          realTimePaint..color = order.iconBgColor);
      tp.paint(
          canvas, Offset(left + (_width - tp.width) / 2, y - tp.height / 2));
      left = right;
    }

    //??????????????????
    if (order.useTimeRemain) {
      const _width = 30.0;
      right = left + _width;
      TextPainter tp =
          getTextPainter("${order.timeRemain.inSeconds}S", color: Colors.white);
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
          realTimePaint..color = Colors.black87);
      tp.paint(
          canvas, Offset(left + (_width - tp.width) / 2, y - tp.height / 2));
      left = right;
    }

    //?????????
    {
      var text = format(price);
      TextPainter tp = getTextPainter(text, color: Colors.white);

      var _width = tp.width + 10;
      right = left + _width;
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
          realTimePaint..color = _color);
      tp.paint(
          canvas, Offset(left + (_width - tp.width) / 2, y - tp.height / 2));
      left = right;
    }
    //???TIP
    if (order.tip.isNotEmpty) {
      TextPainter tp = getTextPainterStyle(order.tip,
          style: order.tipStyle ?? getTextStyle(_color));
      var _width = tp.width + 10;
      right = left + _width;
      tp.paint(
          canvas, Offset(left + (_width - tp.width) / 2, y - tp.height / 2));
      left = right;
    }
    //?????????
    {
      var dashWidth = 1;
      var dashSpace = 2;
      var startX = left;
      final space = (dashSpace + dashWidth);
      while (startX < mWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          realTimePaint
            ..strokeWidth = 1
            ..color = _color.withOpacity(0.5),
        );
        startX += space;
      }
    }

    //????????????

    // final space = (dashSpace + dashWidth);

    //???????????????

    // //???????????????
    // double left =
    //     mWidth - mWidth / ChartStyle.gridColumns - tp.width / 2 - padding * 2;
    // left = order.useTimeRemain ? _orderBadgeWidth : 0;
    // double top = y - tp.height / 2 - padding;
    // //???????????????????????????padding
    // double right = left + tp.width + padding * 2 + padding;
    // double bottom = top + tp.height + padding * 2;
    // startX = right + tptip.width;
    // while (startX < mWidth) {
    //   canvas.drawLine(
    //     Offset(startX, y),
    //     Offset(startX + dashWidth, y),
    //     realTimePaint
    //       ..strokeWidth = 1
    //       ..color = _color.withOpacity(0.8),
    //   );
    //   startX += space;
    // }
    // canvas.drawRect(Rect.fromLTRB(left, top, right, bottom),
    //     realTimePaint..color = _color.withOpacity(1));

    // //????????????
    // if (order.tip.isNotEmpty) {
    //   canvas.drawRect(Rect.fromLTRB(right, top, right + tptip.width, bottom),
    //       realTimePaint..color = Colors.black87);
    //   Offset textOffset = Offset(right, y - tptip.height / 2);
    //   tptip.paint(canvas, textOffset);
    // }
    // if (order.useTimeRemain) {
    //   canvas.drawRect(Rect.fromLTRB(0, top, _orderBadgeWidth, bottom),
    //       realTimePaint..color = Colors.black87);
    //   //?????????
    //   // final icon = Icons.alarm;
    //   // var builder = ui.ParagraphBuilder(ui.ParagraphStyle(
    //   //   fontFamily: icon.fontFamily,
    //   //   fontSize: 8,
    //   //   // height: 16,
    //   //   textAlign: TextAlign.center,
    //   // ))
    //   //   ..addText(String.fromCharCode(icon.codePoint));
    //   // var para = builder.build();
    //   // para.layout(const ui.ParagraphConstraints(width: 16));
    //   // canvas.drawParagraph(para, Offset(0, top));

    //   //????????????
    //   tp =
    //       getTextPainter("${order.timeRemain.inSeconds}S", color: Colors.white);
    //   Offset textOffset = Offset(2, y - tp.height / 2);
    //   tp.paint(canvas, textOffset);
    // }

    // //??????
    // tp = getTextPainter(text, color: Colors.white);
    // Offset textOffset = Offset(left + padding, y - tp.height / 2);
    // tp.paint(canvas, textOffset);
  }

  TextPainter getTextPainter(text, {color = Colors.white}) {
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  TextPainter getTextPainterStyle(text, {style = const TextStyle()}) {
    TextSpan span = TextSpan(text: "$text", style: style);
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
