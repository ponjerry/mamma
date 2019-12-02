import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mamma/channel/sound_channel.dart';
import 'package:mamma/pages/base_page_state.dart';

class VoiceCheckPage extends StatefulWidget {
  const VoiceCheckPage();

  @override
  _VoiceCheckPageState createState() => _VoiceCheckPageState();
}

class _VoiceCheckPageState extends BasePageState<VoiceCheckPage> {
  @override
  String get title => 'Voice check';

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
    _speakingSubscription =
        SoundChannel().speakingStateStream.listen((speaking) {
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
  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      FlatButton(
        child: Text(
          'clear',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: _clear,
      )
    ];
  }

  @override
  Widget buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: _isRecording ? Colors.red : Colors.grey,
      onPressed: _record,
      tooltip: 'Record',
      child: Icon(Icons.record_voice_over),
    );
  }

  @override
  Widget buildContents(BuildContext context) {
    return Padding(
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
    );
  }
}
