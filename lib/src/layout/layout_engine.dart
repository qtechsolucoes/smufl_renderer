// lib/src/layout/layout_engine.dart

import 'dart:collection';
import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';

/// Uma classe para guardar um elemento e sua posição calculada.
class PositionedElement {
  final MusicalElement element;
  final Offset position;
  final int system;

  PositionedElement(this.element, this.position, {this.system = 0});
}

/// Motor de layout responsável por calcular posições dos elementos musicais
class LayoutEngine {
  final Staff staff;
  final double availableWidth;
  final double staffSpace;

  // Espaçamentos baseados em SMuFL/Bravura (em staff spaces)
  static const double clefWidth =
      3.2; // um pouco maior para não colar no sustenido
  static const double noteheadWidth = 1.25; // levemente maior, dá mais respiro
  static const double accidentalWidth =
      1.2; // garante que acidentes não fiquem esmagados
  static const double minNoteSpacing = 2.0; // mais espaçamento entre notas
  static const double barlineSpacing =
      0.8; // mais espaço antes da barra de compasso
  static const double measurePadding =
      1.5; // espaço extra no início e fim do compasso

  LayoutEngine(
    this.staff, {
    required this.availableWidth,
    this.staffSpace = 12.0,
  });

  /// Calcula o layout de todos os elementos
  List<PositionedElement> layout() {
    final List<PositionedElement> positionedElements = [];

    // Configurações de margem e espaçamento
    final double leftMargin = staffSpace * 2.0;
    final double rightMargin = staffSpace * 2.0;
    final double usableWidth = availableWidth - leftMargin - rightMargin;
    final double systemHeight = staffSpace * 10.0; // Altura entre sistemas

    double currentX = leftMargin;
    double currentY = staffSpace * 4.0; // Centro da primeira pauta
    int currentSystem = 0;

    // Flag para saber se é o primeiro compasso do sistema
    bool firstMeasureInSystem = true;

    // Processar cada compasso
    for (
      int measureIndex = 0;
      measureIndex < staff.measures.length;
      measureIndex++
    ) {
      final measure = staff.measures[measureIndex];

      // Calcular largura necessária para este compasso
      final measureWidth = _calculateMeasureWidth(
        measure,
        firstMeasureInSystem,
      );

      // Verificar se precisa quebrar linha (novo sistema)
      if (!firstMeasureInSystem &&
          currentX + measureWidth > leftMargin + usableWidth) {
        // Iniciar novo sistema
        currentSystem++;
        currentX = leftMargin;
        currentY += systemHeight;
        firstMeasureInSystem = true;
      }

      // Layout do compasso
      currentX = _layoutMeasure(
        measure,
        positionedElements,
        currentX,
        currentY,
        currentSystem,
        firstMeasureInSystem,
      );

      // Adicionar barra de compasso (exceto no último compasso)
      if (measureIndex < staff.measures.length - 1) {
        positionedElements.add(
          PositionedElement(
            Barline(),
            Offset(currentX, currentY),
            system: currentSystem,
          ),
        );
        currentX += barlineSpacing * staffSpace;
      }

      // Adicionar espaçamento entre compassos
      currentX += measurePadding * staffSpace;

      firstMeasureInSystem = false;
    }

    return positionedElements;
  }

  /// Calcula a largura necessária para um compasso
  double _calculateMeasureWidth(Measure measure, bool isFirstInSystem) {
    double width = 0;

    // Processar elementos considerando se é o primeiro compasso
    for (int i = 0; i < measure.elements.length; i++) {
      final element = measure.elements[i];

      // Pular elementos de sistema se não for o primeiro compasso
      if (!isFirstInSystem && _isSystemElement(element)) {
        continue;
      }

      width += _getElementWidth(element);
    }

    // Adicionar padding mínimo
    if (width < staffSpace * 4) {
      width = staffSpace * 4;
    }

    return width;
  }

  /// Verifica se é um elemento de sistema (clave, armadura, fórmula)
  bool _isSystemElement(MusicalElement element) {
    return element is Clef ||
        element is KeySignature ||
        element is TimeSignature;
  }

  /// Calcula a largura de um elemento específico
  double _getElementWidth(MusicalElement element) {
    if (element is Clef) {
      return (clefWidth + 1.0) * staffSpace; // Clave + espaço extra
    } else if (element is KeySignature) {
      if (element.count == 0) {
        return 0.5 * staffSpace; // Pequeno espaço mesmo sem acidentes
      }
      // Cada acidente ocupa ~0.8 staff spaces + espaço extra
      return (element.count.abs() * 0.8 + 1.0) * staffSpace;
    } else if (element is TimeSignature) {
      return 2.5 * staffSpace; // Fórmula de compasso + espaço
    } else if (element is Note) {
      double width = 0;

      // Espaço para acidente se presente
      if (element.pitch.accidentalGlyph != null) {
        width += accidentalWidth * staffSpace;
      }

      // Largura da cabeça da nota
      width += noteheadWidth * staffSpace;

      // Espaçamento baseado na duração
      width += _getDurationSpacing(element.duration) * staffSpace;

      return width;
    } else if (element is Rest) {
      // Pausas precisam de espaço baseado na duração
      return (1.0 + _getDurationSpacing(element.duration)) * staffSpace;
    } else if (element is Chord) {
      double width = noteheadWidth * staffSpace;

      // Verificar se alguma nota tem acidente
      for (final note in element.notes) {
        if (note.pitch.accidentalGlyph != null) {
          width += accidentalWidth * staffSpace;
          break; // Só precisa de espaço para um conjunto de acidentes
        }
      }

      width += _getDurationSpacing(element.duration) * staffSpace;
      return width;
    } else if (element is Dynamic) {
      return 2.0 * staffSpace;
    } else if (element is Ornament) {
      return 1.0 * staffSpace;
    }

    return staffSpace; // Valor padrão para elementos não reconhecidos
  }

  /// Retorna o espaçamento baseado na duração
  double _getDurationSpacing(Duration duration) {
    // Espaçamento proporcional logarítmico para melhor distribuição visual
    switch (duration.type) {
      case DurationType.whole:
        return 4.0;
      case DurationType.half:
        return 3.0;
      case DurationType.quarter:
        return 2.0;
      case DurationType.eighth:
        return 1.5;
      case DurationType.sixteenth:
        return 1.25;
    }
  }

  /// Layout de um compasso completo
  double _layoutMeasure(
    Measure measure,
    List<PositionedElement> positionedElements,
    double startX,
    double y,
    int system,
    bool isFirstInSystem,
  ) {
    double currentX = startX;

    // Processar elementos considerando beams
    final processedElements = _processBeams(measure.elements);

    for (final element in processedElements) {
      // Pular elementos de sistema se não for o primeiro compasso do sistema
      if (!isFirstInSystem && _isSystemElement(element)) {
        continue;
      }

      // Adicionar elemento posicionado
      positionedElements.add(
        PositionedElement(element, Offset(currentX, y), system: system),
      );

      // Avançar posição X
      currentX += _getElementWidth(element);
    }

    return currentX;
  }

  /// Processa grupos de notas com barras de ligação (beams)
  List<MusicalElement> _processBeams(List<MusicalElement> elements) {
    final List<MusicalElement> result = [];
    final queue = Queue<MusicalElement>.from(elements);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      if (current is Note && _isBeamable(current) && current.beam == null) {
        final beamGroup = <Note>[current];

        // Coletar todas as notas consecutivas que podem ser agrupadas
        while (queue.isNotEmpty) {
          final next = queue.first;
          if (next is Note && _isBeamable(next) && next.beam == null) {
            // CORREÇÃO AQUI:
            // Adicionamos 'next' (que já foi promovido para o tipo Note)
            // e depois removemos da fila.
            beamGroup.add(next);
            queue.removeFirst();
          } else {
            break;
          }
        }

        // Se temos mais de uma nota, criar grupo com beam
        if (beamGroup.length > 1) {
          for (int i = 0; i < beamGroup.length; i++) {
            BeamType beamType;
            if (i == 0) {
              beamType = BeamType.start;
            } else if (i == beamGroup.length - 1) {
              beamType = BeamType.end;
            } else {
              beamType = BeamType.inner;
            }

            result.add(_cloneNoteWithBeam(beamGroup[i], beamType));
          }
        } else {
          result.add(current);
        }
      } else {
        result.add(current);
      }
    }

    return result;
  }

  /// Verifica se uma nota pode ter beam
  bool _isBeamable(Note note) {
    // Notas com colcheia ou menor podem ter beam
    return note.duration.type == DurationType.eighth ||
        note.duration.type == DurationType.sixteenth;
  }

  /// Clona uma nota adicionando informação de beam
  Note _cloneNoteWithBeam(Note original, BeamType beamType) {
    return Note(
      pitch: original.pitch,
      duration: original.duration,
      beam: beamType,
      articulations: original.articulations,
      tie: original.tie,
      slur: original.slur,
      ornaments: original.ornaments,
      dynamicElement: original.dynamicElement,
      techniques: original.techniques,
    );
  }

  /// Calcula a altura total necessária para o layout
  double calculateTotalHeight(List<PositionedElement> elements) {
    if (elements.isEmpty) {
      return staffSpace * 8; // Altura mínima
    }

    // Encontrar o número máximo de sistemas
    int maxSystem = 0;
    for (final element in elements) {
      if (element.system > maxSystem) {
        maxSystem = element.system;
      }
    }

    // Calcular altura total
    final double systemHeight = staffSpace * 10.0;
    final double topMargin = staffSpace * 4.0;
    final double bottomMargin = staffSpace * 2.0;

    return topMargin + ((maxSystem + 1) * systemHeight) + bottomMargin;
  }

  /// Otimiza o espaçamento para distribuir melhor os elementos
  List<PositionedElement> optimizeSpacing(List<PositionedElement> elements) {
    if (elements.isEmpty) return elements;

    final Map<int, List<PositionedElement>> systemGroups = {};

    // Agrupar por sistema
    for (final element in elements) {
      systemGroups.putIfAbsent(element.system, () => []).add(element);
    }

    final List<PositionedElement> optimized = [];

    // Otimizar cada sistema
    for (final entry in systemGroups.entries) {
      final systemElements = entry.value;
      if (systemElements.isEmpty) continue;

      // Encontrar início e fim do sistema
      double minX = double.infinity;
      double maxX = double.negativeInfinity;

      for (final element in systemElements) {
        if (element.position.dx < minX) minX = element.position.dx;
        if (element.position.dx > maxX) maxX = element.position.dx;
      }

      // Calcular fator de expansão se necessário
      final systemWidth = maxX - minX;
      final targetWidth =
          availableWidth - (staffSpace * 4); // Margem de segurança

      if (systemWidth < targetWidth * 0.6) {
        // Sistema muito comprimido, expandir
        final scaleFactor = (targetWidth * 0.8) / systemWidth;

        for (final element in systemElements) {
          final newX = minX + ((element.position.dx - minX) * scaleFactor);
          optimized.add(
            PositionedElement(
              element.element,
              Offset(newX, element.position.dy),
              system: element.system,
            ),
          );
        }
      } else {
        // Sistema OK, manter como está
        optimized.addAll(systemElements);
      }
    }

    return optimized;
  }
}
