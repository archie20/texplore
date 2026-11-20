enum AppBreakpoint {
  mobile,
  tablet,
  desktop;

  static AppBreakpoint of(double width) {
    if (width >= 1024) return desktop;
    if (width >= 600) return tablet;
    return mobile;
  }

  bool get isMobile => this == mobile;
  bool get isDesktop => this == desktop;
}
