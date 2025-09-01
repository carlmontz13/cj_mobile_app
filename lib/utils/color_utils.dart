import 'package:flutter/material.dart';

class ColorUtils {
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  static List<String> getDefaultColors() {
    return [
      '#4285F4', // Blue
      '#EA4335', // Red
      '#FBBC04', // Yellow
      '#34A853', // Green
      '#FF6D01', // Orange
      '#46BDC6', // Teal
      '#7B1FA2', // Purple
      '#E67C73', // Pink
    ];
  }
}
