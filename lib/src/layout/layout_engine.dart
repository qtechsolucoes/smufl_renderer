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

/// Cursor de layout que gerencia posicionamento e quebras de sistema
class LayoutCursor {
  final double staffSpace;
  final double availableWidth;
  final double systemMargin;
  final double systemHeight;

  double _currentX;
  double _currentY;
  int _currentSystem;
  bool _isFirstMeasureInSystem;

  LayoutCursor({
    required this.staffSpace,
    required this.availableWidth,
    required this.systemMargin,
    this.systemHeight = 10.0,
  })  : _currentX = systemMargin,
        _currentY = staffSpace * 4.0,
        _currentSystem = 0,
        _isFirstMeasureInSystem = true;

  // Getters
  double get currentX => _currentX;
  double get currentY => _currentY;
  int get currentSystem => _currentSystem;
  bool get isFirstMeasureInSystem => _isFirstMeasureInSystem;
  double get usableWidth => availableWidth - (systemMargin * 2);

  /// Avança o cursor pela largura especificada
  void advance(double width) {
    _currentX += width;
  }

  /// Verifica se precisa de quebra de sistema
  bool needsSystemBreak(double measureWidth) {
    if (_isFirstMeasureInSystem) return false;
    return _currentX + measureWidth > systemMargin + usableWidth;
  }

  /// Inicia um novo sistema
  void startNewSystem() {
    _currentSystem++;
    _currentX = systemMargin;
    _currentY += systemHeight * staffSpace;
    _isFirstMeasureInSystem = true;
  }

  /// Adiciona uma barra de compasso
  void addBarline(List<PositionedElement> elements) {
    elements.add(PositionedElement(
      Barline(),
      Offset(_currentX, _currentY),
      system: _currentSystem,
    ));
    advance(LayoutEngine.barlineSeparation * staffSpace);
  }

  /// Finaliza um compasso
  void endMeasure() {
    _isFirstMeasureInSystem = false;
    advance(LayoutEngine.measureEndPadding * staffSpace);
  }

  /// Adiciona um elemento na posição atual
  void addElement(MusicalElement element, List<PositionedElement> elements) {
    elements.add(PositionedElement(
      element,
      Offset(_currentX, _currentY),
      system: _currentSystem,
    ));
  }
}

/// Motor de layout responsável por calcular posições dos elementos musicais
/// usando um sistema baseado em cursor para espaçamento consistente
class LayoutEngine {
  final Staff staff;
  final double availableWidth;
  final double staffSpace;

  // Espaçamentos baseados no metadata oficial do Bravura (em staff spaces)
  static const double gClefWidth = 2.684;
  static const double fClefWidth = 2.756;
  static const double cClefWidth = 2.796;
  static const double noteheadBlackWidth = 1.18;
  static const double accidentalSharpWidth = 1.116;
  static const double accidentalFlatWidth = 1.18;
  static const double barlineSeparation = 0.4;
  static const double legerLineExtension = 0.4;

  // Configurações de espaçamento simplificadas
  static const double systemMargin = 2.0;
  static const double measureMinWidth = 4.0;
  static const double noteMinSpacing = 1.5;
  static const double measureEndPadding = 1.0;

  LayoutEngine(
    this.staff, {
    required this.availableWidth,
    this.staffSpace = 12.0,
  });

  /// Calcula o layout de todos os elementos usando sistema baseado em cursor
  List<PositionedElement> layout() {
    final cursor = LayoutCursor(
      staffSpace: staffSpace,
      availableWidth: availableWidth,
      systemMargin: systemMargin * staffSpace,
    );

    final List<PositionedElement> positionedElements = [];

    // Processar cada compasso
    for (int i = 0; i < staff.measures.length; i++) {
      final measure = staff.measures[i];
      final isFirst = cursor.isFirstMeasureInSystem;
      final isLast = i == staff.measures.length - 1;

      // Calcular largura necessária do compasso
      final measureWidth = _calculateMeasureWidthCursor(measure, isFirst);

      // Verificar quebra de sistema
      if (cursor.needsSystemBreak(measureWidth)) {
        cursor.startNewSystem();
      }

      // Layout do compasso usando cursor
      _layoutMeasureCursor(
        measure,
        cursor,
        positionedElements,
        isFirst,
      );

      // Adicionar barra de compasso se não for o último
      if (!isLast) {
        cursor.addBarline(positionedElements);
      }

      cursor.endMeasure();
    }

    return positionedElements;
  }

  /// Calcula a largura necessária para um compasso (versão simplificada)
  double _calculateMeasureWidthCursor(Measure measure, bool isFirstInSystem) {
    double totalWidth = 0;
    int musicalElementCount = 0;

    for (final element in measure.elements) {
      // Pular elementos de sistema se não for o primeiro compasso
      if (!isFirstInSystem && _isSystemElement(element)) {
        continue;
      }

      totalWidth += _getElementWidthSimple(element);

      // Contar elementos musicais para espaçamento
      if (element is Note || element is Rest || element is Chord) {
        musicalElementCount++;
      }
    }

    // Adicionar espaçamento entre elementos musicais
    if (musicalElementCount > 1) {
      totalWidth += (musicalElementCount - 1) * noteMinSpacing * staffSpace;
    }

    // Garantir largura mínima
    final minWidth = measureMinWidth * staffSpace;
    return totalWidth < minWidth ? minWidth : totalWidth;
  }

  /// Layout de um compasso usando o sistema de cursor
  void _layoutMeasureCursor(
    Measure measure,
    LayoutCursor cursor,
    List<PositionedElement> positionedElements,
    bool isFirstInSystem,
  ) {
    // Processar elementos considerando beams com configurações do compasso
    final processedElements = _processBeams(
      measure.elements,
      autoBeaming: measure.autoBeaming,
      beamingMode: measure.beamingMode,
      manualBeamGroups: measure.manualBeamGroups,
    );

    // Filtrar elementos que serão renderizados
    final elementsToRender = processedElements.where((element) {
      return isFirstInSystem || !_isSystemElement(element);
    }).toList();

    if (elementsToRender.isEmpty) return;

    // Separar elementos de sistema dos musicais
    final systemElements = <MusicalElement>[];
    final musicalElements = <MusicalElement>[];

    for (final element in elementsToRender) {
      if (_isSystemElement(element)) {
        systemElements.add(element);
      } else {
        musicalElements.add(element);
      }
    }

    // 1. Posicionar elementos de sistema primeiro
    for (final element in systemElements) {
      cursor.addElement(element, positionedElements);
      cursor.advance(_getElementWidthSimple(element));
    }

    // Adicionar espaçamento inteligente após elementos de sistema
    if (systemElements.isNotEmpty) {
      final spacingAfterSystem = _calculateSpacingAfterSystemElements(
        systemElements,
        musicalElements,
      );
      cursor.advance(spacingAfterSystem);
    }

    // 2. Posicionar elementos musicais com espaçamento consistente
    for (int i = 0; i < musicalElements.length; i++) {
      final element = musicalElements[i];

      // Adicionar espaçamento antes do elemento (exceto o primeiro)
      if (i > 0) {
        cursor.advance(noteMinSpacing * staffSpace);
      }

      cursor.addElement(element, positionedElements);
      cursor.advance(_getElementWidthSimple(element));
    }
  }

  /// Verifica se é um elemento de sistema (clave, armadura, fórmula)
  bool _isSystemElement(MusicalElement element) {
    return element is Clef ||
        element is KeySignature ||
        element is TimeSignature;
  }

  /// Calcula espaçamento inteligente após elementos de sistema
  double _calculateSpacingAfterSystemElements(
    List<MusicalElement> systemElements,
    List<MusicalElement> musicalElements,
  ) {
    // Espaçamento base após elementos de sistema
    double baseSpacing = staffSpace * 1.5; // Aumentado de 1.0 para 1.5

    // Verificar se há clave (elemento mais provável de causar sobreposição)
    bool hasClef = systemElements.any((e) => e is Clef);
    if (hasClef) {
      baseSpacing = staffSpace * 2.0; // Espaço extra após clave
    }

    // Verificar se há armadura de clave com muitos acidentes
    for (final element in systemElements) {
      if (element is KeySignature && element.count.abs() >= 4) {
        baseSpacing += staffSpace * 0.5; // Espaço extra para armaduras complexas
      }
    }

    // Verificar se a primeira nota musical tem acidente
    if (musicalElements.isNotEmpty) {
      final firstMusicalElement = musicalElements.first;
      if (firstMusicalElement is Note && firstMusicalElement.pitch.accidentalGlyph != null) {
        // Adicionar espaço extra para evitar sobreposição do acidente com a clave
        baseSpacing += staffSpace * 1.0;
      }
    }

    // Espaçamento mínimo e máximo para manter proporções
    return baseSpacing.clamp(staffSpace * 1.5, staffSpace * 4.0);
  }

  /// Calcula largura simplificada de um elemento
  double _getElementWidthSimple(MusicalElement element) {
    if (element is Clef) {
      // Largura do glifo + espaçamento após a clave
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
        default:
          clefWidth = cClefWidth;
      }
      // Adicionar pequeno espaçamento após a clave (0.5 staff spaces)
      return (clefWidth + 0.5) * staffSpace;
    }

    if (element is KeySignature) {
      if (element.count == 0) return 0.5 * staffSpace;
      final accidentalWidth = element.count > 0
          ? accidentalSharpWidth
          : accidentalFlatWidth;
      return (element.count.abs() * 0.8 + accidentalWidth) * staffSpace;
    }

    if (element is TimeSignature) {
      return 3.0 * staffSpace;
    }

    if (element is Note) {
      double width = noteheadBlackWidth * staffSpace;
      if (element.pitch.accidentalGlyph != null) {
        final accWidth = element.pitch.accidentalGlyph!.contains('Sharp')
            ? accidentalSharpWidth
            : accidentalFlatWidth;
        width += (accWidth + 0.3) * staffSpace;
      }
      return width;
    }

    if (element is Rest) {
      return 1.5 * staffSpace;
    }

    if (element is Chord) {
      double width = noteheadBlackWidth * staffSpace;
      double maxAccidentalWidth = 0;

      for (final note in element.notes) {
        if (note.pitch.accidentalGlyph != null) {
          final accWidth = note.pitch.accidentalGlyph!.contains('Sharp')
              ? accidentalSharpWidth
              : accidentalFlatWidth;
          if (accWidth > maxAccidentalWidth) {
            maxAccidentalWidth = accWidth;
          }
        }
      }

      if (maxAccidentalWidth > 0) {
        width += (maxAccidentalWidth + 0.3) * staffSpace;
      }
      return width;
    }

    if (element is Dynamic) return 2.0 * staffSpace;
    if (element is Ornament) return 1.0 * staffSpace;

    return staffSpace; // Padrão
  }


  /// Processa grupos de notas com barras de ligação (beams) usando lógica inteligente
  List<MusicalElement> _processBeams(List<MusicalElement> elements, {
    bool autoBeaming = true,
    BeamingMode beamingMode = BeamingMode.automatic,
    List<List<int>> manualBeamGroups = const [],
  }) {
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

    // Usar nova lógica inteligente de agrupamento com controles
    final beamGroups = BeamGrouper.groupNotesForBeaming(
      notes,
      timeSignature,
      autoBeaming: autoBeaming,
      beamingMode: beamingMode,
      manualBeamGroups: manualBeamGroups,
    );

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

}
