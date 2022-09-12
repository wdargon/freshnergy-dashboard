import 'dart:async';
import 'dart:convert';

import 'package:clay_containers/clay_containers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

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
  late StreamSubscription<DatabaseEvent> _device1Subscription;
  late StreamSubscription<DatabaseEvent> _device2Subscription;
  late StreamSubscription<DatabaseEvent> _device3Subscription;
  late StreamSubscription<DatabaseEvent> _device4Subscription;
  FirebaseException? _dev1Error;
  FirebaseException? _dev2Error;
  FirebaseException? _dev3Error;
  FirebaseException? _dev4Error;
  deviceData? _dev1Data;
  deviceData? _dev2Data;
  deviceData? _dev3Data;
  deviceData? _dev4Data;

  var mainSizeFactor = 0.96;
  var sensorTitleFactor = 0.10;

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
  }

  @override
  void dispose() {
    super.dispose();
    _device1Subscription.cancel();
    _device2Subscription.cancel();
    _device3Subscription.cancel();
    _device4Subscription.cancel();
  }

  initPageData() async {
    const cid = '10521C838958';
    _dev1Data = await getDeviceData(cid);
    if (_dev1Data != null) await subscripDevice1(cid);
  }

  Future<deviceData?> getDeviceData(String cid) async {
    deviceData? d = deviceData.init();
    var event = await FirebaseDatabase.instance
        .ref('user')
        .orderByChild('cid')
        .equalTo(cid)
        .once();
    if (event.snapshot.value != null) {
      var mapSnap = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
      print(event.snapshot.value);
      print(mapSnap.entries.first.value);
      var map =
          Map<dynamic, dynamic>.from(mapSnap.entries.first.value as dynamic);
      var a = map.entries.first;
      d.deviceName = map['name'];
      d.deviceModel = map['model'];
      d.room = map['room'] ?? '';
      d.version = map['version'] ?? '0.00';
      d.wifiSSID = map['wifi_ssid'] ?? '';
      if (map['location'] != null) {
        d.location = locationData.fromMap(map['location']);
      }
      return d;
    } else {
      return null;
    }
  }

  subscripDevice1(String cid) async {
    var _dev = FirebaseDatabase.instance.ref('data/$cid/realtime');
    await _dev.get().then((value) {
      print(value.value);
    });

    _device1Subscription = _dev.onValue.listen(
      (DatabaseEvent event) {
        setState(() {
          _dev1Error = null;
          var values = event.snapshot.value;
          var map = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
          var tmpDev = deviceData.fromMap(map);
          tmpDev.wifiSSID = _dev1Data!.wifiSSID;
          tmpDev.location = _dev1Data!.location;
          tmpDev.cid = cid;
          tmpDev.room = _dev1Data!.room;
          tmpDev.deviceModel = _dev1Data!.deviceModel;
          tmpDev.deviceName = _dev1Data!.deviceName;
          tmpDev.version = _dev1Data!.version;
          _dev1Data = tmpDev;
          // print(dev!.sensor.temp);
        });
      },
      onError: (Object o) {
        final error = o as FirebaseException;
        setState(() {
          _dev1Error = error;
        });
      },
    );
  }

  Widget colorIndicator(Color c, var h, var w) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        height: h * sensorTitleFactor,
        width: w * 0.01,
        color: c,
      ),
    );
  }

  Widget showDeviceInfo(deviceData dev, var h, var w) {
    var ts = TextStyle(
      fontSize: h / 22,
      color: textColor,
    );
    var tsTitle = TextStyle(
      fontSize: h / 28,
      color: textColor,
    );
    var tsValue = TextStyle(
      fontSize: h / 32,
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
        "${loc.main.temperature}", "${dev.sensor.temp.toStringAsFixed(0)}°C");
  }

  Widget gaugeHumi(
      deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
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
        "${loc.main.humi}", "${dev.sensor.humi.toStringAsFixed(0)}%");
  }

  Widget gaugePm(deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
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
    return gaugeShow(dev, h, w, styleTitle, styleValue, gauge, "PM2.5",
        "${dev.sensor.pm2_5} ug/m³");
  }

  Widget gaugeCo2(
      deviceData dev, var h, var w, var styleTitle, var styleValue) {
    var gaugeWidth = h / 70;
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
    return gaugeShow(dev, h, w, styleTitle, styleValue, gauge, "CO₂",
        "${dev.sensor.co2} PPM");
  }

  Widget gaugeShow(deviceData dev, var h, var w, var styleTitle, var styleValue,
      var gauge, var title, var value) {
    return Center(
      child: Container(
        padding: EdgeInsets.only(
            top: h / 80, bottom: h / 80, left: h / 80, right: h / 40),
        child: Row(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sensorShow(deviceData? data, Color c) {
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
                    showDeviceInfo(data, height, width),
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
        return Container(
          height: height,
          width: width,
          child: Center(
            child: Container(
              height: height * mainSizeFactor,
              width: width * mainSizeFactor,
              decoration: BoxDecoration(
                color: cardColor,
                // borderRadius: BorderRadius.all(Radius.circular(height * 0.1)),
              ),
              child: c,
            ),
          ),
        );
      },
    );
  }

  Widget cardSensor(Widget c, int position) {
    late var al;
    switch (position) {
      case 1:
        al = Alignment.topLeft;
        break;
      case 2:
        al = Alignment.topRight;
        break;
      case 3:
        al = Alignment.bottomLeft;
        break;
      case 4:
        al = Alignment.bottomRight;
        break;
      default:
        al = Alignment.topCenter;
        break;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.biggest.width;
        final height = constraints.biggest.height;
        return Container(
          height: height,
          width: width,
          child: Stack(
            children: [
              Align(
                alignment: al,
                child: Container(
                  height: height * mainSizeFactor,
                  width: width * mainSizeFactor,
                  decoration: BoxDecoration(
                    color: cardColor,
                    // borderRadius: BorderRadius.all(Radius.circular(height * 0.1)),
                  ),
                  child: c,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var abh = AppBar().preferredSize.height;
    var h = MediaQuery.of(context).size.height;
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
        padding: EdgeInsets.all(h * 0.01),
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final sw = constraints.biggest.width;
                        final sh = constraints.biggest.height;
                        return Center(
                          child: Container(
                            height: sh * mainSizeFactor,
                            width: sw * mainSizeFactor,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                    child: sensorShow(_dev1Data, dev1Color)),
                                SizedBox(width: sw - (sw * mainSizeFactor)),
                                Expanded(
                                    child: sensorShow(_dev2Data, dev2Color)),
                                SizedBox(width: sw - (sw * mainSizeFactor)),
                                Expanded(
                                    child: sensorShow(_dev3Data, dev3Color)),
                                SizedBox(width: sw - (sw * mainSizeFactor)),
                                Expanded(
                                    child: sensorShow(_dev4Data, dev4Color)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(child: cardWidget(Container())),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cardWidget(Container())),
                  Expanded(child: cardWidget(Container())),
                ],
              ),
            ),
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
