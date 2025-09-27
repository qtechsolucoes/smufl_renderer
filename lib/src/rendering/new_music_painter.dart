// lib/src/rendering/new_music_painter.dart

import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';
import 'staff_coordinate_system.dart';
import 'staff_renderer.dart';

/// Nova implementação do MusicPainter usando sistema de coordenadas correto
class NewMusicPainter extends CustomPainter {
  final List<PositionedElement> positionedElements;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double staffSpace;

  NewMusicPainter({
    required this.positionedElements,
    required this.metadata,
    required this.theme,
    this.staffSpace = 12.0, // Valor padrão apropriado
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (metadata.isNotLoaded || positionedElements.isEmpty) {
      return;
    }

    // Calcular posição da baseline da pauta
    final staffMargin = staffSpace * 2;
    final staffBaseline = Offset(
      staffMargin,
      staffMargin + (staffSpace * 2),
    ); // 3ª linha da pauta

    // Criar sistema de coordenadas

    // Sistema de coordenadas criado

    // Agrupar elementos por sistema
    final systemElements = _groupElementsBySystem();

    // Renderizar cada sistema
    for (final entry in systemElements.entries) {
      final systemIndex = entry.key;
      final elements = entry.value;

      final systemBaseline = Offset(
        staffMargin,
        staffBaseline.dy + (systemIndex * staffSpace * 10), // Espaçamento entre sistemas
      );

      final systemCoordinates = StaffCoordinateSystem(
        staffSpace: staffSpace,
        staffBaseline: systemBaseline,
      );

      final systemRenderer = StaffRenderer(
        coordinates: systemCoordinates,
        metadata: metadata,
        theme: theme,
      );

      systemRenderer.renderStaff(canvas, elements, size);
    }
  }

  Map<int, List<PositionedElement>> _groupElementsBySystem() {
    final Map<int, List<PositionedElement>> systems = {};

    for (final element in positionedElements) {
      final systemIndex = element.system;
      systems[systemIndex] ??= [];
      systems[systemIndex]!.add(element);
    }

    return systems;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! NewMusicPainter) return true;

    return oldDelegate.positionedElements != positionedElements ||
        oldDelegate.staffSpace != staffSpace ||
        oldDelegate.theme != theme;
  }
}
