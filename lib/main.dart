import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mamma/channel/sound_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // TODO(wonjerry): Add speaking start, stop log
  List<String> _logs = [];
  bool _isRecording = false;
  StreamSubscription _speakingSubscription;

  void _clear() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _record() async {
    await SoundChannel.record(!_isRecording);
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  @override
  void initState() {
    super.initState();
    _speakingSubscription = SoundChannel().speakingStateStream.listen((speaking) {
      setState(() {
        _logs.add(speaking ? '말하는중...' : '!!!!!!!!!!끝!!!!!!!!!!');
      });
    });
  }

  @override
  void dispose() {
    _speakingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'clear',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _clear,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (BuildContext context, int index) {
            return Text(
              _logs[index],
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isRecording ? Colors.red : Colors.grey,
        onPressed: _record,
        tooltip: 'Record',
        child: Icon(Icons.record_voice_over),
      ),
    );
  }
}
