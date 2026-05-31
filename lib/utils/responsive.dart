import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType getDeviceType(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return DeviceType.desktop;
    if (w >= 650) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;

  static double contentMaxWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop: return 900;
      case DeviceType.tablet: return 700;
      case DeviceType.mobile: return double.infinity;
    }
  }

  static int gridColumns(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop: return 4;
      case DeviceType.tablet: return 4;
      case DeviceType.mobile: return 2;
    }
  }

  static double horizontalPadding(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop: return 32;
      case DeviceType.tablet: return 24;
      case DeviceType.mobile: return 16;
    }
  }
}