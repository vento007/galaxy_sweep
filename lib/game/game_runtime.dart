import 'dart:async';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:galaxy_sweep/controllers/render_config_controller.dart';
import 'package:galaxy_sweep/game/cubit/game_cubit.dart';
import 'package:galaxy_sweep/game/cubit/game_state.dart';
import 'package:galaxy_sweep/game/game_stage.dart';
import 'package:galaxy_sweep/models/galaxy_blast.dart';
import 'package:galaxy_sweep/models/piece_visual_state.dart';

class GameRuntime extends StatefulWidget {
  const GameRuntime({super.key, required this.gameCubit});

  final GameCubit gameCubit;

  @override
  State<GameRuntime> createState() => _GameRuntimeState();
}

class _GameRuntimeState extends State<GameRuntime>
    with SingleTickerProviderStateMixin {
  static const _idleMusicAsset = 'assets/VibeDepot_Yoga.mp3';
  static const _gameMusicAsset = 'assets/Happiness_In_Music_Space.mp3';
  static const _moveSoundAsset =
      'assets/whoosh-clean-fast-bosnow-3-3-00-00.mp3';
  static const _foundSoundAsset =
      'assets/whoosh-dark-metallic-vadi-sound-1-00-05.mp3';
  static const _explosionSoundAsset =
      'assets/whoosh-boom-stutter-tomas-herudek-1-00-09.mp3';
  static const _musicTargetVolume = 0.4;
  static const _musicFadeDuration = Duration(milliseconds: 900);
  static const _musicFadeSteps = 12;
  static const _moveSoundVolume = 0.14;
  static const _foundSoundVolume = 0.19;
  static const _explosionSoundVolume = 0.24;

  late final RenderConfigController _renderConfig;
  late final AudioPlayer _musicPlayer;
  late final AudioPlayer _moveSoundPlayer;
  late final AudioPlayer _foundSoundPlayer;
  late final AudioPlayer _explosionSoundPlayer;
  late final Ticker _ticker;
  final ValueNotifier<double> _elapsedSeconds = ValueNotifier<double>(0);
  final Stopwatch _clock = Stopwatch();

  ui.FragmentProgram? _tileNebulaProgram;
  ui.FragmentProgram? _tileStarsProgram;
  ui.FragmentProgram? _galaxyExplodeProgram;
  ui.FragmentProgram? _galaxyRevealProgram;
  bool _showRenderControls = false;
  double _musicVolume = 0;
  int _musicFadeToken = 0;
  String? _currentMusicAsset;

  @override
  void initState() {
    super.initState();
    _renderConfig = RenderConfigController();
    _musicPlayer = AudioPlayer()..audioCache = AudioCache(prefix: '');
    _moveSoundPlayer = AudioPlayer()..audioCache = AudioCache(prefix: '');
    _foundSoundPlayer = AudioPlayer()..audioCache = AudioCache(prefix: '');
    _explosionSoundPlayer = AudioPlayer()..audioCache = AudioCache(prefix: '');
    unawaited(_musicPlayer.setReleaseMode(ReleaseMode.loop));
    unawaited(_musicPlayer.setVolume(0));
    unawaited(_moveSoundPlayer.setVolume(_moveSoundVolume));
    unawaited(_foundSoundPlayer.setVolume(_foundSoundVolume));
    unawaited(_explosionSoundPlayer.setVolume(_explosionSoundVolume));
    _clock.start();
    _ticker = createTicker((_) {
      final now = _clock.elapsedMicroseconds / Duration.microsecondsPerSecond;
      _elapsedSeconds.value = now;
      widget.gameCubit.tick(
        now,
        explosionSpeed: _renderConfig.config.galaxyExplosionSpeed,
        foundSpeed: _renderConfig.config.galaxyFoundSpeed,
      );
    })..start();
    _loadShader('shaders/tile_nebula.frag', (program) {
      _tileNebulaProgram = program;
    }, 'Tile nebula');
    _loadShader('shaders/tile_stars.frag', (program) {
      _tileStarsProgram = program;
    }, 'Tile stars');
    _loadShader('shaders/galaxy_explode.frag', (program) {
      _galaxyExplodeProgram = program;
    }, 'Galaxy explode');
    _loadShader('shaders/galaxy_reveal.frag', (program) {
      _galaxyRevealProgram = program;
    }, 'Galaxy reveal');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_syncPhaseMusic(widget.gameCubit.state));
    });
  }

  @override
  void dispose() {
    _renderConfig.dispose();
    unawaited(_musicPlayer.dispose());
    unawaited(_moveSoundPlayer.dispose());
    unawaited(_foundSoundPlayer.dispose());
    unawaited(_explosionSoundPlayer.dispose());
    _ticker.dispose();
    _elapsedSeconds.dispose();
    super.dispose();
  }

  Future<void> _playMusic(String asset) async {
    if (_currentMusicAsset == asset) {
      return;
    }

    try {
      final token = ++_musicFadeToken;
      final previousAsset = _currentMusicAsset;
      if (previousAsset != null) {
        await _fadeMusicTo(0, token: token);
        if (token != _musicFadeToken) {
          return;
        }
        await _musicPlayer.stop();
      }

      _musicVolume = 0;
      await _musicPlayer.setVolume(0);
      await _musicPlayer.play(AssetSource(asset));
      _currentMusicAsset = asset;
      await _fadeMusicTo(_musicTargetVolume, token: token);
    } catch (error) {
      _currentMusicAsset = null;
      debugPrint('Music failed to start: $error');
    }
  }

  Future<void> _syncPhaseMusic(GameState state) async {
    if (state.isPlaying) {
      await _playMusic(_gameMusicAsset);
      return;
    }

    await _playMusic(_idleMusicAsset);
  }

  Future<void> _playMoveSound() async {
    try {
      await _moveSoundPlayer.stop();
      await _moveSoundPlayer.play(AssetSource(_moveSoundAsset));
    } catch (error) {
      debugPrint('Move sound failed to play: $error');
    }
  }

  Future<void> _playFoundSound() async {
    try {
      await _foundSoundPlayer.stop();
      await _foundSoundPlayer.play(AssetSource(_foundSoundAsset));
    } catch (error) {
      debugPrint('Found sound failed to play: $error');
    }
  }

  Future<void> _playExplosionSound() async {
    try {
      await _explosionSoundPlayer.stop();
      await _explosionSoundPlayer.play(AssetSource(_explosionSoundAsset));
    } catch (error) {
      debugPrint('Explosion sound failed to play: $error');
    }
  }

  Future<void> _fadeMusicTo(double target, {required int token}) async {
    final stepDelay = Duration(
      milliseconds: _musicFadeDuration.inMilliseconds ~/ _musicFadeSteps,
    );
    final start = _musicVolume;

    for (var step = 1; step <= _musicFadeSteps; step++) {
      if (token != _musicFadeToken) {
        return;
      }

      final progress = step / _musicFadeSteps;
      final volume = start + (target - start) * progress;
      _musicVolume = volume;
      await _musicPlayer.setVolume(volume);

      if (step < _musicFadeSteps) {
        await Future.delayed(stepDelay);
      }
    }
  }

  Future<void> _loadShader(
    String asset,
    void Function(ui.FragmentProgram program) onLoaded,
    String label,
  ) async {
    try {
      final program = await ui.FragmentProgram.fromAsset(asset);
      if (!mounted) {
        return;
      }
      setState(() {
        onLoaded(program);
      });
    } catch (error) {
      debugPrint('$label shader unavailable: $error');
    }
  }

  bool _shouldPlayMoveSound(GameState previous, GameState current) {
    for (final piece in current.board.pieces) {
      final currentVisualState = piece.visualState;

      if (currentVisualState is! PieceMoving ||
          currentVisualState.fromIndex == currentVisualState.toIndex) {
        continue;
      }

      final previousPiece = previous.board.pieces.firstWhere(
        (candidate) => candidate.id == piece.id,
      );
      if (previousPiece.visualState is! PieceMoving) {
        return true;
      }
    }

    return false;
  }

  bool _shouldPlayExplosionSound(GameState previous, GameState current) {
    final previousTimerBlastCount = previous.board.blasts
        .where((blast) => blast.kind == GalaxyBlastKind.timer)
        .length;
    final currentTimerBlastCount = current.board.blasts
        .where((blast) => blast.kind == GalaxyBlastKind.timer)
        .length;

    return currentTimerBlastCount > previousTimerBlastCount;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GameCubit, GameState>(
          bloc: widget.gameCubit,
          listenWhen: (previous, current) =>
              previous.isPlaying != current.isPlaying,
          listener: (context, state) {
            unawaited(_syncPhaseMusic(state));
          },
        ),
        BlocListener<GameCubit, GameState>(
          bloc: widget.gameCubit,
          listenWhen: _shouldPlayMoveSound,
          listener: (context, state) {
            unawaited(_playMoveSound());
          },
        ),
        BlocListener<GameCubit, GameState>(
          bloc: widget.gameCubit,
          listenWhen: (previous, current) => previous.score < current.score,
          listener: (context, state) {
            unawaited(_playFoundSound());
          },
        ),
        BlocListener<GameCubit, GameState>(
          bloc: widget.gameCubit,
          listenWhen: _shouldPlayExplosionSound,
          listener: (context, state) {
            unawaited(_playExplosionSound());
          },
        ),
      ],
      child: GameStage(
        gameCubit: widget.gameCubit,
        renderConfigController: _renderConfig,
        elapsedSeconds: _elapsedSeconds,
        tileNebulaProgram: _tileNebulaProgram,
        tileStarsProgram: _tileStarsProgram,
        galaxyExplodeProgram: _galaxyExplodeProgram,
        galaxyRevealProgram: _galaxyRevealProgram,
        showRenderControls: _showRenderControls,
        onToggleRenderControls: () => setState(() {
          _showRenderControls = !_showRenderControls;
        }),
      ),
    );
  }
}
