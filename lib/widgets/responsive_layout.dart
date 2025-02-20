import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool useMargin;
  final bool usePadding;
  final bool useConstraints;
  final Color? backgroundColor;

  const ResponsiveLayout({
    Key? key,
    required this.child,
    this.useMargin = true,
    this.usePadding = true,
    this.useConstraints = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200
        ? (screenWidth - 1200) / 2
        : screenWidth > 600
            ? 40.0
            : 8.0;

    return Center(
      child: Container(
        constraints: useConstraints ? BoxConstraints(maxWidth: screenWidth > 600 ? 1200 : screenWidth) : null,
        margin: useMargin ? EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: screenWidth > 600 ? 40 : 16,
        ) : null,
        padding: usePadding ? EdgeInsets.all(screenWidth > 600 ? 30 : 12) : null,
        decoration: BoxDecoration(
          gradient: backgroundColor == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0F0F0), Color(0xFFC0C0C0)],
                )
              : null,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFBEBEBE),
              offset: Offset(20, 20),
              blurRadius: 60,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-20, -20),
              blurRadius: 60,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}