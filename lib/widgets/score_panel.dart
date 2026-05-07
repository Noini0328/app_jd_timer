import 'package:flutter/material.dart';
import '../models/player_state.dart';
import '../providers/match_provider.dart';

class ScorePanel extends StatelessWidget {
  final bool isAka;
  final PlayerState player;
  final MatchProvider provider;

  const ScorePanel({
    super.key,
    required this.isAka,
    required this.player,
    required this.provider,
  });

  Color get baseColor =>
      isAka ? const Color(0xFFCC2936) : const Color(0xFFCCCCCC);
  Color get bgColor =>
      isAka ? const Color(0xFF200A0C) : const Color(0xFF0E0E1E);
  String get label => isAka ? '赤' : '白';

  OsaeKomiSide get mySide =>
      isAka ? OsaeKomiSide.aka : OsaeKomiSide.shiro;

  bool get isMyOsaeActive => provider.osaeKomiSide == mySide;

  bool get canEdit =>
      provider.status == MatchStatus.running ||
      provider.status == MatchStatus.paused ||
      provider.status == MatchStatus.idle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ─── ヘッダー ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: baseColor.withOpacity(0.18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: baseColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
          // ─── スコア行群（均等分割・スクロールなし）───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Column(
                children: [
                  Expanded(child: _buildIpponRow()),
                  const SizedBox(height: 2),
                  Expanded(child: _buildWazaariRow()),
                  const SizedBox(height: 2),
                  Expanded(
                    child: _buildScoreRow(
                      label: '有効',
                      emoji: '🏅',
                      value: player.yuko,
                      onAdd: () => _change(yuko: 1),
                      onSub: () => _change(yuko: -1),
                      canAdd: canEdit,
                      canSub: canEdit && player.yuko > 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(child: _buildShidoRow()),
                  const SizedBox(height: 2),
                  Expanded(flex: 2, child: _buildOsaeKomi()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 一本（上限1） ───
  Widget _buildIpponRow() {
    final reached = player.ippon >= 1;
    return _buildScoreRow(
      label: '一本',
      emoji: '🥇',
      value: player.ippon,
      valueColor: reached ? const Color(0xFFFF6B35) : baseColor,
      canAdd: canEdit && !reached,
      canSub: canEdit && player.ippon > 0,
      onAdd: () => _change(ippon: 1),
      onSub: () => _change(ippon: -1),
      badge: reached ? '上限' : null,
      badgeColor: const Color(0xFFFF6B35),
    );
  }

  // ─── 技あり（上限2） ───
  Widget _buildWazaariRow() {
    final reached = player.wazaari >= 2;
    return _buildScoreRow(
      label: '技あり',
      emoji: '🥈',
      value: player.wazaari,
      valueColor: reached ? const Color(0xFF2196F3) : baseColor,
      canAdd: canEdit && !reached,
      canSub: canEdit && player.wazaari > 0,
      onAdd: () => _change(wazaari: 1),
      onSub: () => _change(wazaari: -1),
      badge: reached ? '一本相当' : '/2',
      badgeColor: reached ? const Color(0xFF2196F3) : Colors.white38,
    );
  }

  // ─── 指導（上限 shidoCountForLoss） ───
  Widget _buildShidoRow() {
    final lim = provider.settings.shidoCountForLoss;
    final reached = player.shido >= lim;
    return _buildScoreRow(
      label: '指導',
      emoji: '🟡',
      value: player.shido,
      valueColor: const Color(0xFFFFD700),
      canAdd: canEdit && !reached,
      canSub: canEdit && player.shido > 0,
      onAdd: () => _change(shido: 1),
      onSub: () => _change(shido: -1),
      badge: reached ? '負け' : '/$lim',
      badgeColor: reached ? Colors.red : Colors.white38,
    );
  }

  // ─── 汎用スコア行（高さに応じてサイズを動的調整）───
  Widget _buildScoreRow({
    required String label,
    required String emoji,
    required int value,
    Color? valueColor,
    required bool canAdd,
    required bool canSub,
    required VoidCallback onAdd,
    required VoidCallback onSub,
    String? badge,
    Color? badgeColor,
  }) {
    final color = valueColor ?? baseColor;
    return LayoutBuilder(builder: (context, constraints) {
      // 利用可能な高さからサイズを算出
      final h = constraints.maxHeight;
      final btnSize = (h * 0.62).clamp(22.0, 34.0);
      final iconSize = (btnSize * 0.5).clamp(11.0, 17.0);
      final numFontSize = (h * 0.48).clamp(14.0, 26.0);
      final badgeFontSize = (h * 0.16).clamp(7.0, 9.0);
      final labelFontSize = (h * 0.22).clamp(8.5, 11.0);
      final emojiSize = (h * 0.22).clamp(8.5, 12.0);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ラベル（固定幅：「技あり」4文字が入る幅）
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Row(
                  children: [
                    Text(emoji,
                        style: TextStyle(fontSize: emojiSize)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── 中央：ボタン + 数値（残り幅で中央寄せ）───
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _roundBtn(Icons.remove, canSub ? onSub : null, color,
                      size: btnSize, iconSize: iconSize),
                  SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$value',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: numFontSize,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        if (badge != null)
                          Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor ?? Colors.white38,
                              fontSize: badgeFontSize,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _roundBtn(Icons.add, canAdd ? onAdd : null, color,
                      size: btnSize, iconSize: iconSize),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─── 抑え込み ───
  Widget _buildOsaeKomi() {
    final secs = player.osaeKomiSeconds;
    final maxSecs = provider.settings.osaeKomiMaxSeconds;
    final isRunning = isMyOsaeActive &&
        provider.osaeKomiRunState == OsaeKomiRunState.running;
    final isActive = isMyOsaeActive;

    final double progress =
        maxSecs > 0 ? (secs / maxSecs).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (progress < 0.5) {
      barColor = const Color(0xFF4CAF50);
    } else if (progress < 0.8) {
      barColor = const Color(0xFFFFD700);
    } else {
      barColor = const Color(0xFFFF5722);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final secFontSize = (h * 0.30).clamp(14.0, 28.0);
      final labelFontSize = (h * 0.10).clamp(8.0, 11.0);
      final showProgressBar = h > 60 && isActive;

      return Container(
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0D2B0D)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF4CAF50) : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ラベル + 最大秒
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 9)),
                  const SizedBox(width: 3),
                  Text(
                    '抑え込み',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '最大${maxSecs}秒',
                    style: TextStyle(
                        color: Colors.white38, fontSize: labelFontSize * 0.9),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // 三列：[開始/停止] [秒数] [解けた]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _osaeBtn(
                      icon: isRunning ? Icons.pause : Icons.play_arrow,
                      label: isRunning ? '一時停止' : '開始',
                      color: isRunning
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF4CAF50),
                      enabled: provider.status == MatchStatus.running ||
                          provider.status == MatchStatus.paused ||
                          provider.status == MatchStatus.idle,
                      onTap: () {
                        if (isRunning) {
                          provider.pauseOsaeKomi();
                        } else {
                          provider.startOsaeKomi(mySide);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),

                  // 中央：秒数
                  SizedBox(
                    width: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$secs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive ? barColor : Colors.white38,
                            fontSize: secFontSize,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        Text(
                          '秒',
                          style: TextStyle(
                            color: isActive ? barColor : Colors.white38,
                            fontSize: labelFontSize * 0.85,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  Expanded(
                    child: _osaeBtn(
                      icon: Icons.lock_open,
                      label: '解けた',
                      color: const Color(0xFFFF5722),
                      enabled: isActive,
                      onTap: provider.releaseOsaeKomi,
                    ),
                  ),
                ],
              ),
            ),

            // 進捗バー（高さが十分ある場合のみ表示）
            if (showProgressBar) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _osaeBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: enabled ? color : Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? color : Colors.white24, size: 12),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback? onTap, Color color,
      {double size = 32, double iconSize = 15}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: onTap != null ? color.withOpacity(0.6) : Colors.white12,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: onTap != null ? color : Colors.white24,
        ),
      ),
    );
  }

  void _change({int? ippon, int? wazaari, int? yuko, int? shido}) {
    if (isAka) {
      provider.changeAka(
          ippon: ippon, wazaari: wazaari, yuko: yuko, shido: shido);
    } else {
      provider.changeShiro(
          ippon: ippon, wazaari: wazaari, yuko: yuko, shido: shido);
    }
  }
}
