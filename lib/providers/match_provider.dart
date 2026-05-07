import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/player_state.dart';
import '../models/match_settings.dart';

enum MatchStatus { idle, running, paused, finished }

enum WinResult { none, aka, shiro, draw }

enum OsaeKomiSide { none, aka, shiro }

enum OsaeKomiRunState { stopped, running, paused }

/// アンドゥ用スナップショット
class _MatchSnapshot {
  final PlayerState aka;
  final PlayerState shiro;
  final MatchStatus status;
  final int remainingSeconds;
  final OsaeKomiSide osaeKomiSide;
  final OsaeKomiRunState osaeKomiRunState;

  const _MatchSnapshot({
    required this.aka,
    required this.shiro,
    required this.status,
    required this.remainingSeconds,
    required this.osaeKomiSide,
    required this.osaeKomiRunState,
  });
}

class MatchProvider extends ChangeNotifier {
  MatchSettings settings = MatchSettings();

  PlayerState aka = PlayerState();
  PlayerState shiro = PlayerState();

  MatchStatus status = MatchStatus.idle;
  int remainingSeconds = 240;

  OsaeKomiSide osaeKomiSide = OsaeKomiSide.none;
  OsaeKomiRunState osaeKomiRunState = OsaeKomiRunState.stopped;

  Timer? _matchTimer;
  Timer? _osaeKomiTimer;

  // ─── アンドゥ履歴（最大20件）───
  final List<_MatchSnapshot> _history = [];
  static const int _maxHistory = 20;

  bool get canUndo => _history.isNotEmpty;

  void _saveSnapshot() {
    _history.add(_MatchSnapshot(
      aka: aka.copyWith(),
      shiro: shiro.copyWith(),
      status: status,
      remainingSeconds: remainingSeconds,
      osaeKomiSide: osaeKomiSide,
      osaeKomiRunState: osaeKomiRunState,
    ));
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
  }

  /// 前の状態に戻す（タイマーも元の動作状態に復元）
  void undo() {
    if (_history.isEmpty) return;

    // 既存タイマーを全停止
    _matchTimer?.cancel();
    _osaeKomiTimer?.cancel();

    final snap = _history.removeLast();
    aka = snap.aka.copyWith();
    shiro = snap.shiro.copyWith();
    remainingSeconds = snap.remainingSeconds;
    osaeKomiSide = snap.osaeKomiSide;

    // finished → running として復元（試合を再開させる）
    final restoredStatus = snap.status == MatchStatus.finished
        ? MatchStatus.running
        : snap.status;
    status = restoredStatus;

    // 試合タイマーの復元
    if (restoredStatus == MatchStatus.running) {
      _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (remainingSeconds > 0) {
          remainingSeconds--;
          notifyListeners();
          if (_isDecided) _finishMatch();
        } else {
          _finishMatch();
        }
      });
    }

    // 抑え込みタイマーの復元
    if (snap.osaeKomiRunState == OsaeKomiRunState.running &&
        osaeKomiSide != OsaeKomiSide.none) {
      osaeKomiRunState = OsaeKomiRunState.running;
      final side = osaeKomiSide;
      _osaeKomiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final current = side == OsaeKomiSide.aka
            ? aka.osaeKomiSeconds
            : shiro.osaeKomiSeconds;
        final next = current + 1;
        if (side == OsaeKomiSide.aka) {
          aka = aka.copyWith(osaeKomiSeconds: next);
        } else {
          shiro = shiro.copyWith(osaeKomiSeconds: next);
        }
        notifyListeners();
        if (next >= settings.osaeKomiMaxSeconds) {
          _osaeKomiTimer?.cancel();
          osaeKomiRunState = OsaeKomiRunState.stopped;
          osaeKomiSide = OsaeKomiSide.none;
          _saveSnapshot();
          if (side == OsaeKomiSide.aka) {
            aka = _applyScore(aka, ippon: 1);
          } else {
            shiro = _applyScore(shiro, ippon: 1);
          }
          _finishMatch();
        }
      });
    } else {
      osaeKomiRunState = snap.osaeKomiRunState;
    }

    notifyListeners();
  }

  // ────────────────────────────────
  // 勝敗判定
  // ────────────────────────────────
  WinResult get currentResult {
    if (aka.ippon >= 1 && shiro.ippon < 1) return WinResult.aka;
    if (shiro.ippon >= 1 && aka.ippon < 1) return WinResult.shiro;
    if (aka.wazaari >= 2 && shiro.wazaari < 2) return WinResult.aka;
    if (shiro.wazaari >= 2 && aka.wazaari < 2) return WinResult.shiro;
    if (settings.shidoEnabled) {
      final lim = settings.shidoCountForLoss;
      if (aka.shido >= lim && shiro.shido < lim) return WinResult.shiro;
      if (shiro.shido >= lim && aka.shido < lim) return WinResult.aka;
    }
    if (aka.wazaari > shiro.wazaari) return WinResult.aka;
    if (shiro.wazaari > aka.wazaari) return WinResult.shiro;
    if (aka.yuko > shiro.yuko) return WinResult.aka;
    if (shiro.yuko > aka.yuko) return WinResult.shiro;
    return WinResult.draw;
  }

  bool get _isDecided {
    if (aka.ippon >= 1 || shiro.ippon >= 1) return true;
    if (aka.wazaari >= 2 || shiro.wazaari >= 2) return true;
    if (settings.shidoEnabled) {
      final lim = settings.shidoCountForLoss;
      if (aka.shido >= lim || shiro.shido >= lim) return true;
    }
    return false;
  }

  // ────────────────────────────────
  // 試合タイマー
  // ────────────────────────────────
  void startMatch() {
    if (status == MatchStatus.finished) return;
    if (status == MatchStatus.idle) {
      remainingSeconds = settings.matchDurationSeconds;
    }
    status = MatchStatus.running;
    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
        if (_isDecided) _finishMatch();
      } else {
        _finishMatch();
      }
    });
    notifyListeners();
  }

  void pauseMatch() {
    _matchTimer?.cancel();
    if (osaeKomiRunState == OsaeKomiRunState.running) {
      _osaeKomiTimer?.cancel();
      osaeKomiRunState = OsaeKomiRunState.paused;
    }
    status = MatchStatus.paused;
    notifyListeners();
  }

  void _finishMatch() {
    _matchTimer?.cancel();
    _osaeKomiTimer?.cancel();
    osaeKomiRunState = OsaeKomiRunState.stopped;
    osaeKomiSide = OsaeKomiSide.none;
    status = MatchStatus.finished;
    notifyListeners();
  }

  void resetMatch() {
    _matchTimer?.cancel();
    _osaeKomiTimer?.cancel();
    aka = PlayerState();
    shiro = PlayerState();
    osaeKomiSide = OsaeKomiSide.none;
    osaeKomiRunState = OsaeKomiRunState.stopped;
    status = MatchStatus.idle;
    remainingSeconds = settings.matchDurationSeconds;
    _history.clear();
    notifyListeners();
  }

  // ────────────────────────────────
  // スコア変更
  // ────────────────────────────────
  void changeAka({int? ippon, int? wazaari, int? yuko, int? shido}) {
    _saveSnapshot();
    aka = _applyScore(aka,
        ippon: ippon, wazaari: wazaari, yuko: yuko, shido: shido);
    _checkAndFinish();
    notifyListeners();
  }

  void changeShiro({int? ippon, int? wazaari, int? yuko, int? shido}) {
    _saveSnapshot();
    shiro = _applyScore(shiro,
        ippon: ippon, wazaari: wazaari, yuko: yuko, shido: shido);
    _checkAndFinish();
    notifyListeners();
  }

  PlayerState _applyScore(PlayerState p,
      {int? ippon, int? wazaari, int? yuko, int? shido}) {
    return p.copyWith(
      ippon: ippon != null ? (p.ippon + ippon).clamp(0, 1) : p.ippon,
      wazaari:
          wazaari != null ? (p.wazaari + wazaari).clamp(0, 2) : p.wazaari,
      yuko: yuko != null ? (p.yuko + yuko).clamp(0, 9999) : p.yuko,
      shido: shido != null
          ? (p.shido + shido).clamp(0, settings.shidoCountForLoss)
          : p.shido,
    );
  }

  void _checkAndFinish() {
    if (_isDecided && status == MatchStatus.running) {
      _finishMatch();
    }
  }

  // ────────────────────────────────
  // 抑え込みタイマー
  // ────────────────────────────────
  void startOsaeKomi(OsaeKomiSide side) {
    if (status != MatchStatus.running &&
        status != MatchStatus.paused &&
        status != MatchStatus.idle) return;
    if (osaeKomiRunState == OsaeKomiRunState.running) return;

    if (osaeKomiSide != side && osaeKomiSide != OsaeKomiSide.none) {
      _resetOsaeKomiState(side);
    }

    osaeKomiSide = side;
    osaeKomiRunState = OsaeKomiRunState.running;

    if (status == MatchStatus.paused || status == MatchStatus.idle) {
      startMatch();
    }

    _osaeKomiTimer?.cancel();
    _osaeKomiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current =
          side == OsaeKomiSide.aka ? aka.osaeKomiSeconds : shiro.osaeKomiSeconds;
      final next = current + 1;

      if (side == OsaeKomiSide.aka) {
        aka = aka.copyWith(osaeKomiSeconds: next);
      } else {
        shiro = shiro.copyWith(osaeKomiSeconds: next);
      }

      notifyListeners();

      if (next >= settings.osaeKomiMaxSeconds) {
        _osaeKomiTimer?.cancel();
        osaeKomiRunState = OsaeKomiRunState.stopped;
        osaeKomiSide = OsaeKomiSide.none;
        _saveSnapshot();
        if (side == OsaeKomiSide.aka) {
          aka = _applyScore(aka, ippon: 1);
        } else {
          shiro = _applyScore(shiro, ippon: 1);
        }
        _finishMatch();
      }
    });

    notifyListeners();
  }

  void pauseOsaeKomi() {
    _osaeKomiTimer?.cancel();
    osaeKomiRunState = OsaeKomiRunState.paused;
    notifyListeners();
  }

  void releaseOsaeKomi() {
    _saveSnapshot();
    _osaeKomiTimer?.cancel();
    final side = osaeKomiSide;
    osaeKomiRunState = OsaeKomiRunState.stopped;
    osaeKomiSide = OsaeKomiSide.none;
    if (side == OsaeKomiSide.aka) {
      aka = aka.copyWith(osaeKomiSeconds: 0);
    } else if (side == OsaeKomiSide.shiro) {
      shiro = shiro.copyWith(osaeKomiSeconds: 0);
    }
    notifyListeners();
  }

  void _resetOsaeKomiState(OsaeKomiSide newSide) {
    _osaeKomiTimer?.cancel();
    if (osaeKomiSide == OsaeKomiSide.aka) {
      aka = aka.copyWith(osaeKomiSeconds: 0);
    } else if (osaeKomiSide == OsaeKomiSide.shiro) {
      shiro = shiro.copyWith(osaeKomiSeconds: 0);
    }
    osaeKomiSide = newSide;
    osaeKomiRunState = OsaeKomiRunState.stopped;
  }

  // ────────────────────────────────
  // 設定
  // ────────────────────────────────
  void updateSettings(MatchSettings newSettings) {
    settings = newSettings;
    if (status == MatchStatus.idle) {
      remainingSeconds = newSettings.matchDurationSeconds;
    }
    notifyListeners();
  }

  String get formattedTime {
    int m = remainingSeconds ~/ 60;
    int s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
