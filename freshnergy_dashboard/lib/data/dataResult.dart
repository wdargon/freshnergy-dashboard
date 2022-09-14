import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'dataClass.dart';

class DataResult {
  List<deviceData> chartDataDay = List<deviceData>.empty(growable: true);
  List<deviceData> chartDataWeek = List<deviceData>.empty(growable: true);

  late String name;
  late String version;
  late String model;
  late String cid;
  late String room;
  late locationData location;
  late String wifiSSID;
  late bool isOnline;
  late String keyPath;

  late bool dataLoaded = false;
  late bool hadAQI = true;

  late int aqi;

  deviceData? sensorData;
  late StreamSubscription<DatabaseEvent> dataSub;
  late StreamSubscription<DatabaseEvent> infoSub;
  late StreamSubscription<DatabaseEvent> chartSub;

  late VoidCallback callback; // Notice the variable type
  bool firstInit = true;

  DataResult(
      this.cid,
      this.version,
      this.model,
      this.name,
      this.dataLoaded,
      this.isOnline,
      this.room,
      this.callback);

  DataResult.deviceSelect(
      String c, String n, String m, String v, bool owner, String r, String wifi, String k, var cb) {
    name = n;
    cid = c;
    model = m;
    version = v;
    room = r;
    wifiSSID = wifi;
    callback = cb;
    keyPath = k;
    subscripData();
    subscripinfo();
    subscripChart();
  }

  int aqi_cal(var imin, var imax, var cmin, var cmax, var cal_data) {
    var a = imax - imin;
    var b = cmax - cmin;
    var c = cal_data - cmin;
    return (((a / b) * c) + imin).toInt();
  }

  int pm2aqi_cal() {
    var tmp_aqi;
    var dat = sensorData?.sensor.pm2_5;
    if (dat <= 25) {
      tmp_aqi = aqi_cal(0, 25, 0, 25, dat);
    } else if (dat <= 37) {
      tmp_aqi = aqi_cal(26, 50, 26, 37, dat);
    } else if (dat <= 50) {
      tmp_aqi = aqi_cal(51, 100, 38, 50, dat);
    } else if (dat <= 90) {
      tmp_aqi = aqi_cal(101, 200, 51, 90, dat);
    } else {
      tmp_aqi = dat + 110;
    }
    return tmp_aqi.toInt();
  }

  int pm10aqi_cal() {
    var tmp_aqi;
    var dat = sensorData?.sensor.pm10;
    if (dat <= 50) {
      tmp_aqi = aqi_cal(0, 25, 0, 50, dat);
    } else if (dat <= 80) {
      tmp_aqi = aqi_cal(26, 50, 51, 80, dat);
    } else if (dat <= 120) {
      tmp_aqi = aqi_cal(51, 100, 81, 120, dat);
    } else if (dat <= 180) {
      tmp_aqi = aqi_cal(101, 200, 121, 180, dat);
    } else {
      tmp_aqi = (dat / 2) + 111;
    }
    return tmp_aqi.toInt();
  }

  calculateAQI() {
    var pm2aqi, pm10aqi;
    if(sensorData?.sensor.pm2_5 != null){
      pm2aqi = pm2aqi_cal();
    }
    if(sensorData?.sensor.pm10 != null){
      pm10aqi = pm10aqi_cal();
    }
    print('pm2aqi = $pm2aqi');
    print('pm10aqi = $pm10aqi');
    if(pm2aqi != null || pm10aqi != null){
      aqi = pm2aqi > pm10aqi ? pm2aqi : pm10aqi;
      hadAQI = true;
    }else{
      hadAQI = false;
    }
  }

  subscripData() async {
    var _dev = FirebaseDatabase.instance.ref('data/$cid/realtime');
    await _dev.get().then((value) {
      print(value.value);
    });

    dataSub = _dev.onValue.listen(
      (DatabaseEvent event) {
        // setState(() {
          // _dev1Error = null;
          var values = event.snapshot.value;
          var map = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
          var tmpDev = deviceData.fromMap(map);
          tmpDev.wifiSSID = wifiSSID;
          tmpDev.cid = cid;
          tmpDev.room = room;
          tmpDev.deviceModel = model;
          tmpDev.deviceName = name;
          tmpDev.version = version.toString();
          sensorData = tmpDev;
          calculateAQI();
          callback();
          // print(dev!.sensor.temp);
        // });
      },
      onError: (Object o) {
        final error = o as FirebaseException;
        // setState(() {
        //   _dev1Error = error;
        // });
      },
    );
  }

  subscripinfo() async {
    var _dev = FirebaseDatabase.instance.ref('user/$keyPath');
    await _dev.get().then((value) {
      print(value.value);
    });

    chartSub = _dev.onValue.listen(
      (DatabaseEvent event) {
          var values = event.snapshot.value;
          var map = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
          name = map['name'];
          model = map['model'];
          version = map['version'] ?? '0.00';
          room = map['room'] ?? '';
          wifiSSID = map['wifi_ssid'] ?? '';
          callback();
      },
      onError: (Object o) {
        final error = o as FirebaseException;
      },
    );
  }

  subscripChart() async {
    var _dev = FirebaseDatabase.instance.ref('data/$cid/data');
    await _dev.get().then((value) {
      print(value.value);
    });

    // _dev.onChildAdded.listen((event) { })
    infoSub = _dev.limitToLast(1).onChildAdded.listen(
      (DatabaseEvent event) {
          var values = event.snapshot.value;
          var map = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
          deviceData tempData = deviceData.fromMapChart(map);
          if(firstInit){
            firstInit = false;
          }else{
            if(tempData.sensor != null){
              print(tempData.sensor);
              var timeNow = DateTime.now();
              var hrNow = timeNow.hour;
              var dayNow = timeNow.day;
              if(chartDataDay[0].dateTime.day < dayNow-1){
                  chartDataDay.removeAt(0);
              }else if(chartDataDay[0].dateTime.day == dayNow-1){
                if(hrNow >= chartDataDay[0].dateTime.hour){
                  chartDataDay.removeAt(0);
                }
              }
              chartDataDay.add(tempData);
              callback();
            }
          }
          // name = map['name'];
          // model = map['model'];
          // version = map['version'] ?? '0.00';
          // room = map['room'] ?? '';
          // wifiSSID = map['wifi_ssid'] ?? '';
          // callback();
      },
      onError: (Object o) {
        final error = o as FirebaseException;
      },
    );
  }

  cancelSub(){
    dataSub.cancel();
    chartSub.cancel();
    infoSub.cancel();
  }

  proofChart(){
    var dt24hr = DateTime.now().add(const Duration(days: -1));
    var dataSize = chartDataDay.length;
    int? lastIndexDelete;
    for(var i=0;i<dataSize;i++){
      var st = chartDataDay[i].dateTime.isBefore(dt24hr);
      if(st){
        lastIndexDelete=i;
      }
    }
    if(lastIndexDelete!=null){
      chartDataDay.removeRange(0, lastIndexDelete+1);
    }
  }

  checkOnline(){
    int time = DateTime.now().millisecondsSinceEpoch;
    // status = false;
    if(sensorData != null){
      if (time - sensorData!.timeStamp > 16 * 60 * 1000) {
        sensorData!.status = false;
      } else {
        sensorData!.status = true;
      }
    }
      if(sensorData!=null && !sensorData!.status){
        proofChart();
      }
  }

  Future<bool> getChartDataDay() async {
    final firebaseData = FirebaseDatabase.instance.ref();
    List<deviceData> tmpList = List<deviceData>.empty(growable: true);
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int last24h = (currentTime ~/ 1000) - (24 * 60 * 60);
    print('get data for chart');
    var status = false;
    await firebaseData
        .child('data')
        .child(cid)
        .child('data')
        .orderByChild('timeStamp')
        .startAt(last24h)
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        var mapSnap = Map<dynamic, dynamic>.from(event.snapshot.value as dynamic);
        mapSnap.forEach((k, v) {
          deviceData tempData = deviceData.fromMapChart(v);
          if(tempData.sensor != null) tmpList.add(tempData);
        });
        tmpList.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
        chartDataDay = tmpList;
        print('map all result data');
        status = true;
      } else {
        print('chart data null');
        status = false;
      }
      return status;
    });
    return status;
  }

  // Future<bool> getChartDataWeek() async {
  //   final firebaseData = FirebaseDatabase.instance.reference();
  //   List<deviceData> tmpList = List<deviceData>();
  //   int currentTime = DateTime.now().millisecondsSinceEpoch;
  //   int lastWeek = (currentTime ~/ 1000) - (7 * 24 * 60 * 60);
  //   print('get data for chart');
  //   var status = false;
  //   await firebaseData
  //       .child('data')
  //       .child(this.cid)
  //       .child('data')
  //       .orderByChild('timeStamp')
  //       .startAt(lastWeek)
  //       .once()
  //       .then((DataSnapshot data) {
  //     if (data.value != null) {
  //       Map<dynamic, dynamic> values = data.value;
  //       values.forEach((k, v) {
  //         deviceData tempData = deviceData.fromMapChart(v);
  //         if(tempData.sensor != null) tmpList.add(tempData);
  //       });
  //       tmpList.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));
  //       chartDataWeek = tmpList;
  //       print('map all result data');
  //       status = true;
  //     }else{
  //       print('chart data null');
  //       status = false;
  //     }
  //   });
  //   return status;
  // }
}