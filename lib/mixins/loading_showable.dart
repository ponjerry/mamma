import 'package:flutter/material.dart';
import 'package:mamma/utils/app_util.dart';
import 'package:mamma/utils/dialog_util.dart';
import 'package:mamma/utils/exception_util.dart';

typedef LoadingHandler<T> = Future<T> Function();
typedef ErrorHandler = Future<void> Function(
    BuildContext context, dynamic error, StackTrace stackTrace);

mixin LoadingShowable<T extends StatefulWidget> on State<T> {
  /// Show loading dialog with title.
  ///
  /// Usage:
  ///
  /// final value = await showLoading(
  ///   title: 'title',
  ///   callback: () async {
  ///     final value = await doSomeAsync();
  ///     return value;
  ///   },
  ///   errorHandler: () async {}
  /// );
  Future<T> showLoading<T>({
    @required String title,
    @required LoadingHandler<T> handler,
    ErrorHandler errorHandler,
  }) async {
    return await showLoadingForFuture(
        title: title,
        future: handler(),
        errorHandler: errorHandler ?? defaultErrorHandler);
  }

  Future<T> showLoadingForFuture<T>({
    @required String title,
    @required Future<T> future,
    ErrorHandler errorHandler,
  }) async {
    errorHandler ??= defaultErrorHandler;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: DialogUtil.of(context).buildLoadingDialog(
            child: Text(title),
          ),
        );
      },
    );

    try {
      final ret = await future;
      // Pop the loading dialog after running handler.
      Navigator.of(context).pop();
      return ret;
    } catch (error, stackTrace) {
      // Pop the loading dialog first.
      Navigator.of(context).pop();
      if (errorHandler != null) {
        try {
          await errorHandler(context, error, stackTrace);
        } catch (error2) {
          // Error propagation fallback
          await defaultErrorHandler(context, error, stackTrace);
        }
      } else {
        await defaultErrorHandler(context, error, stackTrace);
      }
      return null;
    }
  }

  Future<void> defaultErrorHandler(
      BuildContext context, dynamic error, StackTrace stackTrace) async {
    final errorMessage = extractErrorMessage(error);
    if (isInDebugMode) {
      print(error);
      print(stackTrace);
    } else {
      // TODO(hyungsun): Report it
    }
    await DialogUtil.of(context).showMessageDialog(
      title: '오류',
      message: errorMessage,
      leftTitle: null,
    );
  }
}
