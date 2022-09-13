

var maxPM = 300;
var minPM = 0;

var minCo2 = 400;
var maxCo2 = 5000;

class deviceData {
  late String deviceName;
  late String deviceModel;
  late String version;
  late String cid;
  late String switchCode;
  late String room;
  late int timeStamp;
  late DateTime dateTime;
  late bool status;
  late bool isOwner;
  late locationData location;
  late String wifiSSID;
  late var sensor;
  late var board;
  late var loc;

  deviceData(
      this.deviceName,
      this.cid,
      this.switchCode,
      this.room,
      this.timeStamp,
      this.sensor,
      this.board,
      this.status,
      this.loc,
      this.isOwner,
      this.location,
      this.deviceModel,
      this.version);

  deviceData.fromMap(Map<dynamic, dynamic> map) {
    if (map['cid'] != null) cid = map['cid'].toString();
    if (map['version'] != null) {
      version = map['version'].toString();
    } else {
      version = '0.00';
    }
    if (map['wifi_ssid'] != null) wifiSSID = map['wifi_ssid'].toString();
    if (map['timeStamp'] != null) timeStamp = (map['timeStamp'].toInt()) * 1000;
    if (map['sensor'] != null) sensor = sensorData.fromMap(map['sensor']);
    if (map['board'] != null) board = boardData.fromMap(map['board']);
    if (map['switch_code']!=null) {
      switchCode=map['switch_code'].toString();
    } else {
      switchCode='';
    }
    if (map['room']!=null) {
      room = map['room'].toString();
    } else {
      room='';
    }
    if (map['location'] != null) {
      location = locationData.fromMap(map['location']);
    }
    var _tmpLoc = map['location'];
    if (_tmpLoc != null) {
      loc = locationData.fromMap(map['location']);
    } else {
      loc = locationData.init();
    }

    int time = DateTime.now().millisecondsSinceEpoch;
    // status = false;
    if (time - timeStamp > 16 * 60 * 1000) {
      status = false;
    } else {
      status = true;
    }
  }

  deviceData.fromMapChart(Map<dynamic, dynamic> map){
    // if (map['cid'] != null) cid = map['cid'].toString();
    if (map['timeStamp'] != null) timeStamp = (map['timeStamp'].toInt()) * 1000;
    if (map['sensor'] != null) sensor = sensorData.fromMap(map['sensor']);
    // else sensor = sensorData.init();
    if (map['board'] != null) board = boardData.fromMap(map['board']);

    var hr = timeStamp % 3600000;
    timeStamp = timeStamp - hr;
    dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp, isUtc: false);
    // print(dateTime.hour);
  }

  deviceData.init() {
    cid = '';
    timeStamp = 0;
    status = false;
    sensor = sensorData.init();
    board = boardData.init();
    wifiSSID = '';
  }

  deviceData.fromTime(var timeStamp) {
    cid = '';
    wifiSSID = '';
    timeStamp = timeStamp * 1000;
    int time = DateTime.now().millisecondsSinceEpoch;
    if (time - timeStamp > 11 * 60 * 1000) {
      status = false;
    } else {
      status = true;
    }
    sensor = sensorData.init();
    board = boardData.init();
    location = locationData.init();
  }

  checkStatus(var timeStamp) {
    timeStamp = timeStamp * 1000;
    int time = DateTime.now().millisecondsSinceEpoch;
    if (time - timeStamp > 11 * 60 * 1000) {
      status = false;
    } else {
      status = true;
    }
  }

  importBoard(var board) {
    board = boardData.fromMap(board);
  }
}

class sensorData {
  double? temp;
  double? humi;
  int? pm1;
  int? pm2_5;
  int? pm4;
  int? pm10;
  int? co2;
  int? eco2;
  double? tvoc;

  sensorData(this.temp, this.humi, this.pm1, this.pm2_5, this.pm4, this.pm10,
      this.co2);

  sensorData.fromMap(Map<dynamic, dynamic> map) {
    if (map['temp'] != null) {
      temp = checkRange(max: 99, min: 0, data: map['temp'].toDouble());
    }else{
      temp = null;
    }
    if (map['humi'] != null) {
      humi = checkRange(max: 99, min: 0, data: map['humi'].toDouble());
    }else{
      humi = null;
    }
    if (map['pm1'] != null) {
      pm1 = checkRangeInt(data: map['pm1'].toInt(), max: maxPM, min: minPM);
    }else{
      pm1 = null;
    }
    if (map['pm2_5'] != null) {
      pm2_5 = checkRangeInt(data: map['pm2_5'].toInt(), max: maxPM, min: minPM);
    }else{
      pm2_5 = null;
    }
    if (map['pm4'] != null) {
      pm4 = checkRangeInt(data: map['pm4'].toInt(), max: maxPM, min: minPM);
    }else{
      pm4 = null;
    }
    if (map['pm10'] != null) {
      pm10 = checkRangeInt(data: map['pm10'].toInt(), max: maxPM, min: minPM);
    }else{
      pm10 = null;
    }
    if (map['co2'] != null) {
      co2 = checkRangeInt(data: map['co2'].toInt(), max: maxCo2, min: minCo2);
    }else{
      co2 = null;
    }
    if (map['eco2'] != null) {
      eco2 = checkRangeInt(data: map['eco2'].toInt(), max: maxCo2, min: minCo2);
    }else{
      eco2 = null;
    }
    if (map['tvoc'] != null) {
      tvoc = checkRange(max: 65, min: 0, data: map['tvoc'].toDouble());
    }else{
      tvoc = null;
    }
  }

  sensorData.init() {
    temp = 0;
    humi = 0;
    pm1 = 0;
    pm2_5 = 0;
    pm4 = 0;
    pm10 = 0;
    co2 = 0;
    eco2 = 0;
    tvoc = 0;
  }
}

double checkRange({double max = 100, double min = 0, required double data}) {
  if (data >= max)
    data = max;
  else if (data <= min) data = min;

  return data;
}

int checkRangeInt({int max = 100, int min = 0, required int data}) {
  if (data >= max)
    data = max;
  else if (data <= min) data = min;

  return data;
}

class boardData {
  late double vbat;
  late double vbus;
  late double cpu_temp;
  late double rssi;
  late int filter;

  boardData(
    this.vbat,
    this.vbus,
    this.cpu_temp,
    this.rssi,
    this.filter,
  );

  boardData.fromMap(Map<dynamic, dynamic> map) {
    if (map['vbat'] != null) vbat = map['vbat'].toDouble();
    if (map['vbus'] != null) vbus = map['vbus'].toDouble();
    if (map['cpu_temp'] != null) cpu_temp = map['cpu_temp'].toDouble();
    if (map['rssi'] != null) rssi = map['rssi'].toDouble();
    if (map['filter'] != null) filter = map['filter'].toInt();
  }

  boardData.init() {
    vbat = 0;
    vbus = 0;
    cpu_temp = 0;
    rssi = 0;
    filter = 0;
  }
}

class locationData {
  late double lat;
  late double long;

  locationData(this.lat, this.long);

  locationData.fromMap(Map<dynamic, dynamic> map) {
    lat = map['lat'].toDouble();
    long = map['long'].toDouble();
  }

  locationData.init() {
    lat = 0;
    long = 0;
  }
}
