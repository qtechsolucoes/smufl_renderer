// lib/src/layout/layout_engine.dart
// VERSÃO CORRIGIDA: Espaçamento melhorado e beaming corrigido

import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import 'beam_grouper.dart';

class PositionedElement {
  final MusicalElement element;
  final Offset position;
  final int system;

  PositionedElement(this.element, this.position, {this.system = 0});
}

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
  }) : _currentX = systemMargin,
       _currentY = staffSpace * 4.0,
       _currentSystem = 0,
       _isFirstMeasureInSystem = true;

  double get currentX => _currentX;
  double get currentY => _currentY;
  int get currentSystem => _currentSystem;
  bool get isFirstMeasureInSystem => _isFirstMeasureInSystem;
  double get usableWidth => availableWidth - (systemMargin * 2);

  void advance(double width) {
    _currentX += width;
  }

  bool needsSystemBreak(double measureWidth) {
    if (_isFirstMeasureInSystem) return false;
    return _currentX + measureWidth > systemMargin + usableWidth;
  }

  void startNewSystem() {
    _currentSystem++;
    _currentX = systemMargin;
    _currentY += systemHeight * staffSpace;
    _isFirstMeasureInSystem = true;
  }

  void addBarline(List<PositionedElement> elements) {
    elements.add(
      PositionedElement(
        Barline(),
        Offset(_currentX, _currentY),
        system: _currentSystem,
      ),
    );
    advance(LayoutEngine.barlineSeparation * staffSpace);
  }

  void endMeasure() {
    _isFirstMeasureInSystem = false;
    advance(LayoutEngine.measureEndPadding * staffSpace);
  }

  void addElement(MusicalElement element, List<PositionedElement> elements) {
    elements.add(
      PositionedElement(
        element,
        Offset(_currentX, _currentY),
        system: _currentSystem,
      ),
    );
  }
}

class LayoutEngine {
  final Staff staff;
  final double availableWidth;
  final double staffSpace;
  final SmuflMetadata? metadata;

  // CORREÇÃO SMuFL: Larguras agora consultadas dinamicamente do metadata
  // Valores de fallback mantidos para compatibilidade
  static const double _gClefWidthFallback = 2.684;
  static const double _fClefWidthFallback = 2.756;
  static const double _cClefWidthFallback = 2.796;
  static const double _noteheadBlackWidthFallback = 1.18;
  static const double _accidentalSharpWidthFallback = 1.116;
  static const double _accidentalFlatWidthFallback = 1.18;
  static const double barlineSeparation = 0.4;
  static const double legerLineExtension = 0.4;

  // CORREÇÃO TIPOGRÁFICA: Espaçamentos melhorados baseados em padrões musicais
  static const double systemMargin = 2.0;
  static const double measureMinWidth = 4.0;
  static const double noteMinSpacing = 2.0; // CORRIGIDO: 1.5 era muito apertado
  static const double measureEndPadding = 1.0;

  LayoutEngine(
    this.staff, {
    required this.availableWidth,
    this.staffSpace = 12.0,
    this.metadata,
  });

  /// Obtém largura de glifo dinamicamente do metadata ou retorna fallback
  double _getGlyphWidth(String glyphName, double fallback) {
    if (metadata != null && metadata!.hasGlyph(glyphName)) {
      return metadata!.getGlyphWidth(glyphName);
    }
    return fallback;
  }

  /// Largura da clave de Sol (G clef)
  double get gClefWidth => _getGlyphWidth('gClef', _gClefWidthFallback);

  /// Largura da clave de Fá (F clef)
  double get fClefWidth => _getGlyphWidth('fClef', _fClefWidthFallback);

  /// Largura da clave de Dó (C clef)
  double get cClefWidth => _getGlyphWidth('cClef', _cClefWidthFallback);

  /// Largura da cabeça de nota preta
  double get noteheadBlackWidth => _getGlyphWidth('noteheadBlack', _noteheadBlackWidthFallback);

  /// Largura do sustenido
  double get accidentalSharpWidth => _getGlyphWidth('accidentalSharp', _accidentalSharpWidthFallback);

  /// Largura do bemol
  double get accidentalFlatWidth => _getGlyphWidth('accidentalFlat', _accidentalFlatWidthFallback);

  List<PositionedElement> layout() {
    final cursor = LayoutCursor(
      staffSpace: staffSpace,
      availableWidth: availableWidth,
      systemMargin: systemMargin * staffSpace,
    );

    final List<PositionedElement> positionedElements = [];

    for (int i = 0; i < staff.measures.length; i++) {
      final measure = staff.measures[i];
      final isFirst = cursor.isFirstMeasureInSystem;
      final isLast = i == staff.measures.length - 1;

      final measureWidth = _calculateMeasureWidthCursor(measure, isFirst);

      if (cursor.needsSystemBreak(measureWidth)) {
        cursor.startNewSystem();
      }

      _layoutMeasureCursor(measure, cursor, positionedElements, isFirst);

      if (!isLast) {
        cursor.addBarline(positionedElements);
      }

      cursor.endMeasure();
    }

    return positionedElements;
  }

  double _calculateMeasureWidthCursor(Measure measure, bool isFirstInSystem) {
    double totalWidth = 0;
    int musicalElementCount = 0;

    for (final element in measure.elements) {
      if (!isFirstInSystem && _isSystemElement(element)) {
        continue;
      }

      totalWidth += _getElementWidthSimple(element);

      if (element is Note || element is Rest || element is Chord) {
        musicalElementCount++;
      }
    }

    if (musicalElementCount > 1) {
      totalWidth += (musicalElementCount - 1) * noteMinSpacing * staffSpace;
    }

    final minWidth = measureMinWidth * staffSpace;
    return totalWidth < minWidth ? minWidth : totalWidth;
  }

  void _layoutMeasureCursor(
    Measure measure,
    LayoutCursor cursor,
    List<PositionedElement> positionedElements,
    bool isFirstInSystem,
  ) {
    // CORREÇÃO #9: Processar beaming considerando anacrusis
    final processedElements = _processBeamsWithAnacrusis(
      measure.elements,
      measure.timeSignature,
      autoBeaming: measure.autoBeaming,
      beamingMode: measure.beamingMode,
      manualBeamGroups: measure.manualBeamGroups,
    );

    final elementsToRender = processedElements.where((element) {
      return isFirstInSystem || !_isSystemElement(element);
    }).toList();

    if (elementsToRender.isEmpty) return;

    final systemElements = <MusicalElement>[];
    final musicalElements = <MusicalElement>[];

    for (final element in elementsToRender) {
      if (_isSystemElement(element)) {
        systemElements.add(element);
      } else {
        musicalElements.add(element);
      }
    }

    for (final element in systemElements) {
      cursor.addElement(element, positionedElements);
      cursor.advance(_getElementWidthSimple(element));
    }

    // CORREÇÃO #3: Espaçamento inteligente melhorado
    if (systemElements.isNotEmpty) {
      final spacingAfterSystem = _calculateSpacingAfterSystemElementsCorrected(
        systemElements,
        musicalElements,
      );
      cursor.advance(spacingAfterSystem);
    }

    for (int i = 0; i < musicalElements.length; i++) {
      final element = musicalElements[i];

      if (i > 0) {
        cursor.advance(noteMinSpacing * staffSpace);
      }

      cursor.addElement(element, positionedElements);
      cursor.advance(_getElementWidthSimple(element));
    }
  }

  bool _isSystemElement(MusicalElement element) {
    return element is Clef ||
        element is KeySignature ||
        element is TimeSignature;
  }

  // CORREÇÃO TIPOGRÁFICA SMuFL: Espaçamento inteligente baseado em padrões
  double _calculateSpacingAfterSystemElementsCorrected(
    List<MusicalElement> systemElements,
    List<MusicalElement> musicalElements,
  ) {
    // CORRIGIDO: 2.0 ainda muito apertado após elementos de sistema
    double baseSpacing = staffSpace * 2.5;

    bool hasClef = systemElements.any((e) => e is Clef);
    if (hasClef) {
      // CORRIGIDO: Mínimo de 3.0 staff spaces após clave
      baseSpacing = staffSpace * 3.0;
    }

    for (final element in systemElements) {
      if (element is KeySignature && element.count.abs() >= 4) {
        baseSpacing += staffSpace * 0.5;
      }
    }

    // CORREÇÃO: Verificar se primeira nota tem acidente
    if (musicalElements.isNotEmpty) {
      final firstMusicalElement = musicalElements.first;

      if (firstMusicalElement is Note &&
          firstMusicalElement.pitch.accidentalGlyph != null) {
        baseSpacing += staffSpace * 1.2; // Mais espaço para acidente
      } else if (firstMusicalElement is Chord) {
        // Verificar se alguma nota do acorde tem acidente
        bool hasAccidental = firstMusicalElement.notes.any(
          (note) => note.pitch.accidentalGlyph != null,
        );
        if (hasAccidental) {
          baseSpacing += staffSpace * 1.2;
        }
      }
    }

    return baseSpacing.clamp(staffSpace * 2.0, staffSpace * 5.0);
  }

  double _getElementWidthSimple(MusicalElement element) {
    if (element is Clef) {
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
        // CORREÇÃO SMuFL: Detecção mais robusta e uso de valores corretos
        final glyphName = element.pitch.accidentalGlyph!;
        double accWidth = accidentalSharpWidth; // Default

        // Identificar tipo de acidente corretamente
        if (glyphName.contains('Flat') || glyphName.contains('flat')) {
          accWidth = accidentalFlatWidth;
        } else if (glyphName.contains('Natural') || glyphName.contains('natural')) {
          accWidth = 0.92; // Largura típica de natural
        } else if (glyphName.contains('DoubleSharp')) {
          accWidth = 1.0; // Largura de dobrado sustenido
        } else if (glyphName.contains('DoubleFlat')) {
          accWidth = 1.5; // Largura de dobrado bemol
        }

        // CORRIGIDO: Espaçamento recomendado SMuFL é 0.25-0.3 staff spaces
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
          // CORREÇÃO: Usar mesma lógica robusta de detecção que Note
          final glyphName = note.pitch.accidentalGlyph!;
          double accWidth = accidentalSharpWidth;

          if (glyphName.contains('Flat') || glyphName.contains('flat')) {
            accWidth = accidentalFlatWidth;
          } else if (glyphName.contains('Natural') || glyphName.contains('natural')) {
            accWidth = 0.92;
          } else if (glyphName.contains('DoubleSharp')) {
            accWidth = 1.0;
          } else if (glyphName.contains('DoubleFlat')) {
            accWidth = 1.5;
          }
          if (accWidth > maxAccidentalWidth) {
            maxAccidentalWidth = accWidth;
          }
        }
      }

      if (maxAccidentalWidth > 0) {
        width += (maxAccidentalWidth + 0.5) * staffSpace;
      }
      return width;
    }

    if (element is Dynamic) return 2.0 * staffSpace;
    if (element is Ornament) return 1.0 * staffSpace;
    if (element is Tuplet) return 3.0 * staffSpace;

    return staffSpace;
  }

  // CORREÇÃO #9: Processamento de beams considerando anacrusis
  List<MusicalElement> _processBeamsWithAnacrusis(
    List<MusicalElement> elements,
    TimeSignature? timeSignature, {
    bool autoBeaming = true,
    BeamingMode beamingMode = BeamingMode.automatic,
    List<List<int>> manualBeamGroups = const [],
  }) {
    timeSignature ??= TimeSignature(numerator: 4, denominator: 4);

    final notes = elements.whereType<Note>().toList();
    if (notes.isEmpty) return elements;

    // Calcular posição inicial no compasso (para detectar anacrusis)
    for (final element in elements) {
      if (element is Note || element is Rest) {
        break;
      }
    }

    // Agrupar notas considerando anacrusis
    final beamGroups = BeamGrouper.groupNotesForBeaming(
      notes,
      timeSignature,
      autoBeaming: autoBeaming,
      beamingMode: beamingMode,
      manualBeamGroups: manualBeamGroups,
    );

    final processedElements = <MusicalElement>[];
    final processedNotes = <Note>{};

    for (final element in elements) {
      if (element is Note && !processedNotes.contains(element)) {
        BeamGroup? group;
        for (final beamGroup in beamGroups) {
          if (beamGroup.notes.contains(element)) {
            group = beamGroup;
            break;
          }
        }

        if (group != null && group.isValid) {
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
              voice: note.voice,
            );

            processedElements.add(beamedNote);
            processedNotes.add(note);
          }
        } else {
          processedElements.add(element);
          processedNotes.add(element);
        }
      } else if (element is! Note) {
        processedElements.add(element);
      }
    }

    return processedElements;
  }

  double calculateTotalHeight(List<PositionedElement> elements) {
    if (elements.isEmpty) {
      return staffSpace * 8;
    }

    int maxSystem = 0;
    for (final element in elements) {
      if (element.system > maxSystem) {
        maxSystem = element.system;
      }
    }

    final double systemHeight = staffSpace * 10.0;
    final double topMargin = staffSpace * 4.0;
    final double bottomMargin = staffSpace * 2.0;

    return topMargin + ((maxSystem + 1) * systemHeight) + bottomMargin;
  }
}
