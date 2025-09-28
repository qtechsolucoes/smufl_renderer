// lib/src/layout/layout_engine.dart

import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';
import 'beam_grouper.dart';

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

  // Espaçamentos baseados no metadata oficial do Bravura (em staff spaces)

  // Larguras oficiais dos glifos do Bravura metadata
  static const double gClefWidth = 2.684; // gClef bounding box width
  static const double fClefWidth = 2.756; // fClef bounding box width (2.736 - (-0.02))
  static const double cClefWidth = 2.796; // cClef bounding box width
  static const double noteheadBlackWidth = 1.18; // noteheadBlack official width
  static const double accidentalSharpWidth = 1.116; // accidentalSharp width
  static const double accidentalFlatWidth = 1.18; // accidentalFlat width

  // Valores oficiais do metadata Bravura engravingDefaults
  static const double barlineSeparation = 0.4; // barlineSeparation oficial
  static const double legerLineExtension = 0.4; // legerLineExtension oficial

  // --- As variáveis abaixo são regras de layout e não valores diretos do SMuFL ---

  // Um valor estilístico para o respiro mínimo entre as notas. 2.0 é uma boa escolha.
  static const double minNoteSpacing = 2.0;

  // Um valor estilístico para o preenchimento do compasso. 1.5 é uma boa escolha.
  static const double measurePadding = 1.5;

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
        currentX += barlineSeparation * staffSpace;
      }

      // Adicionar espaçamento entre compassos
      currentX += measurePadding * staffSpace;

      firstMeasureInSystem = false;
    }

    return positionedElements;
  }

  /// Calcula a largura necessária para um compasso de forma inteligente
  double _calculateMeasureWidth(Measure measure, bool isFirstInSystem) {
    double baseWidth = 0;
    int noteCount = 0;
    double totalDurationValue = 0;

    // Processar elementos considerando se é o primeiro compasso
    for (int i = 0; i < measure.elements.length; i++) {
      final element = measure.elements[i];

      // Pular elementos de sistema se não for o primeiro compasso
      if (!isFirstInSystem && _isSystemElement(element)) {
        continue;
      }

      baseWidth += _getElementWidth(element);

      // Contar elementos musicais para análise de densidade
      if (element is Note) {
        noteCount++;
        totalDurationValue += element.duration.realValue;
      } else if (element is Chord) {
        noteCount++;
        totalDurationValue += element.duration.realValue;
      } else if (element is Rest) {
        noteCount++;
        totalDurationValue += element.duration.realValue;
      }
    }

    // Sistema inteligente de espaçamento baseado na densidade
    double intelligentWidth = _calculateIntelligentSpacing(
      baseWidth,
      noteCount,
      totalDurationValue,
      isFirstInSystem,
    );

    return intelligentWidth;
  }

  /// Calcula espaçamento inteligente baseado na densidade musical
  double _calculateIntelligentSpacing(
    double baseWidth,
    int noteCount,
    double totalDurationValue,
    bool isFirstInSystem,
  ) {
    // Largura mínima base - considerar espaçamentos inicial e final
    double minWidth = isFirstInSystem
        ? staffSpace * 8   // Primeiro compasso: clave + armadura + tempo + espaço
        : staffSpace * 4.5; // Compassos subsequentes: espaço inicial + conteúdo + espaço final

    // Fator de densidade: mais notas = mais espaço necessário
    double densityFactor = 1.0;
    if (noteCount > 0) {
      // Calcular densidade média (durações menores = maior densidade)
      double averageDuration = totalDurationValue / noteCount;

      // Fator baseado na duração média das notas
      if (averageDuration <= 0.25) { // Semicolcheias e menores
        densityFactor = 1.8;
      } else if (averageDuration <= 0.5) { // Colcheias
        densityFactor = 1.5;
      } else if (averageDuration <= 1.0) { // Semínimas
        densityFactor = 1.2;
      } else { // Mínimas e maiores
        densityFactor = 1.0;
      }

      // Ajuste adicional para quantidade de elementos
      if (noteCount > 8) {
        densityFactor *= 1.3;
      } else if (noteCount > 4) {
        densityFactor *= 1.15;
      }
    }

    // Aplicar fator de densidade à largura base
    double adjustedWidth = baseWidth * densityFactor;

    // Garantir largura mínima para legibilidade
    return adjustedWidth < minWidth ? minWidth : adjustedWidth;
  }

  /// Verifica se é um elemento de sistema (clave, armadura, fórmula)
  bool _isSystemElement(MusicalElement element) {
    return element is Clef ||
        element is KeySignature ||
        element is TimeSignature;
  }

  /// Calcula a largura de um elemento específico usando valores oficiais Bravura
  double _getElementWidth(MusicalElement element) {
    if (element is Clef) {
      // Usar largura correta baseada no tipo de clave
      double clefWidth;
      switch (element.actualClefType) {
        case ClefType.treble:
        case ClefType.treble8va:
        case ClefType.treble8vb:
        case ClefType.treble15ma:
        case ClefType.treble15mb:
          clefWidth = gClefWidth;
          break;
        case ClefType.bass:
        case ClefType.bassThirdLine:
        case ClefType.bass8va:
        case ClefType.bass8vb:
        case ClefType.bass15ma:
        case ClefType.bass15mb:
          clefWidth = fClefWidth;
          break;
        case ClefType.soprano:
        case ClefType.mezzoSoprano:
        case ClefType.alto:
        case ClefType.tenor:
        case ClefType.baritone:
        case ClefType.c8vb:
          clefWidth = cClefWidth;
          break;
        default:
          clefWidth = gClefWidth;
      }
      return (clefWidth + 0.5) * staffSpace; // Clave + espaço oficial
    } else if (element is KeySignature) {
      if (element.count == 0) {
        return 0.3 * staffSpace; // Espaço mínimo sem acidentes
      }
      // Usar largura oficial dos acidentes + espaçamento compacto
      final isSharp = element.count > 0;
      final accidentalWidth = isSharp ? accidentalSharpWidth : accidentalFlatWidth;
      final spacing = 0.8; // Espaçamento padrão entre acidentes
      // Espaçamento mais compacto após a armadura
      return (element.count.abs() * spacing + accidentalWidth + 0.3) * staffSpace;
    } else if (element is TimeSignature) {
      return 4.5 * staffSpace; // Fórmula de compasso + espaço generoso para primeira nota
    } else if (element is Note) {
      double width = 0;

      // Espaço para acidente se presente (valor oficial)
      if (element.pitch.accidentalGlyph != null) {
        final accidentalWidth = element.pitch.accidentalGlyph!.contains('Sharp')
            ? accidentalSharpWidth
            : accidentalFlatWidth;
        width += (accidentalWidth + 0.3) * staffSpace; // Acidente + espaçamento
      }

      // Largura oficial da cabeça da nota
      width += noteheadBlackWidth * staffSpace;

      // Espaçamento baseado na duração
      width += _getDurationSpacing(element.duration) * staffSpace;

      return width;
    } else if (element is Rest) {
      // Pausas precisam de espaço baseado na duração
      return (1.0 + _getDurationSpacing(element.duration)) * staffSpace;
    } else if (element is Chord) {
      double width = noteheadBlackWidth * staffSpace;

      // Verificar se alguma nota tem acidente e usar largura correta
      bool hasAccidental = false;
      double maxAccidentalWidth = 0;
      for (final note in element.notes) {
        if (note.pitch.accidentalGlyph != null) {
          hasAccidental = true;
          final accWidth = note.pitch.accidentalGlyph!.contains('Sharp')
              ? accidentalSharpWidth
              : accidentalFlatWidth;
          if (accWidth > maxAccidentalWidth) {
            maxAccidentalWidth = accWidth;
          }
        }
      }

      if (hasAccidental) {
        width += (maxAccidentalWidth + 0.3) * staffSpace;
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

  /// Retorna o espaçamento baseado na duração real (incluindo pontos)
  double _getDurationSpacing(Duration duration) {
    // Espaçamento baseado na duração real, com ajuste logarítmico para visualização
    final realValue = duration.realValue;

    // Fórmula logarítmica: quanto maior a duração, mais espaço (mas não linear)
    // Base: semínima (0.25) = 2.0 staff spaces
    double spacing = 2.0 * (realValue / 0.25);

    // Aplicar compressão logarítmica para evitar espaços excessivos
    spacing = 1.0 + (spacing - 1.0) * 0.7;

    // Limitar valores mínimos e máximos
    return spacing.clamp(1.0, 5.0);
  }

  /// Layout de um compasso completo com distribuição inteligente
  double _layoutMeasure(
    Measure measure,
    List<PositionedElement> positionedElements,
    double startX,
    double y,
    int system,
    bool isFirstInSystem,
  ) {
    // Processar elementos considerando beams
    final processedElements = _processBeams(measure.elements);

    // Filtrar elementos que serão renderizados
    final elementsToRender = processedElements.where((element) {
      return isFirstInSystem || !_isSystemElement(element);
    }).toList();

    if (elementsToRender.isEmpty) return startX;

    // Calcular largura total do compasso
    final totalMeasureWidth = _calculateMeasureWidth(measure, isFirstInSystem);

    // Separar elementos de sistema dos elementos musicais
    final systemElements = <MusicalElement>[];
    final musicalElements = <MusicalElement>[];

    for (final element in elementsToRender) {
      if (_isSystemElement(element)) {
        systemElements.add(element);
      } else {
        musicalElements.add(element);
      }
    }

    double currentX = startX;

    // 1. Posicionar elementos de sistema primeiro (clave, armadura, tempo)
    for (final element in systemElements) {
      positionedElements.add(
        PositionedElement(element, Offset(currentX, y), system: system),
      );
      currentX += _getElementWidth(element);
    }

    // 2. Distribuir elementos musicais proporcionalmente no espaço restante
    if (musicalElements.isNotEmpty) {
      // Adicionar espaçamento inicial para todos os compassos (não só o primeiro)
      final initialSpacing = isFirstInSystem ? 0 : staffSpace * 1.5; // Espaço após barra de compasso

      // Espaçamento final muito reduzido para evitar excesso antes da barra
      final noteCount = musicalElements.where((e) => e is Note || e.runtimeType.toString() == 'Chord').length;
      double finalSpacing;

      if (noteCount >= 6) {
        finalSpacing = staffSpace * 0.15; // Compassos densos: espaçamento mínimo
      } else if (noteCount >= 4) {
        finalSpacing = staffSpace * 0.2; // Densidade média
      } else if (noteCount >= 2) {
        finalSpacing = staffSpace * 0.25; // Poucos elementos
      } else {
        finalSpacing = staffSpace * 0.3; // Compasso muito simples
      }

      currentX += initialSpacing;

      // Calcular espaço disponível considerando o espaçamento final
      final availableSpace = totalMeasureWidth - (currentX - startX) - finalSpacing;
      final spaceBetweenNotes = _calculateOptimalSpacing(
        musicalElements,
        availableSpace,
      );

      for (int i = 0; i < musicalElements.length; i++) {
        final element = musicalElements[i];

        // Aplicar espaçamento proporcional
        if (i > 0) {
          currentX += spaceBetweenNotes;
        }

        positionedElements.add(
          PositionedElement(element, Offset(currentX, y), system: system),
        );

        // Avançar pela largura mínima do elemento
        currentX += _getMinimalElementWidth(element);
      }

      // Adicionar espaçamento no final do compasso para garantir distância da próxima barra
      currentX += finalSpacing;
    }

    return startX + totalMeasureWidth;
  }

  /// Calcula espaçamento ótimo entre elementos musicais
  double _calculateOptimalSpacing(
    List<MusicalElement> elements,
    double availableSpace,
  ) {
    if (elements.length <= 1) return 0;

    // Calcular largura mínima total dos elementos
    double totalMinimalWidth = 0;
    for (final element in elements) {
      totalMinimalWidth += _getMinimalElementWidth(element);
    }

    // Espaço disponível para distribuição
    final spaceForDistribution = availableSpace - totalMinimalWidth;
    final gaps = elements.length - 1;

    if (gaps <= 0 || spaceForDistribution <= 0) {
      return staffSpace * 0.5; // Espaçamento mínimo
    }

    // Distribuir espaço uniformemente, com limites
    double spacing = spaceForDistribution / gaps;

    // Limites de espaçamento para manter legibilidade
    final minSpacing = staffSpace * 0.8;
    final maxSpacing = staffSpace * 4.0;

    return spacing.clamp(minSpacing, maxSpacing);
  }

  /// Retorna largura mínima de um elemento (sem espaçamento extra)
  double _getMinimalElementWidth(MusicalElement element) {
    if (element is Note) {
      double width = noteheadBlackWidth * staffSpace;
      if (element.pitch.accidentalGlyph != null) {
        final accidentalWidth = element.pitch.accidentalGlyph!.contains('Sharp')
            ? accidentalSharpWidth
            : accidentalFlatWidth;
        width += (accidentalWidth + 0.3) * staffSpace;
      }
      return width;
    } else if (element is Rest) {
      return staffSpace;
    } else if (element is Chord) {
      double width = noteheadBlackWidth * staffSpace;
      bool hasAccidental = false;
      double maxAccidentalWidth = 0;

      for (final note in element.notes) {
        if (note.pitch.accidentalGlyph != null) {
          hasAccidental = true;
          final accWidth = note.pitch.accidentalGlyph!.contains('Sharp')
              ? accidentalSharpWidth
              : accidentalFlatWidth;
          if (accWidth > maxAccidentalWidth) {
            maxAccidentalWidth = accWidth;
          }
        }
      }

      if (hasAccidental) {
        width += (maxAccidentalWidth + 0.3) * staffSpace;
      }
      return width;
    }

    return staffSpace * 0.5; // Padrão para outros elementos
  }

  /// Processa grupos de notas com barras de ligação (beams) usando lógica inteligente
  List<MusicalElement> _processBeams(List<MusicalElement> elements) {
    // Encontrar fórmula de compasso no compasso
    TimeSignature? timeSignature;
    for (final element in elements) {
      if (element is TimeSignature) {
        timeSignature = element;
        break;
      }
    }

    timeSignature ??= TimeSignature(numerator: 4, denominator: 4);

    // Extrair apenas as notas para agrupamento
    final notes = elements.whereType<Note>().toList();

    if (notes.isEmpty) return elements;

    // Usar nova lógica inteligente de agrupamento
    final beamGroups = BeamGrouper.groupNotesForBeaming(notes, timeSignature);

    // Aplicar agrupamento de beams às notas originais
    final processedElements = <MusicalElement>[];
    final processedNotes = <Note>{};

    for (final element in elements) {
      if (element is Note && !processedNotes.contains(element)) {
        // Verificar se esta nota faz parte de um grupo de beam
        BeamGroup? group;
        for (final beamGroup in beamGroups) {
          if (beamGroup.notes.contains(element)) {
            group = beamGroup;
            break;
          }
        }

        if (group != null && group.isValid) {
          // Processar todo o grupo
          for (int i = 0; i < group.notes.length; i++) {
            final note = group.notes[i];
            BeamType? beamType;

            if (i == 0) {
              beamType = BeamType.start;
            } else if (i == group.notes.length - 1) {
              beamType = BeamType.end;
            } else {
              beamType = BeamType.inner;
            }

            // Criar nova nota com informação de beam
            final beamedNote = Note(
              pitch: note.pitch,
              duration: note.duration,
              beam: beamType,
              articulations: note.articulations,
              tie: note.tie,
              slur: note.slur,
              ornaments: note.ornaments,
              dynamicElement: note.dynamicElement,
              techniques: note.techniques,
            );

            processedElements.add(beamedNote);
            processedNotes.add(note);
          }
        } else {
          // Nota isolada, manter como está
          processedElements.add(element);
          processedNotes.add(element);
        }
      } else if (element is! Note) {
        // Elementos que não são notas, manter como estão
        processedElements.add(element);
      }
    }

    return processedElements;
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
