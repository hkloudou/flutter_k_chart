import 'package:flutter/material.dart' show Color;

class ChartColors {
  ChartColors._();

  //背景颜色
  static Color bgColor = Color(0xff0D141E);
  static Color kLineColor = Color(0xff4C86CD);
  static Color gridColor = Color(0xff4c5c74);
  static List<Color> kLineShadowColor = [
    Color(0x554C86CD),
    Color(0x00000000)
  ]; //k线阴影渐变
  static Color ma5Color = Color(0xffC9B885);
  static Color ma10Color = Color(0xff6CB0A6);
  static Color ma30Color = Color(0xff9979C6);
  static Color upColor = Color.fromRGBO(30, 191, 120, 1);
  static Color dnColor = Color.fromRGBO(205, 51, 77, 1);
  static Color volUpColor = Color.fromRGBO(30, 114, 81, 1);
  static Color volDnColor = Color.fromRGBO(133, 49, 63, 1);
  static Color volColor = Color(0xff4729AE);

  static Color macdColor = Color(0xff4729AE);
  static Color difColor = Color(0xffC9B885);
  static Color deaColor = Color(0xff6CB0A6);

  static Color kColor = Color(0xffC9B885);
  static Color dColor = Color(0xff6CB0A6);
  static Color jColor = Color(0xff9979C6);
  static Color rsiColor = Color(0xffC9B885);

  static Color yAxisTextColor = Color(0xff60738E); //右边y轴刻度
  static Color xAxisTextColor = Color(0xff60738E); //下方时间刻度

  static Color maxMinTextColor = Color(0xffffffff); //最大最小值的颜色

  //深度颜色
  static Color depthBuyColor = Color(0xff60A893);
  static Color depthSellColor = Color(0xffC15866);

  //选中后显示值边框颜色
  static Color markerBorderColor = Color(0xff6C7A86);

  //选中后显示值背景的填充颜色
  static Color markerBgColor = Color(0xff0D1722);

  static Color markerTextColor = Color(0xFFFFFFFF);

  //实时线颜色等
  static Color realTimeBgColor = Color(0xff0D1722);
  static Color rightRealTimeTextColor = Color(0xff4C86CD);
  static Color realTimeTextBorderColor = Color(0xffffffff);
  static Color realTimeTextColor = Color(0xffffffff);

  //实时线
  static Color realTimeLineColor = Color(0xffffffff);
  static Color realTimeLongLineColor = Color(0xff4C86CD);

  static Color simpleLineUpColor = Color(0xff6CB0A6);
  static Color simpleLineDnColor = Color(0xffC15466);

  //交叉线
  static Color crossLineWidth = Color(0xFFFFFFFF).withOpacity(0.12);
  static Color crossLineHeight = Color(0xFFFFFFFF);
  static Color crossTextColor = Color(0x00000000);
}

class ChartStyle {
  ChartStyle._();

  //点与点的距离
  static const double pointWidth = 11.0;

  //蜡烛宽度
  static const double candleWidth = 8.5;

  //蜡烛中间线的宽度
  static const double candleLineWidth = 1.5;

  //vol柱子宽度
  static const double volWidth = 8.5;

  //macd柱子宽度
  static const double macdWidth = 3.0;

  //垂直交叉线宽度
  static const double vCrossWidth = 8.5;

  //水平交叉线宽度
  static const double hCrossWidth = 0.5;

  //网格
  static const int gridRows = 3, gridColumns = 4;

  static const double topPadding = 30.0,
      bottomDateHigh = 20.0,
      childPadding = 25.0;

  static const double defaultTextSize = 10.0;
}
