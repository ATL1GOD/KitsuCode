import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 1000.0;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileScaffold;
  final Widget? tabletScaffold;
  final Widget desktopScaffold;

  const ResponsiveLayout({
    super.key,
    required this.mobileScaffold,
    this.tabletScaffold,
    required this.desktopScaffold,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return desktopScaffold;
        } else if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tabletScaffold ?? desktopScaffold;
        } else {
          return mobileScaffold;
        }
      },
    );
  }
}
