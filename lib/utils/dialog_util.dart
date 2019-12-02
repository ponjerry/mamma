import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'common_util.dart';
import 'dialog_item.dart';

typedef InputDialogCallback = Function(String newValue);

class DialogUtil {
  final BuildContext context;

  DialogUtil._(this.context);

  factory DialogUtil.of(BuildContext context) {
    return DialogUtil._(context);
  }

  AlertDialog buildDialog({
    String title,
    Widget content,
    String leftTitle,
    String rightTitle,
    VoidCallback leftCallback,
    VoidCallback rightCallback,
  }) {
    return AlertDialog(
      title: let(title, (text) {
        return Text(title, style: Theme.of(context).textTheme.title);
      }),
      content: content,
      actions: <Widget>[
        if (leftTitle != null) ...[
          FlatButton(
            textColor: Theme.of(context).disabledColor,
            onPressed: () {
              if (leftCallback != null) {
                leftCallback();
              }
            },
            child: Text(leftTitle),
          )
        ],
        if (rightTitle != null) ...[
          FlatButton(
            textColor: Theme.of(context).buttonColor,
            onPressed: () {
              if (rightCallback != null) {
                rightCallback();
              }
            },
            child: Text(rightTitle),
          )
        ],
      ],
    );
  }

  Dialog buildLoadingDialog({Widget child}) {
    return Dialog(
      child: Container(
        width: 280.0,
        height: 86.0,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
              ),
              width: 25.0,
              height: 25.0,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> showMessageDialog({
    bool barrierDismissible = true,
    String title,
    String message,
    String leftTitle = '취소',
    String rightTitle = '확인',
  }) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        Widget current = buildDialog(
          title: title,
          content: let(message, (text) {
            return Text(message, style: Theme.of(context).textTheme.body1);
          }),
          leftTitle: leftTitle,
          rightTitle: rightTitle,
          leftCallback: () => Navigator.of(context).pop(false),
          rightCallback: () => Navigator.of(context).pop(true),
        );
        if (!barrierDismissible) {
          current = WillPopScope(
            onWillPop: () async => false,
            child: current,
          );
        }
        return current;
      },
    );
    return result ?? false;
  }

  Future<void> showErrorDialog({
    String title,
    String message,
    String rightTitle = '확인',
  }) async {
    await showMessageDialog(
      barrierDismissible: false,
      title: title,
      message: message,
      leftTitle: null,
      rightTitle: rightTitle,
    );
  }

  // TODO(hyungsun): Implement show input dialog

  Widget _buildListItem<T>(DialogItem<T> item) {
    return Container(
      color: Theme.of(context).cardColor,
      child: FlatButton(
        child: SizedBox(
          width: double.infinity,
          child: Text(
            item.displayName,
            style: Theme.of(context).textTheme.subhead,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(item.value),
      ),
    );
  }

  Future<T> showListDialog<T>({
    String title,
    List<DialogItem<T>> list = const [],
  }) {
    assert(list != null);
    final titleWidget = let(title, (text) {
      return Text(title, style: Theme.of(context).textTheme.headline);
    });
    final actions = list.map((item) => _buildListItem(item)).toList();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return showCupertinoModalPopup(
        context: context,
        builder: (_) =>
            CupertinoActionSheet(title: titleWidget, actions: actions),
      );
    } else {
      return showDialog(
        context: context,
        builder: (_) => SimpleDialog(title: titleWidget, children: actions),
      );
    }
  }

  Future<String> showSimpleListDialog({
    String title,
    List<String> list = const [],
  }) {
    return showListDialog(
      title: title,
      list: list.map((value) => DialogItem(value, value)).toList(),
    );
  }
}
