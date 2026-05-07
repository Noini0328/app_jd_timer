import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../widgets/score_panel.dart';
import 'settings_screen.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Consumer<MatchProvider>(
          builder: (context, match, _) {
            return OrientationBuilder(
              builder: (context, orientation) {
                return Column(
                  children: [
                    _buildHeader(context, match),
                    Expanded(
                      child: orientation == Orientation.landscape
                          ? _buildLandscapeBody(match)
                          : _buildPortraitBody(match),
                    ),
                    _buildControls(context, match),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLandscapeBody(MatchProvider match) {
    return Row(
      children: [
        Expanded(
            child: ScorePanel(
                isAka: true, player: match.aka, provider: match)),
        Container(width: 1.5, color: Colors.white12),
        Expanded(
            child: ScorePanel(
                isAka: false, player: match.shiro, provider: match)),
      ],
    );
  }

  Widget _buildPortraitBody(MatchProvider match) {
    return Column(
      children: [
        Expanded(
            child: ScorePanel(
                isAka: true, player: match.aka, provider: match)),
        Container(height: 1.5, color: Colors.white12),
        Expanded(
            child: ScorePanel(
                isAka: false, player: match.shiro, provider: match)),
      ],
    );
  }

  // ─── ヘッダー ───
  Widget _buildHeader(BuildContext context, MatchProvider match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          _iconBtn(
            Icons.settings,
            Colors.white54,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 6),
          _statusBadge(match.status),
          const Spacer(),
          _buildTimer(match),
          const Spacer(),
          _buildResultBadge(match),
        ],
      ),
    );
  }

  Widget _buildTimer(MatchProvider match) {
    final isLow = match.remainingSeconds <= 30 &&
        match.status == MatchStatus.running;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isLow
            ? const Color(0xFFCC2936).withOpacity(0.15)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLow ? const Color(0xFFCC2936) : Colors.white24,
          width: isLow ? 2 : 1,
        ),
      ),
      child: Text(
        match.formattedTime,
        style: TextStyle(
          color: isLow ? const Color(0xFFFF6B7A) : Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _statusBadge(MatchStatus status) {
    final (text, color) = switch (status) {
      MatchStatus.idle => ('待機中', Colors.white38),
      MatchStatus.running => ('試合中', const Color(0xFF4CAF50)),
      MatchStatus.paused => ('停止中', const Color(0xFFFFD700)),
      MatchStatus.finished => ('終　了', const Color(0xFFFF5722)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildResultBadge(MatchProvider match) {
    final result = match.currentResult;
    final (text, color, icon) = switch (result) {
      WinResult.aka =>
        ('赤 勝ち', const Color(0xFFCC2936), Icons.emoji_events),
      WinResult.shiro =>
        ('白 勝ち', const Color(0xFFDDDDDD), Icons.emoji_events),
      WinResult.draw =>
        ('引き分け', const Color(0xFFFFD700), Icons.balance),
      WinResult.none => ('－', Colors.white24, Icons.remove),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 下部コントロール ───
  Widget _buildControls(BuildContext context, MatchProvider match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFF16213E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 開始 / 一時停止 / 再開
          if (match.status == MatchStatus.idle)
            _ctrlBtn('▶ 開始', const Color(0xFF4CAF50), match.startMatch)
          else if (match.status == MatchStatus.running)
            _ctrlBtn('⏸ 一時停止', const Color(0xFFFFD700), match.pauseMatch)
          else if (match.status == MatchStatus.paused)
            _ctrlBtn('▶ 再開', const Color(0xFF4CAF50), match.startMatch)
          else
            // finished
            _ctrlBtn('▶ 開始', const Color(0xFF4CAF50), null),

          const SizedBox(width: 6),

          // 前の判定を戻す
          _ctrlBtn(
            '↩ 戻す',
            const Color(0xFF7E57C2),
            match.canUndo ? match.undo : null,
            small: true,
          ),

          const SizedBox(width: 6),

          // リセット
          _ctrlBtn(
            '↺ リセット',
            const Color(0xFFFF5722),
            () => _confirmReset(context, match),
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(String label, Color color, VoidCallback? onTap,
      {bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withOpacity(0.18)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null ? color : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null ? color : Colors.white24,
            fontSize: small ? 12 : 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _confirmReset(BuildContext context, MatchProvider match) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'リセット確認',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          '試合データをすべてリセットしますか？\nこの操作は取り消せません。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              match.resetMatch();
              Navigator.pop(context);
            },
            child: const Text(
              'リセット',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
