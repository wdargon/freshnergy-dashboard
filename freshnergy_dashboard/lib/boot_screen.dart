import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({Key? key}) : super(key: key);

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    var deviceData = <String, dynamic>{};

    try {
      if (kIsWeb) {
        // deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      } else {
        if (Platform.isAndroid) {
          deviceData =
              _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        }
        // else if (Platform.isIOS) {
        //   deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        // } else if (Platform.isLinux) {
        //   deviceData = _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
        // } else if (Platform.isMacOS) {
        //   deviceData = _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
        // } else if (Platform.isWindows) {
        //   deviceData =
        //       _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
        // }
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
    };
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned(
              top: h / 10,
              child: Image.asset(
                'images/logoFreshNergy.png',
                height: h / 10,
                width: w,
                fit: BoxFit.fitHeight,
              ),
            ),
            Positioned(
              top: h / 4,
              left: (w - (h / 2)) / 2,
              child: Container(
                width: h / 2,
                height: h / 2,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(h / 24))),
                child: Center(
                  child: QrImage(
                    data: "123456789",
                    size: h / 2.2,
                    backgroundColor: Colors.white,
                    embeddedImage:
                        const AssetImage('images/freshnergy_logo.png'),
                    embeddedImageStyle:
                        QrEmbeddedImageStyle(size: Size(h / 15, h / 15)),
                    semanticsLabel: "Freshnergy",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
