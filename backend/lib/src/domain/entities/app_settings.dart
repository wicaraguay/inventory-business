/// Business-wide settings, shared by every device.
class AppSettings {
  AppSettings({required this.businessName, required this.defaultThreshold});

  final String businessName;
  final int defaultThreshold;
}
