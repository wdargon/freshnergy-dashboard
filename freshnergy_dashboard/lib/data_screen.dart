import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:freshnergy_dashboard/data/dataResult.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'const.dart';
import 'data/dataClass.dart';
import 'generated/locale_base.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({Key? key}) : super(key: key);

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  var loc;
  // var bgColor = const Color.fromARGB(255, 20, 20, 20);
  // var cardColor = const Color.fromARGB(255, 15, 15, 15);
  var bgColor = const Color.fromARGB(255, 0x12, 0x15, 0x26);
  // var cardColor = const Color.fromARGB(255, 20, 20, 20);
  var cardColor = const Color.fromARGB(255, 0x25, 0x29, 0x35);
  var textColor = const Color.fromARGB(255, 255, 255, 255);
  var dev1Color = Colors.deepOrange.shade300;
  var dev2Color = Colors.green.shade300;
  var dev3Color = Colors.indigo.shade300;
  var dev4Color = Colors.pink.shade300;
  late DatabaseReference _firebaseData;
  DataResult? device1;
  DataResult? device2;
  DataResult? device3;
  DataResult? device4;

  final mainPaddingSize = 0.04;
  var paddingSize = 0.0;
  var sensorTitleFactor = 0.10;
  var indexChart = 0;
  late StreamSubscription<DatabaseEvent> subDeviceList;
  late Timer chartCheckTimer;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    loc = Localizations.of<LocaleBase>(context, LocaleBase);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPageData();
    chartCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) { 
      recheckDevice();
    });
  }

  recheckDevice(){
    if(device1!=null){
      device1!.checkOnline();
    }
    if(device2!=null){
      device2!.checkOnline();
    }
    if(device3!=null){
      device3!.checkOnline();
    }
    if(device4!=null){
      device4!.checkOnline();
    }
    refreshScreen();
  }

  @override
  void dispose() {
    super.dispose();
    device1?.cancelSub();
    device2?.cancelSub();
    device3?.cancelSub();
    device4?.cancelSub();
    subDeviceList.cancel();
    chartCheckTimer.cancel();
  }

  initNewDevice() {
    device1?.cancelSub();
    device2?.cancelSub();
    device3?.cancelSub();
    device4?.cancelSub();
    device1 = null;
    device2 = null;
    device3 = null;
    device4 = null;
  }

  initPageData() async {
    var subDeviceList =
        await FirebaseDatabase.instance.ref('dashboard/test').onValue.listen(
      (DatabaseEvent event) async {
        var values = event.snapshot.value;
        List<String> cidList =
            List<String>.from(event.snapshot.value as dynamic);
        initNewDevice();
        if (cidList.isNotEmpty) {
          int i = 1;
          for (var element in cidList) {
            if (i <= 4) {
              var st = await getDevice(element, i);
              if (st) {
                i++;
              }
            }
          }
        }
      },
      onError: (Object o) {
        final error = o as FirebaseException;
      },
    );
  }

  Future<bool> getDevice(String cid, int ind) async {
    var tmpDevice = await getDeviceData(cid);
    var stat = true;
    if (tmpDevice != null) {
      switch (ind) {
        case 1:
          device1 = tmpDevice;
          await device1?.getChartDataDay();
          break;
        case 2:
          device2 = tmpDevice;
          await device2?.getChartDataDay();
          break;
        case 3:
          device3 = tmpDevice;
          await device3?.getChartDataDay();
          break;
        case 4:
          device4 = tmpDevice;
          await device4?.getChartDataDay();
          break;
        default:
          stat = false;
          break;
      }
    } else {
      stat = false;
    }
    return stat;
  }

  Future<DataResult?> getDeviceData(String cid) async {
    var event = await FirebaseDatabase.instance
        .ref('user')
        .orderByChild('cid')
        .equalTo(cid)
        .once();
    if (event.snapshot.value != null) {
      var mapSnap = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
      var map =
          Map<dynamic, dynamic>.from(mapSnap.entries.first.value as dynamic);
      print(mapSnap.entries.first.key);
      return DataResult.deviceSelect(
          cid,
          map['name'],
          map['model'],
          map['version'] ?? '0.00',
          true,
          map['room'] ?? '',
          map['wifi_ssid'] ?? '',
          mapSnap.entries.first.key,
          refreshScreen);
    } else {
      return null;
    }
  }

  refreshScreen() {
    setState(() {});
  }

  ChartSeries getChartDataCo2(DataResult dev, Color c) {
    return LineSeries<deviceData, DateTime>(
      dataSource: indexChart == 0 ? dev.chartDataDay : dev.chartDataWeek,
      name: CO2_String,
      width: 2,
      xValueMapper: (deviceData device, _) => device.dateTime,
      yValueMapper: (deviceData device, _) => device.sensor.co2,
      enableTooltip: true,
      color: c,
    );
  }

  ChartSeries getChartDataTemp(DataResult dev, Color c) {
    return LineSeries<deviceData, DateTime>(
      dataSource: indexChart == 0 ? dev.chartDataDay : dev.chartDataWeek,
      name: loc.main.temperature,
      width: 2,
      xValueMapper: (deviceData device, _) => device.dateTime,
      yValueMapper: (deviceData device, _) => device.sensor.temp,
      enableTooltip: true,
      color: c,
    );
  }

  ChartSeries getChartDataHumi(DataResult dev, Color c) {
    return LineSeries<deviceData, DateTime>(
      dataSource: indexChart == 0 ? dev.chartDataDay : dev.chartDataWeek,
      name: loc.main.humi,
      width: 2,
      xValueMapper: (deviceData device, _) => device.dateTime,
      yValueMapper: (deviceData device, _) => device.sensor.humi,
      enableTooltip: true,
      color: c,
    );
  }

  ChartSeries getChartDataPM(DataResult dev, Color c) {
    return LineSeries<deviceData, DateTime>(
      dataSource: indexChart == 0 ? dev.chartDataDay : dev.chartDataWeek,
      name: PM_String,
      width: 2,
      xValueMapper: (deviceData device, _) => device.dateTime,
      yValueMapper: (deviceData device, _) => device.sensor.pm2_5,
      enableTooltip: true,
      color: c,
    );
  }

  Widget co2_chart(var width, var height, var ts, var tsTime) {
    var cData = List<ChartSeries>.empty(growable: true);
    if (device1 != null) {
      cData.add(getChartDataCo2(device1!, dev1Color));
    }
    if (device2 != null) {
      cData.add(getChartDataCo2(device2!, dev2Color));
    }
    if (device3 != null) {
      cData.add(getChartDataCo2(device3!, dev3Color));
    }
    if (device4 != null) {
      cData.add(getChartDataCo2(device4!, dev4Color));
    }
    return chartShow(
        width, height, '$CO2_String (PPM)', cData, false, ts, tsTime);
  }

  Widget temp_chart(var width, var height, var ts, var tsTime) {
    var cData = List<ChartSeries>.empty(growable: true);
    if (device1 != null) {
      cData.add(getChartDataTemp(device1!, dev1Color));
    }
    if (device2 != null) {
      cData.add(getChartDataTemp(device2!, dev2Color));
    }
    if (device3 != null) {
      cData.add(getChartDataTemp(device3!, dev3Color));
    }
    if (device4 != null) {
      cData.add(getChartDataTemp(device4!, dev4Color));
    }
    return chartShow(width, height, '${loc.main.temperature} (°C)', cData,
        false, ts, tsTime);
  }

  Widget humi_chart(var width, var height, var ts, var tsTime) {
    var cData = List<ChartSeries>.empty(growable: true);
    if (device1 != null) {
      cData.add(getChartDataHumi(device1!, dev1Color));
    }
    if (device2 != null) {
      cData.add(getChartDataHumi(device2!, dev2Color));
    }
    if (device3 != null) {
      cData.add(getChartDataHumi(device3!, dev3Color));
    }
    if (device4 != null) {
      cData.add(getChartDataHumi(device4!, dev4Color));
    }
    return chartShow(
        width, height, '${loc.main.humi} (%)', cData, false, ts, tsTime);
  }

  Widget pm_chart(var width, var height, var ts, var tsTime) {
    var cData = List<ChartSeries>.empty(growable: true);
    if (device1 != null) {
      cData.add(getChartDataHumi(device1!, dev1Color));
    }
    if (device2 != null) {
      cData.add(getChartDataHumi(device2!, dev2Color));
    }
    if (device3 != null) {
      cData.add(getChartDataHumi(device3!, dev3Color));
    }
    if (device4 != null) {
      cData.add(getChartDataHumi(device4!, dev4Color));
    }
    return chartShow(
        width, height, '$PM_String (ug/m³)', cData, false, ts, tsTime);
  }

  Widget getChart(String type) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.biggest.width;
        final height = constraints.biggest.height;
        var ts = TextStyle(
          fontSize: width / 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );
        var tsTime = TextStyle(
          fontSize: width / 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );
        switch (type) {
          case CHART_TEMP:
            return temp_chart(width, height, ts, tsTime);
          case CHART_HUMI:
            return humi_chart(width, height, ts, tsTime);
          case CHART_CO2:
            return co2_chart(width, height, ts, tsTime);
          case CHART_PM:
            return pm_chart(width, height, ts, tsTime);
          default:
            return Container();
        }
      },
    );
  }

  Widget chartShow(var w, var h, var header, var chartData, var isLegend,
      var tsTitle, var tsTime) {
    return Container(
      height: h,
      width: w,
      // color: Colors.white,
      child: SfCartesianChart(
        title: ChartTitle(text: header, textStyle: tsTitle),
        margin: EdgeInsets.only(
            right: h / 10, top: h / 30, bottom: h / 30, left: h / 30),
        // backgroundColor: Colors.white,
        legend: isLegend
            ? Legend(isVisible: true, position: LegendPosition.auto)
            : Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          opacity: 0.5,
          // header: tooltopHeader,
          canShowMarker: false,
        ),
        series: chartData,
        // plotAreaBackgroundColor: Colors.amber,
        plotAreaBorderColor: Colors.transparent,
        primaryXAxis: DateTimeAxis(
          majorGridLines: const MajorGridLines(
            width: 0,
            color: Colors.white,
          ),
          axisLine: const AxisLine(
            color: Colors.white,
            width: 1,
          ),
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: w / 44,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500),
          title: AxisTitle(
              text: indexChart == 0 ? 'Hours' : 'Date', textStyle: tsTime),
          interval: indexChart == 0 ? 2 : 1,
          intervalType: indexChart == 0
              ? DateTimeIntervalType.hours
              : DateTimeIntervalType.days,
          dateFormat: indexChart == 0 ? DateFormat.H() : DateFormat.d(),
        ),
        primaryYAxis: NumericAxis(
          // maximumLabels: 100,
          majorGridLines: const MajorGridLines(
            width: 1,
            color: Colors.white,
          ),
          axisLine: const AxisLine(
            color: Colors.white,
            width: 1,
          ),
          labelStyle: TextStyle(
              color: Colors.white,
              fontSize: w / 44,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget colorIndicator(Color c, var h, var w) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        height: h * sensorTitleFactor,
        width: w * 0.04,
        color: c,
      ),
    );
  }

  Widget showDeviceInfo(deviceData dev, var h, var w) {
    var ts = TextStyle(
      fontSize: h / 24,
      color: textColor,
    );
    var tsTitle = TextStyle(
      fontSize: h / 30,
      color: textColor,
    );
    var tsValue = TextStyle(
      fontSize: h / 36,
      color: textColor,
    );
    return SizedBox(
      height: h,
      width: w,
      child: Column(
        children: [
          sensorTitle(dev, h, w, ts),
          Expanded(child: gaugeTemp(dev, h, w, tsTitle, tsValue)),
          Expanded(child: gaugeHumi(dev, h, w, tsTitle, tsValue)),
          Expanded(child: gaugePm(dev, h, w, tsTitle, tsValue)),
          Expanded(child: gaugeCo2(dev, h, w, tsTitle, tsValue)),
        ],
      ),
    );
  }

  Widget sensorTitle(deviceData dev, var h, var w, var ts) {
    var txtStatus = dev.status ? 'Online' : 'Offline';
    return Container(
      width: w,
      height: h * sensorTitleFactor,
      decoration: BoxDecoration(
          border: Border(
        bottom: BorderSide(width: h * 0.005, color: Colors.white),
      )),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              child: Text(
                // 'Test LongLongLongLongLongLongLongLong Text',
                '${dev.deviceName} ($txtStatus)',
                style: ts,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget gaugeTemp(
      deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
    var isShow = true;
    if(dev.sensor.temp == null){
      isShow = false;
    }
    var gauge = SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          showAxisLine: false,
          showLabels: false,
          minimum: 0,
          maximum: 100,
          startAngle: -220,
          endAngle: 40,
          ranges: <GaugeRange>[
            GaugeRange(
                startValue: 0,
                endValue: 30,
                color: Colors.blue,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 31,
                endValue: 50,
                color: Colors.orange,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 51,
                endValue: 100,
                color: Colors.red,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: dev.sensor.temp,
              needleStartWidth: w / 240,
              needleEndWidth: w / 100,
              needleColor: Colors.white,
            )
          ],
        ),
      ],
    );
    return gaugeShow(dev, h, w, styleTitle, styleValue, gauge,
        "${loc.main.temperature}", "${dev.sensor.temp.toStringAsFixed(0)}°C", isShow);
  }

  Widget gaugeHumi(
      deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
    var isShow = true;
    if(dev.sensor.humi == null){
      isShow = false;
    }
    var gauge = SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          showAxisLine: false,
          showLabels: false,
          minimum: 0,
          maximum: 100,
          startAngle: -220,
          endAngle: 40,
          ranges: <GaugeRange>[
            GaugeRange(
                startValue: 0,
                endValue: 50,
                color: Colors.orangeAccent,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 51,
                endValue: 70,
                color: Colors.greenAccent,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 71,
                endValue: 100,
                color: Colors.blue,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: dev.sensor.humi,
              needleStartWidth: w / 240,
              needleEndWidth: w / 100,
              needleColor: Colors.white,
            )
          ],
        ),
      ],
    );
    return gaugeShow(dev, h, w, styleTitle, styleValue, gauge,
        "${loc.main.humi}", "${dev.sensor.humi.toStringAsFixed(0)}%", isShow);
  }

  Widget gaugePm(deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
    var isShow = true;
    if(dev.sensor.pm2_5 == null){
      isShow = false;
    }
    var gauge = SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          showAxisLine: false,
          showLabels: false,
          minimum: minPM.toDouble(),
          maximum: maxPM.toDouble(),
          startAngle: -220,
          endAngle: 40,
          ranges: <GaugeRange>[
            GaugeRange(
                startValue: 0,
                endValue: 25,
                color: Colors.blue,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 26,
                endValue: 50,
                color: Colors.green,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 51,
                endValue: 100,
                color: Colors.yellow,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 101,
                endValue: 200,
                color: Colors.orange,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 201,
                endValue: 300,
                color: Colors.red,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: dev.sensor.pm2_5.toDouble(),
              needleStartWidth: w / 240,
              needleEndWidth: w / 100,
              needleColor: Colors.white,
            )
          ],
        ),
      ],
    );
    return gaugeShow(dev, h, w, styleTitle, styleValue, gauge, PM_String,
        "${dev.sensor.pm2_5} ug/m³", isShow);
  }

  Widget gaugeCo2(
      deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
    var isShow = true;
    if(dev.sensor.co2 == null || dev.sensor.co2 == 0){
      isShow = false;
    }
    var gauge = SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          showAxisLine: false,
          showLabels: false,
          minimum: minCo2.toDouble(),
          maximum: maxCo2.toDouble(),
          startAngle: -220,
          endAngle: 40,
          ranges: <GaugeRange>[
            GaugeRange(
                startValue: minCo2.toDouble(),
                endValue: 1000,
                color: Colors.green,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 1001,
                endValue: 1500,
                color: Colors.yellow,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 1501,
                endValue: 2000,
                color: Colors.orange,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
            GaugeRange(
                startValue: 2001,
                endValue: maxCo2.toDouble(),
                color: Colors.red,
                endWidth: gaugeWidth,
                startWidth: gaugeWidth),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: dev.sensor.co2.toDouble(),
              needleStartWidth: w / 240,
              needleEndWidth: w / 100,
              needleColor: Colors.white,
            )
          ],
        ),
      ],
    );
    return gaugeShow(dev, h, w, styleTitle, styleValue, gauge, CO2_String,
        "${dev.sensor.co2} PPM", isShow);
  }

  Widget gaugeShow(deviceData dev, var h, var w, var styleTitle, var styleValue,
      var gauge, var title, var value, bool isShow) {
    return Center(
      child: Container(
        padding: EdgeInsets.only(
            top: h / 80, bottom: h / 80, left: h / 80, right: h / 40),
        child: isShow?Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: h / 80),
                child: Center(
                  child: gauge,
                ),
              ),
            ),
            SizedBox(
              width: w / 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    title,
                    style: styleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  Text(
                    value,
                    style: styleValue,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ],
        ):Container(),
      ),
    );
  }

  Widget sensorShow(DataResult? data, Color c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.biggest.width;
        final height = constraints.biggest.height;
        var ts = TextStyle(
          fontSize: height / 16,
          color: textColor,
        );
        return Container(
          color: cardColor,
          child: data != null
              ? Stack(
                  children: [
                    colorIndicator(c, height, width),
                    data.sensorData != null
                        ? showDeviceInfo(data.sensorData!, height, width)
                        : Container(),
                  ],
                )
              : Center(
                  child: Text(
                    "No device",
                    style: ts,
                  ),
                ),
        );
      },
    );
  }

  Widget cardWidget(Widget c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.biggest.width;
        final height = constraints.biggest.height;
        var ts = TextStyle(
          fontSize: height / 16,
          color: textColor,
        );
        return Container(
          padding: EdgeInsets.only(
              top: paddingSize / 2,
              right: paddingSize / 2),
          height: height,
          width: width,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              // borderRadius: BorderRadius.all(Radius.circular(height * 0.1)),
            ),
            child: checkZeroDevice()
                ? c
                : Center(
                    child: Text(
                      "No device",
                      style: ts,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget showTempHumiChart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.biggest.width;
        final h = constraints.biggest.height;
        final height = h / 2;
        var ts = TextStyle(
          fontSize: height / 16,
          color: textColor,
        );
        return Container(
          padding: EdgeInsets.only(left: paddingSize/2),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child: Container(
                  color: cardColor,
                  child: checkZeroDevice()
                      ? getChart(CHART_TEMP)
                      : Center(
                          child: Text(
                            "No device",
                            style: ts,
                          ),
                        ),
                )),
                SizedBox(height: paddingSize),
                Expanded(
                    child: Container(
                  color: cardColor,
                  child: checkZeroDevice()
                      ? getChart(CHART_HUMI)
                      : Center(
                          child: Text(
                            "No device",
                            style: ts,
                          ),
                        ),
                )),
                SizedBox(height: paddingSize),
                Expanded(
                    child: Container(
                  color: cardColor,
                  child: checkZeroDevice()
                      ? getChart(CHART_PM)
                      : Center(
                          child: Text(
                            "No device",
                            style: ts,
                          ),
                        ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  bool checkZeroDevice() {
    return device1 != null ||
        device2 != null ||
        device3 != null ||
        device4 != null;
  }

  @override
  Widget build(BuildContext context) {
    var abh = AppBar().preferredSize.height;
    var h = MediaQuery.of(context).size.height;
    paddingSize = ((h - abh) * mainPaddingSize) / 2;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'images/logoFreshNergy.png',
          height: abh * 0.6,
          fit: BoxFit.fitHeight,
        ),
        backgroundColor: bgColor,
        elevation: 0,
        actions: [getPopup()],
      ),
      body: Container(
        padding: EdgeInsets.all(paddingSize),
        color: bgColor,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final sw = constraints.biggest.width;
                        final sh = constraints.biggest.height;
                        return Container(
                          padding: EdgeInsets.only(bottom: paddingSize / 2, right: paddingSize/2),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: sensorShow(device1, dev1Color)),
                              SizedBox(width: paddingSize),
                              Expanded(child: sensorShow(device2, dev2Color)),
                              SizedBox(width: paddingSize),
                              Expanded(child: sensorShow(device3, dev3Color)),
                              SizedBox(width: paddingSize),
                              Expanded(child: sensorShow(device4, dev4Color)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(child: cardWidget(getChart(CHART_CO2))),
                ],
              ),
            ),
            Expanded(child: showTempHumiChart()),
          ],
        ),
      ),
    );
  }

  Widget getPopup() {
    return PopupMenuButton<SettingMenu>(
      onSelected: (value) {
        switch (value) {
          case SettingMenu.Logout:
            break;
        }
      },
      itemBuilder: (context) => SettingMenu.values
          .map(
            (item) => PopupMenuItem<SettingMenu>(
              child: Text(item.name),
              value: item,
            ),
          )
          .toList(),
      icon: const Icon(
        Icons.more_vert,
        // color: Colors.black,
      ),
    );
  }
}

enum SettingMenu {
  Logout,
}
