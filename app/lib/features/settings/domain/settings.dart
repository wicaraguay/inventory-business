/// App settings (persisted locally with SharedPreferences).
class Settings {
  const Settings({required this.businessName, required this.defaultThreshold});

  final String businessName;
  final int defaultThreshold;

  Settings copyWith({String? businessName, int? defaultThreshold}) => Settings(
        businessName: businessName ?? this.businessName,
        defaultThreshold: defaultThreshold ?? this.defaultThreshold,
      );
}
