/// Business settings, shared across devices (stored in the backend).
class Settings {
  const Settings({
    required this.businessName,
    required this.defaultThreshold,
    this.hasLogo = false,
    this.logoVersion = 0,
  });

  final String businessName;
  final int defaultThreshold;

  /// Whether a business logo has been uploaded (shown on login + sidebar).
  final bool hasLogo;

  /// Bumps when the logo changes — used to cache-bust the logo URL.
  final int logoVersion;

  Settings copyWith({
    String? businessName,
    int? defaultThreshold,
    bool? hasLogo,
    int? logoVersion,
  }) =>
      Settings(
        businessName: businessName ?? this.businessName,
        defaultThreshold: defaultThreshold ?? this.defaultThreshold,
        hasLogo: hasLogo ?? this.hasLogo,
        logoVersion: logoVersion ?? this.logoVersion,
      );
}
