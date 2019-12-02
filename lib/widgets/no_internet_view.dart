import 'package:flutter/material.dart';

class NoInternetView extends StatelessWidget {
  final VoidCallback onRetryPressed;

  const NoInternetView({
    Key key,
    @required this.onRetryPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '네트워크 연결 상태가 좋지 않습니다.',
            style: Theme.of(context).textTheme.subhead,
            textAlign: TextAlign.center,
          ),
          Text(
            '네트워크 연결 상태 확인 후, 다시 시도해주세요.',
            style: Theme.of(context).textTheme.subtitle,
            textAlign: TextAlign.center,
          ),
          Container(
            padding: const EdgeInsets.only(top: 20.0),
            width: 120.0,
            child: RaisedButton(
              child: Text(
                '새로고침',
                style: Theme.of(context).textTheme.button,
              ),
              onPressed: onRetryPressed,
            ),
          ),
        ],
      ),
    );
  }
}
