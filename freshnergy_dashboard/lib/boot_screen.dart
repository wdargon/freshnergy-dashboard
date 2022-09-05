import 'package:flutter/material.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({ Key? key }) : super(key: key);

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Text("Test"),
    );
  }
}