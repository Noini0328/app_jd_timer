class PlayerState {
  /// 一本: 0 or 1（上限1）
  int ippon;

  /// 技あり: 0〜2（上限2）
  int wazaari;

  /// 有効: 0以上（上限なし）
  int yuko;

  /// 指導: 0〜3（上限3）
  int shido;

  /// 抑え込み経過秒数
  int osaeKomiSeconds;

  PlayerState({
    this.ippon = 0,
    this.wazaari = 0,
    this.yuko = 0,
    this.shido = 0,
    this.osaeKomiSeconds = 0,
  });

  PlayerState copyWith({
    int? ippon,
    int? wazaari,
    int? yuko,
    int? shido,
    int? osaeKomiSeconds,
  }) {
    return PlayerState(
      ippon: ippon ?? this.ippon,
      wazaari: wazaari ?? this.wazaari,
      yuko: yuko ?? this.yuko,
      shido: shido ?? this.shido,
      osaeKomiSeconds: osaeKomiSeconds ?? this.osaeKomiSeconds,
    );
  }
}
