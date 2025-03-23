import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

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
    this.usePadding = false, // Changed default to false to avoid extra padding
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
            : 0.0; // Changed to 0 to avoid horizontal padding on mobile
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Determine the actual background color
    final bgColor = backgroundColor ?? 
                   (isDarkMode ? Color(0xFF001333) : Colors.white);

    return Center(
      child: Container(
        constraints: useConstraints ? BoxConstraints(maxWidth: screenWidth > 600 ? 1200 : screenWidth) : null,
        margin: useMargin ? EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: screenWidth > 600 ? 20 : 0, // Reduced vertical margin
        ) : null,
        padding: usePadding ? EdgeInsets.all(screenWidth > 600 ? 20 : 8) : null,
        color: bgColor, // Simple color instead of gradient
        // Remove decoration properties that create the white border
        child: child,
      ),
    );
  }
}