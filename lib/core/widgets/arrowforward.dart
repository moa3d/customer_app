import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final void Function() onPressed;
  final Color? color;
  final bool isForward;

  const ActionButton({
    super.key,
    required this.onPressed,
    this.color,
    this.isForward = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    IconData iconData;
    // In RTL, 'forward' is left and 'back' is right.
    if (isForward) {
      iconData = isRtl ? Icons.arrow_back : Icons.arrow_forward;
    } else {
      iconData = isRtl ? Icons.arrow_forward : Icons.arrow_back;
    }

    return Padding(
      // Use directional padding
      padding: const EdgeInsetsDirectional.only(end: 8.0),
      child: Container(
        decoration: BoxDecoration(
          // Use a theme-aware default color
          color: color ?? theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        width: 40,
        height: 40,
        child: IconButton(
          // Use a theme-aware icon color
          color: theme.iconTheme.color,
          onPressed: onPressed,
          icon: Icon(iconData),
        ),
      ),
    );
  }
}
