class MatchSettings {
  int matchDurationSeconds;
  int osaeKomiMaxSeconds;
  bool shidoEnabled;
  int shidoCountForLoss;

  MatchSettings({
    this.matchDurationSeconds = 240,
    this.osaeKomiMaxSeconds = 20,
    this.shidoEnabled = true,
    this.shidoCountForLoss = 3,
  });

  MatchSettings copyWith({
    int? matchDurationSeconds,
    int? osaeKomiMaxSeconds,
    bool? shidoEnabled,
    int? shidoCountForLoss,
  }) {
    return MatchSettings(
      matchDurationSeconds: matchDurationSeconds ?? this.matchDurationSeconds,
      osaeKomiMaxSeconds: osaeKomiMaxSeconds ?? this.osaeKomiMaxSeconds,
      shidoEnabled: shidoEnabled ?? this.shidoEnabled,
      shidoCountForLoss: shidoCountForLoss ?? this.shidoCountForLoss,
    );
  }
}
