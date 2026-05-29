import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/overlays/signal_panel_painter.dart';
import 'package:google_fonts/google_fonts.dart';

class StartGameOverlay extends StatelessWidget {
  const StartGameOverlay({
    super.key,
    required this.elapsedSeconds,
    required this.onStart,
  });

  final ValueNotifier<double> elapsedSeconds;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GameOverlayPanel(
      elapsedSeconds: elapsedSeconds,
      title: 'Galaxy Sweep',
      subtitle: 'signal field ready',
      actionLabel: 'Start Game',
      onAction: onStart,
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.elapsedSeconds,
    required this.score,
    required this.onRestart,
  });

  final ValueNotifier<double> elapsedSeconds;
  final int score;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return GameOverlayPanel(
      elapsedSeconds: elapsedSeconds,
      title: 'GAME OVER',
      subtitle: '$score galaxies found',
      actionLabel: 'Restart',
      onAction: onRestart,
    );
  }
}

class GameOverlayPanel extends StatelessWidget {
  const GameOverlayPanel({
    super.key,
    required this.elapsedSeconds,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final ValueNotifier<double> elapsedSeconds;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ValueListenableBuilder<double>(
            valueListenable: elapsedSeconds,
            builder: (context, time, child) {
              return CustomPaint(
                painter: SignalPanelPainter(time: time),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.russoOne(
                      color: const Color(0xfff5fffb),
                      fontSize: 34,
                      letterSpacing: 0,
                      shadows: const [
                        Shadow(color: Color(0xff26f2df), blurRadius: 18),
                        Shadow(color: Color(0xff5a7dff), blurRadius: 34),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _OverlayActionButton(label: actionLabel, onPressed: onAction),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  const _OverlayActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff2ee6c8),
        foregroundColor: const Color(0xff031014),
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
