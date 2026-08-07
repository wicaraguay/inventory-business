/// Business-wide settings, shared by every device.
class AppSettings {
  AppSettings({
    required this.businessName,
    required this.defaultThreshold,
    this.hasLogo = false,
    this.logoVersion = 0,
  });

  final String businessName;
  final int defaultThreshold;

  /// Whether a business logo has been uploaded.
  final bool hasLogo;

  /// Epoch seconds of the last logo change — cache-busts the logo URL.
  final int logoVersion;
}
