import 'package:flutter/material.dart';

abstract class Breakpoints {
  static const double small = 576;

  static const double medium = 900;

  static const double large = 1100;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget smallScaffold;

  final Widget? mediumScaffold;

  final Widget largeScaffold;

  const ResponsiveLayout({
    super.key,
    required this.smallScaffold,
    this.mediumScaffold,
    required this.largeScaffold,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        if (maxWidth <= Breakpoints.small) {
          return smallScaffold;
        } else if (maxWidth <= Breakpoints.medium) {
          return mediumScaffold ?? largeScaffold;
        } else {
          return largeScaffold;
        }
      },
    );
  }
}
