import 'package:flutter/material.dart';

/// This file is copied from the [CloseButtonIcon] class.
///
/// Please refer the original file before changing it.
class CustomCloseButton extends StatelessWidget {
  const CustomCloseButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const Icon(Icons.close),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () {
        Navigator.maybePop(context);
      },
    );
  }
}
