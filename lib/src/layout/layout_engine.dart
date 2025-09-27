// lib/src/layout/layout_engine.dart
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';

/// Uma classe para guardar um elemento e sua posição calculada.
class PositionedElement {
  final MusicalElement element;
  final Offset position;
  final int system; // A qual "linha" de pauta ele pertence

  PositionedElement(this.element, this.position, {this.system = 0});
}

class LayoutEngine {
  final Staff staff;
  final double availableWidth;

  // Espaçamentos profissionais baseados no padrão SMuFL - OTIMIZADO
  static const double quarterNoteSpace = 24.0; // Espaço base para semínima (aumentado)
  static const double clefSpace = 35.0; // Espaço após clave (aumentado)
  static const double keySignatureSpace = 18.0; // Espaço para armadura (aumentado)
  static const double timeSignatureSpace = 28.0; // Espaço para fórmula de compasso (aumentado)
  static const double barlineSpace = 20.0; // Espaço para barra de compasso (aumentado)
  static const double minimumNoteSpace = 12.0; // Espaçamento mínimo entre notas (aumentado)
  static const double accidentalSpace = 16.0; // Espaço para acidentes
  static const double ornamentSpace = 8.0; // Espaço para ornamentos
  static const double dynamicSpace = 10.0; // Espaço para dinâmicas

  LayoutEngine(this.staff, {required this.availableWidth});

  List<PositionedElement> layout() {
    final List<PositionedElement> positionedElements = [];
    double cursorX = 10.0;
    double cursorY = 100.0;
    int currentSystem = 0;

    for (final measure in staff.measures) {
      // --- Início da Lógica de Agrupamento de Barras (Beaming) ---
      final processedElements = _processBeams(measure.elements);
      // --- Fim da Lógica de Agrupamento de Barras (Beaming) ---

      // Calcula a largura ideal do compasso com espaçamentos profissionais
      double idealMeasureWidth = 0;
      final Map<MusicalElement, double> elementWidths = {};

      for (final element in processedElements) {
        double width = 0;

        if (element is Note) {
          // Espaçamento inteligente baseado na duração e contexto
          double baseWidth = quarterNoteSpace * element.duration.type.value;

          // Adiciona espaço para acidentes
          if (element.pitch.accidentalGlyph != null) {
            baseWidth += accidentalSpace;
          }

          // Adiciona espaço para ornamentos
          if (element.ornaments.isNotEmpty) {
            baseWidth += ornamentSpace * element.ornaments.length;
          }

          // Adiciona espaço para articulações
          if (element.articulations.isNotEmpty) {
            baseWidth += 6.0;
          }

          width = math.max(baseWidth, minimumNoteSpace);

        } else if (element is Rest) {
          width = math.max(
            quarterNoteSpace * element.duration.type.value * 0.8, // Pausas são mais compactas
            minimumNoteSpace
          );

        } else if (element is Chord) {
          // Acordes precisam de mais espaço
          double baseWidth = quarterNoteSpace * element.duration.type.value * 1.2;

          // Adiciona espaço para ornamentos
          if (element.ornaments.isNotEmpty) {
            baseWidth += ornamentSpace * element.ornaments.length;
          }

          width = math.max(baseWidth, minimumNoteSpace * 1.5);

        } else if (element is Clef) {
          width = clefSpace;

        } else if (element is KeySignature) {
          if (element.count == 0) {
            width = 8.0; // Espaço mínimo mesmo sem acidentes
          } else {
            width = keySignatureSpace + (element.count.abs() * 10.0); // Espaçamento melhorado
          }

        } else if (element is TimeSignature) {
          width = timeSignatureSpace;

        } else if (element is Dynamic) {
          width = dynamicSpace;

        } else if (element is Ornament) {
          width = ornamentSpace;

        } else if (element is TempoMark) {
          width = 40.0; // Espaço para marcas de tempo

        } else if (element is MusicText) {
          width = 25.0; // Espaço para texto musical

        } else if (element is Tuplet) {
          // Quiálteras precisam de espaço adicional
          double tupletWidth = 0;
          for (final note in element.notes) {
            tupletWidth += quarterNoteSpace * note.duration.type.value * 0.9;
          }
          width = math.max(tupletWidth, minimumNoteSpace * element.notes.length);
        }

        elementWidths[element] = width;
        idealMeasureWidth += elementWidths[element]!;
      }

      if (cursorX + idealMeasureWidth > availableWidth &&
          measure != staff.measures.first) {
        cursorX = 10.0;
        currentSystem++;
        cursorY += 120.0;
      }

      for (final element in processedElements) {
        positionedElements.add(
          PositionedElement(
            element,
            Offset(cursorX, cursorY),
            system: currentSystem,
          ),
        );
        cursorX += elementWidths[element]!;
      }

      positionedElements.add(
        PositionedElement(
          Barline(),
          Offset(cursorX, cursorY),
          system: currentSystem,
        ),
      );
      cursorX += barlineSpace;
    }
    return positionedElements;
  }

  /// Processa uma lista de elementos para identificar e marcar grupos de notas
  /// que devem ser conectadas por barras de ligação.
  List<MusicalElement> _processBeams(List<MusicalElement> elements) {
    final List<MusicalElement> result = [];
    final queue = Queue<MusicalElement>.from(elements);

    while (queue.isNotEmpty) {
      final current = queue.first;

      if (current is Note && _isBeamable(current)) {
        // Encontramos o início de um possível grupo de barras
        final beamGroup = <Note>[];
        beamGroup.add(queue.removeFirst() as Note);

        // Olha para frente na fila para encontrar outras notas conectáveis
        while (queue.isNotEmpty &&
            queue.first is Note &&
            _isBeamable(queue.first as Note)) {
          beamGroup.add(queue.removeFirst() as Note);
        }

        // Se o grupo tem mais de uma nota, marca-as para ligação
        if (beamGroup.length > 1) {
          result.add(_cloneNoteWithBeam(beamGroup.first, BeamType.start));
          for (int i = 1; i < beamGroup.length - 1; i++) {
            result.add(_cloneNoteWithBeam(beamGroup[i], BeamType.inner));
          }
          result.add(_cloneNoteWithBeam(beamGroup.last, BeamType.end));
        } else {
          // Grupo de uma nota só, adiciona de volta sem marcação de barra
          result.addAll(beamGroup);
        }
      } else {
        // Elemento não conectável, apenas o move para o resultado
        result.add(queue.removeFirst());
      }
    }
    return result;
  }

  /// Verifica se uma nota tem uma duração que permite ligação por barra.
  bool _isBeamable(Note note) {
    return note.duration.type == DurationType.eighth ||
        note.duration.type == DurationType.sixteenth;
  }

  /// Cria um clone de uma nota, aplicando o tipo de barra.
  Note _cloneNoteWithBeam(Note original, BeamType beamType) {
    return Note(
      pitch: original.pitch,
      duration: original.duration,
      beam: beamType,
      articulations: original.articulations,
      tie: original.tie,
      slur: original.slur,
    );
  }
}
