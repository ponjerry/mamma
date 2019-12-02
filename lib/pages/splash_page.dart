import 'package:flutter/material.dart';
import 'package:mamma/enums/route_type.dart';
import 'base_page_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends BasePageState<SplashPage> {
  @override
  String get title => 'Splash page';

  @override
  void onPostLoad() {
    gotoPage(RouteType.voiceCheckPage);
    return super.onPostLoad();
  }

  @override
  Widget buildContents(BuildContext context) {
    return SafeArea(
      child: Container(
        child: ListView(
          children: List.generate(100, (value) => Text('Value: $value')),
        ),
      ),
    );
  }
}
