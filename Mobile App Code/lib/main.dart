import 'package:flutter/material.dart';
import 'package:ioteggincubatorapp/mqtt.dart';
import 'package:ioteggincubatorapp/onboarding.dart';

void main() {
//  Mqttwrapper().initializemqtt();
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
  MyApp({Key key, this.title}) : super(key: key);
  final String title;
  _AppState createState() => _AppState();
}
class _AppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Automatic Egg Incubator',
      theme: ThemeData(
        primaryColor: Colors.brown,
        fontFamily: 'Montserrat',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
      Onboarding(),
    );
  }
}


