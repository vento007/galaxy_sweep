import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartGameOverlay extends StatelessWidget {
  const StartGameOverlay({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.34),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _GalaxySweepWordmark(),
              const SizedBox(height: 28),
              _OverlayActionButton(label: 'Start Game', onPressed: onStart),
            ],
          ),
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onRestart,
  });

  final int score;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return GameOverlayPanel(
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
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.russoOne(
                    color: Color(0xfff5fffb),
                    fontSize: 32,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 26),
                _OverlayActionButton(label: actionLabel, onPressed: onAction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GalaxySweepWordmark extends StatelessWidget {
  const _GalaxySweepWordmark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Galaxy Sweep',
      textAlign: TextAlign.center,
      style: GoogleFonts.russoOne(
        color: Color(0xfff5fffb),
        fontSize: 42,
        letterSpacing: 0,
        shadows: const [
          Shadow(color: Color(0xff26f2df), blurRadius: 18),
          Shadow(color: Color(0xff5a7dff), blurRadius: 34),
        ],
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
