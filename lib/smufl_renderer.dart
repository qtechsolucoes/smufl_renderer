// lib/smufl_renderer.dart

import 'package:flutter/material.dart';
import 'src/layout/layout_engine.dart';
import 'src/music_model/musical_element.dart';
import 'src/rendering/staff_renderer.dart';
import 'src/rendering/staff_coordinate_system.dart';
import 'src/smufl/smufl_metadata_loader.dart';
import 'src/theme/music_score_theme.dart';

export 'src/music_model/musical_element.dart';
export 'src/music_model/advanced_elements.dart';
export 'src/theme/music_score_theme.dart';
export 'src/layout/layout_engine.dart';
export 'src/parsers/json_parser.dart';
export 'src/smufl/glyph_categories.dart';
export 'src/smufl/smufl_metadata_loader.dart';

/// Widget principal para renderização de partituras musicais
class MusicScore extends StatefulWidget {
  final Staff staff;
  final MusicScoreTheme theme;
  final double staffSpace;

  const MusicScore({
    super.key,
    required this.staff,
    this.theme = const MusicScoreTheme(),
    this.staffSpace = 12.0, // Valor padrão otimizado para legibilidade
  });

  @override
  State<MusicScore> createState() => _MusicScoreState();
}

class _MusicScoreState extends State<MusicScore> {
  late Future<void> _metadataFuture;

  @override
  void initState() {
    super.initState();
    _metadataFuture = SmuflMetadata().load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _metadataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar metadados: ${snapshot.error}'),
          );
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Criar o motor de layout
            final layoutEngine = LayoutEngine(
              widget.staff,
              availableWidth: constraints.maxWidth,
              staffSpace: widget.staffSpace,
            );

            // Calcular posições dos elementos
            final positionedElements = layoutEngine.layout();

            if (positionedElements.isEmpty) {
              return const Center(child: Text('Partitura vazia'));
            }

            // Calcular altura necessária
            final totalHeight = _calculateTotalHeight(positionedElements);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, totalHeight),
                  painter: MusicScorePainter(
                    positionedElements: positionedElements,
                    metadata: SmuflMetadata(),
                    theme: widget.theme,
                    staffSpace: widget.staffSpace,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _calculateTotalHeight(List<PositionedElement> elements) {
    if (elements.isEmpty) return 200;

    // Encontrar o último sistema
    int maxSystem = 0;
    for (final element in elements) {
      if (element.system > maxSystem) {
        maxSystem = element.system;
      }
    }

    // Altura = margem superior + (número de sistemas * altura do sistema) + margem inferior
    final systemHeight = widget.staffSpace * 5; // Altura de cada sistema
    final margins = widget.staffSpace * 2; // Margens superior e inferior

    return margins + ((maxSystem + 2) * systemHeight);
  }
}

/// Painter customizado para renderização da partitura
class MusicScorePainter extends CustomPainter {
  final List<PositionedElement> positionedElements;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double staffSpace;

  MusicScorePainter({
    required this.positionedElements,
    required this.metadata,
    required this.theme,
    required this.staffSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Agrupar elementos por sistema
    final Map<int, List<PositionedElement>> systemGroups = {};

    for (final element in positionedElements) {
      systemGroups.putIfAbsent(element.system, () => []).add(element);
    }

    // Renderizar cada sistema
    for (final entry in systemGroups.entries) {
      final systemIndex = entry.key;
      final elements = entry.value;

      // Calcular posição base do sistema
      final systemY = (systemIndex * staffSpace * 10) + (staffSpace * 5);
      final staffBaseline = Offset(0, systemY);

      // Criar sistema de coordenadas para este sistema
      final coordinates = StaffCoordinateSystem(
        staffSpace: staffSpace,
        staffBaseline: staffBaseline,
      );

      // Criar renderizador
      final renderer = StaffRenderer(
        coordinates: coordinates,
        metadata: metadata,
        theme: theme,
      );

      // Renderizar o sistema
      renderer.renderStaff(canvas, elements, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! MusicScorePainter) return true;

    return oldDelegate.positionedElements.length != positionedElements.length ||
        oldDelegate.theme != theme ||
        oldDelegate.staffSpace != staffSpace;
  }
}
