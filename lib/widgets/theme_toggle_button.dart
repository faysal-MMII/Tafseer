import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ThemeToggleButton extends StatelessWidget {
  final double size;
  
  ThemeToggleButton({
    this.size = 24.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blueGrey[900]!.withOpacity(0.4) : Colors.blueGrey[50]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.all(4),
      child: IconButton(
        icon: Icon(
          FontAwesomeIcons.moon,
          size: size,
          color: isDarkMode 
            ? Colors.amber[300]  // Golden in dark mode
            : Colors.blueGrey[700],  // Dark in light mode
        ),
        tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
        onPressed: () {
          themeProvider.toggleTheme();
        },
      ),
    );
  }
}