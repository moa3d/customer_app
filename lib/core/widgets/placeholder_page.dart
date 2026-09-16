import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'arrowforward.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ActionButton(onPressed: () => context.pop()),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              "coming_soon".tr(),
              style: theme.textTheme.titleLarge?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
