import 'package:flutter/material.dart';
import 'home.dart';

main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TfLite SSD Mobilenet',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(),
    );
  }
}
