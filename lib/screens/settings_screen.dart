import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../models/match_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late MatchSettings _s;

  @override
  void initState() {
    super.initState();
    _s = context.read<MatchProvider>().settings.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '⚙️ 設定',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '保存',
              style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _section('⏱️ 試合時間', [
            _durationRow(
              label: '試合時間',
              value: _s.matchDurationSeconds,
              displayFn: (v) =>
                  '${v ~/ 60}分${v % 60 == 0 ? '' : '${v % 60}秒'}',
              min: 60,
              max: 600,
              step: 30,
              onChanged: (v) => setState(() => _s.matchDurationSeconds = v),
            ),
          ]),
          const SizedBox(height: 14),
          _section('🔒 抑え込み', [
            _durationRow(
              label: '最大秒数（一本）',
              value: _s.osaeKomiMaxSeconds,
              displayFn: (v) => '${v}秒',
              min: 5,
              max: 60,
              step: 1,
              onChanged: (v) => setState(() => _s.osaeKomiMaxSeconds = v),
            ),
          ]),
          const SizedBox(height: 14),
          _section('🟡 指導', [
            SwitchListTile(
              title: const Text('指導による勝敗判定',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              subtitle: Text(
                _s.shidoEnabled ? '有効' : '無効',
                style: TextStyle(
                    color: _s.shidoEnabled
                        ? const Color(0xFFFFD700)
                        : Colors.grey),
              ),
              value: _s.shidoEnabled,
              activeColor: const Color(0xFFFFD700),
              onChanged: (v) => setState(() => _s.shidoEnabled = v),
            ),
            if (_s.shidoEnabled) ...[
              const Divider(color: Colors.white12),
              _durationRow(
                label: '何回で負け',
                value: _s.shidoCountForLoss,
                displayFn: (v) => '$v回',
                min: 1,
                max: 5,
                step: 1,
                onChanged: (v) => setState(() => _s.shidoCountForLoss = v),
              ),
            ],
          ]),
          const SizedBox(height: 24),
          _preview(),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(title,
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2)),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _durationRow({
    required String label,
    required int value,
    required String Function(int) displayFn,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          _circleBtn(Icons.remove,
              value <= min ? null : () => onChanged((value - step).clamp(min, max))),
          Container(
            width: 72,
            alignment: Alignment.center,
            child: Text(displayFn(value),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          _circleBtn(Icons.add,
              value >= max ? null : () => onChanged((value + step).clamp(min, max))),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null ? Colors.white12 : const Color(0xFF0F3460),
          border: Border.all(
              color: onTap == null
                  ? Colors.white24
                  : const Color(0xFFFFD700)),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap == null ? Colors.white38 : Colors.white),
      ),
    );
  }

  Widget _preview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 設定プレビュー',
              style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 8),
          _prow('試合時間',
              '${_s.matchDurationSeconds ~/ 60}分${_s.matchDurationSeconds % 60 == 0 ? '' : '${_s.matchDurationSeconds % 60}秒'}'),
          _prow('抑え込み一本', '${_s.osaeKomiMaxSeconds}秒'),
          _prow('指導判定',
              _s.shidoEnabled ? '${_s.shidoCountForLoss}回で負け' : '無効'),
        ],
      ),
    );
  }

  Widget _prow(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Text('$label：',
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ]),
      );

  void _save() {
    context.read<MatchProvider>().updateSettings(_s);
    Navigator.pop(context);
  }
}
