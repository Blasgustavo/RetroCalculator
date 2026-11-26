/// Breakpoints declarados en `design/app.design.json` (`dimensions`).
class SpecBreakpoint {
  const SpecBreakpoint._();

  static const String mobile = 'mobile';
  static const String tablet = 'tablet';
  static const String desktop = 'desktop';

  static const int tabletWidth = 600;
  static const int desktopWidth = 1024;

  static String of(double width) {
    if (width >= desktopWidth) {
      return desktop;
    }
    if (width >= tabletWidth) {
      return tablet;
    }
    return mobile;
  }
}
