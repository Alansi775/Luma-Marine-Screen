import 'package:flutter/material.dart';

/// A chromeless full-bleed scaffold: no app bar by default, since a
/// kiosk display showing a video playlist has no use for one on its main
/// screen. Secondary screens (e.g. diagnostics) can opt into [title].
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body, this.title});

  final Widget body;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: SafeArea(child: body),
    );
  }
}
