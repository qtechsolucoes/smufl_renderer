// lib/smufl_renderer.dart
import 'package:flutter/material.dart';
import 'src/layout/layout_engine.dart';
import 'src/music_model/musical_element.dart';
import 'src/rendering/music_painter.dart';
import 'src/smufl/smufl_metadata_loader.dart';
import 'src/theme/music_score_theme.dart';

export 'src/music_model/musical_element.dart';
export 'src/theme/music_score_theme.dart';
export 'src/layout/layout_engine.dart'; // Exporta a classe PositionedElement

class MusicScore extends StatefulWidget {
  final Staff staff;
  final MusicScoreTheme theme;

  const MusicScore({
    super.key,
    required this.staff,
    this.theme = const MusicScoreTheme(),
  });

  @override
  State<MusicScore> createState() => _MusicScoreState();
}

class _MusicScoreState extends State<MusicScore> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SmuflMetadata().load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Chama o construtor do LayoutEngine corretamente
            final layoutEngine = LayoutEngine(
              widget.staff,
              availableWidth: constraints.maxWidth,
            );
            final positionedElements = layoutEngine.layout();

            final lastSystem = positionedElements.isNotEmpty
                ? positionedElements.last.system
                : 0;
            final totalHeight = 150.0 + (lastSystem * 120.0);

            return SizedBox(
              height: totalHeight,
              child: CustomPaint(
                size: Size.infinite,
                painter: MusicPainter(
                  positionedElements: positionedElements,
                  metadata: SmuflMetadata(),
                  theme: widget.theme,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
