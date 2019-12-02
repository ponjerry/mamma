import 'package:flutter/material.dart';
import 'package:mamma/enums/route_type.dart';
import 'package:mamma/pages/splash_page.dart';
import 'package:mamma/pages/voice_check_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamma',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: <RouteType, WidgetBuilder>{
        RouteType.splashPage: (context) => const SplashPage(),
        RouteType.voiceCheckPage: (context) => const VoiceCheckPage(),
      }.map((routeType, page) => MapEntry(toRouteName(routeType), page)),
      home: const SplashPage(),
    );
  }
}
