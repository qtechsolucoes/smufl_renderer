// lib/src/rendering/advanced_painter.dart

import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';

/// Extensão do MusicPainter para elementos avançados
mixin AdvancedMusicPainterMixin {

  // === DESENHO DE ACORDES ===

  void drawChord(
    Canvas canvas,
    Chord chord,
    Clef clef,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    // Ordena as notas do acorde por altura (grave para agudo)
    final sortedNotes = [...chord.notes]
      ..sort((a, b) => a.pitch.midiNumber.compareTo(b.pitch.midiNumber));

    // Calcula posições e determina se precisa de segundas
    final positions = sortedNotes.map((note) =>
      _calculateStaffPosition(note.pitch, clef)).toList();

    bool stemsGoUp = (positions.reduce((a, b) => a + b) / positions.length) < 0;

    // Desenha as cabeças das notas
    double xOffset = 0;
    for (int i = 0; i < sortedNotes.length; i++) {
      final note = sortedNotes[i];
      final staffPos = positions[i];

      // Verifica se precisa deslocar para evitar sobreposição (segundas)
      if (i > 0 && (positions[i] - positions[i-1]).abs() <= 1) {
        xOffset = stemsGoUp ? -staffSpace * 0.6 : staffSpace * 0.6;
      } else {
        xOffset = 0;
      }

      final noteY = position.dy - (staffPos * staffSpace / 2);
      final noteX = position.dx + xOffset;

      _drawGlyph(
        canvas: canvas,
        glyphName: note.duration.type.glyphName,
        color: theme.noteheadColor,
        x: noteX,
        y: noteY,
        fontSize: staffSpace * 4,
        metadata: metadata,
      );

      // Desenha acidentes se necessário
      if (note.pitch.accidentalGlyph != null) {
        _drawGlyph(
          canvas: canvas,
          glyphName: note.pitch.accidentalGlyph!,
          color: theme.noteheadColor,
          x: noteX - staffSpace * 1.5,
          y: noteY,
          fontSize: staffSpace * 4,
          metadata: metadata,
        );
      }
    }

    // Desenha haste única para o acorde
    if (chord.duration.type != DurationType.whole) {
      _drawChordStem(canvas, position, positions, stemsGoUp, staffSpace, theme, metadata);
    }

    // Desenha ornamentos do acorde
    for (final ornament in chord.ornaments) {
      _drawOrnament(canvas, ornament, position, staffSpace, metadata, theme);
    }

    // Desenha dinâmica se presente
    if (chord.dynamic != null) {
      _drawDynamic(canvas, chord.dynamic!, position, staffSpace, metadata, theme);
    }
  }

  void _drawChordStem(
    Canvas canvas,
    Offset position,
    List<int> positions,
    bool stemsGoUp,
    double staffSpace,
    MusicScoreTheme theme,
    SmuflMetadata metadata,
  ) {
    final stemHeight = staffSpace * 3.5;
    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = metadata.getEngravingDefault('stemThickness');

    final extremePos = stemsGoUp ? positions.last : positions.first;
    final stemStartY = position.dy - (extremePos * staffSpace / 2);
    final stemEndY = stemsGoUp ? stemStartY - stemHeight : stemStartY + stemHeight;

    canvas.drawLine(
      Offset(position.dx, stemStartY),
      Offset(position.dx, stemEndY),
      stemPaint,
    );
  }

  // === DESENHO DE ORNAMENTOS ===

  void drawOrnament(
    Canvas canvas,
    Ornament ornament,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    _drawOrnament(canvas, ornament, position, staffSpace, metadata, theme);
  }

  void _drawOrnament(
    Canvas canvas,
    Ornament ornament,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    String? glyphName = _getOrnamentGlyph(ornament.type);
    if (glyphName == null) return;

    final yOffset = ornament.above
      ? -staffSpace * 2.0
      : staffSpace * 2.0;

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.ornamentColor ?? theme.noteheadColor,
      x: position.dx,
      y: position.dy + yOffset,
      fontSize: staffSpace * 3,
      metadata: metadata,
    );

    // Desenha texto adicional se presente
    if (ornament.text != null) {
      _drawText(
        canvas,
        ornament.text!,
        Offset(position.dx + staffSpace, position.dy + yOffset),
        theme.textStyle ?? const TextStyle(color: Colors.black, fontSize: 12),
      );
    }
  }

  String? _getOrnamentGlyph(OrnamentType type) {
    const ornamentGlyphs = {
      OrnamentType.trill: 'ornamentTrill',
      OrnamentType.trillFlat: 'ornamentTrillFlat',
      OrnamentType.trillNatural: 'ornamentTrillNatural',
      OrnamentType.trillSharp: 'ornamentTrillSharp',
      OrnamentType.mordent: 'ornamentMordent',
      OrnamentType.invertedMordent: 'ornamentMordentInverted',
      OrnamentType.shortTrill: 'ornamentShortTrill',
      OrnamentType.turn: 'ornamentTurn',
      OrnamentType.invertedTurn: 'ornamentTurnInverted',
      OrnamentType.turnSlash: 'ornamentTurnSlash',
      OrnamentType.appoggiaturaUp: 'ornamentAppoggiaturaUp',
      OrnamentType.appoggiaturaDown: 'ornamentAppoggiaturaDown',
      OrnamentType.acciaccatura: 'ornamentAppoggiaturaDown',
      OrnamentType.fermata: 'fermataAbove',
      OrnamentType.fermataBelowInverted: 'fermataBelow',
      OrnamentType.schleifer: 'ornamentSchleifer',
      OrnamentType.shake: 'ornamentShake3',
      OrnamentType.wavyLine: 'ornamentPrecompSlide',
      OrnamentType.mordentUpperPrefix: 'ornamentMordentUpperPrefix',
      OrnamentType.mordentLowerPrefix: 'ornamentMordentLowerPrefix',
      OrnamentType.trillLigature: 'ornamentTrillLigature',
      OrnamentType.haydn: 'ornamentHaydn',
      OrnamentType.zigZagLineNoRightEnd: 'ornamentZigZagLineNoRightEnd',
      OrnamentType.zigZagLineWithRightEnd: 'ornamentZigZagLineWithRightEnd',
    };
    return ornamentGlyphs[type];
  }

  // === DESENHO DE DINÂMICAS ===

  void drawDynamic(
    Canvas canvas,
    Dynamic dynamic,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    _drawDynamic(canvas, dynamic, position, staffSpace, metadata, theme);
  }

  void _drawDynamic(
    Canvas canvas,
    Dynamic dynamic,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    if (dynamic.isHairpin) {
      _drawHairpin(canvas, dynamic, position, staffSpace, theme);
    } else {
      String? glyphName = _getDynamicGlyph(dynamic.type);
      if (glyphName != null) {
        _drawGlyph(
          canvas: canvas,
          glyphName: glyphName,
          color: theme.dynamicColor ?? theme.noteheadColor,
          x: position.dx,
          y: position.dy + staffSpace * 3,
          fontSize: staffSpace * 2.5,
          metadata: metadata,
        );
      } else if (dynamic.customText != null) {
        _drawText(
          canvas,
          dynamic.customText!,
          Offset(position.dx, position.dy + staffSpace * 3),
          theme.dynamicTextStyle ?? const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontStyle: FontStyle.italic
          ),
        );
      }
    }
  }

  String? _getDynamicGlyph(DynamicType type) {
    const dynamicGlyphs = {
      DynamicType.pianississimo: 'dynamicPPP',
      DynamicType.pianissimo: 'dynamicPP',
      DynamicType.piano: 'dynamicPiano',
      DynamicType.mezzoPiano: 'dynamicMP',
      DynamicType.mezzoForte: 'dynamicMF',
      DynamicType.forte: 'dynamicForte',
      DynamicType.fortissimo: 'dynamicFF',
      DynamicType.fortississimo: 'dynamicFFF',
      DynamicType.sforzando: 'dynamicSforzando1',
      DynamicType.sforzandoFF: 'dynamicSforzatoFF',
      DynamicType.sforzandoPiano: 'dynamicSforzatoPiano',
      DynamicType.rinforzando: 'dynamicRinforzando1',
      DynamicType.fortePiano: 'dynamicFortePiano',
      DynamicType.sforzandoPianissimo: 'dynamicSforzatoPianissimo',
      DynamicType.niente: 'dynamicNiente',
      DynamicType.pppp: 'dynamicPPPP',
      DynamicType.ppp: 'dynamicPPP',
      DynamicType.pp: 'dynamicPP',
      DynamicType.p: 'dynamicPiano',
      DynamicType.mp: 'dynamicMP',
      DynamicType.mf: 'dynamicMF',
      DynamicType.f: 'dynamicForte',
      DynamicType.ff: 'dynamicFF',
      DynamicType.fff: 'dynamicFFF',
      DynamicType.ffff: 'dynamicFFFF',
    };
    return dynamicGlyphs[type];
  }

  void _drawHairpin(
    Canvas canvas,
    Dynamic dynamic,
    Offset position,
    double staffSpace,
    MusicScoreTheme theme,
  ) {
    final length = dynamic.length ?? staffSpace * 4;
    final height = staffSpace * 0.5;
    final y = position.dy + staffSpace * 3;

    final paint = Paint()
      ..color = theme.dynamicColor ?? theme.noteheadColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (dynamic.type == DynamicType.crescendo) {
      // Crescendo: linha que se abre
      path.moveTo(position.dx, y - height / 2);
      path.lineTo(position.dx + length, y - height);
      path.moveTo(position.dx, y + height / 2);
      path.lineTo(position.dx + length, y + height);
    } else if (dynamic.type == DynamicType.diminuendo) {
      // Diminuendo: linha que se fecha
      path.moveTo(position.dx, y - height);
      path.lineTo(position.dx + length, y - height / 2);
      path.moveTo(position.dx, y + height);
      path.lineTo(position.dx + length, y + height / 2);
    }

    canvas.drawPath(path, paint);
  }

  // === DESENHO DE QUIÁLTERAS ===

  void drawTuplet(
    Canvas canvas,
    Tuplet tuplet,
    List<Offset> elementPositions,
    double staffSpace,
    MusicScoreTheme theme,
  ) {
    if (elementPositions.isEmpty) return;

    final startX = elementPositions.first.dx;
    final endX = elementPositions.last.dx;
    final avgY = elementPositions.map((p) => p.dy).reduce((a, b) => a + b) / elementPositions.length;
    final bracketY = avgY - staffSpace * 2;

    // Desenha colchete se solicitado
    if (tuplet.showBracket) {
      final paint = Paint()
        ..color = theme.tupletColor ?? theme.noteheadColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(startX, bracketY);
      path.lineTo(startX, bracketY - staffSpace * 0.3);
      path.moveTo(startX, bracketY);
      path.lineTo(endX, bracketY);
      path.moveTo(endX, bracketY);
      path.lineTo(endX, bracketY - staffSpace * 0.3);

      canvas.drawPath(path, paint);
    }

    // Desenha número se solicitado
    if (tuplet.showNumber) {
      final centerX = (startX + endX) / 2;
      final text = '${tuplet.actualNotes}';

      _drawText(
        canvas,
        text,
        Offset(centerX, bracketY - staffSpace * 0.5),
        theme.tupletTextStyle ?? const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  // === DESENHO DE TEXTOS ===

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  // === DESENHO DE RESPIRAÇÕES ===

  void drawBreath(
    Canvas canvas,
    Breath breath,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    String? glyphName = _getBreathGlyph(breath.type);
    if (glyphName == null) return;

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.breathColor ?? theme.noteheadColor,
      x: position.dx,
      y: position.dy - staffSpace,
      fontSize: staffSpace * 2,
      metadata: metadata,
    );
  }

  String? _getBreathGlyph(BreathType type) {
    const breathGlyphs = {
      BreathType.comma: 'breathMarkComma',
      BreathType.tick: 'breathMarkTick',
      BreathType.upbow: 'breathMarkUpbow',
      BreathType.caesura: 'caesura',
      BreathType.shortCaesura: 'caesuraShort',
      BreathType.longCaesura: 'caesuraThick',
    };
    return breathGlyphs[type];
  }

  // === UTILITÁRIOS ===

  void _drawGlyph({
    required Canvas canvas,
    required String glyphName,
    required Color color,
    required double x,
    required double y,
    required double fontSize,
    required SmuflMetadata metadata,
    double rotation = 0.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: metadata.getCodepoint(glyphName),
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();

    if (rotation != 0.0 || scaleX != 1.0 || scaleY != 1.0) {
      canvas.translate(x, y);
      if (rotation != 0.0) {
        canvas.rotate(rotation * (3.14159 / 180));
      }
      if (scaleX != 1.0 || scaleY != 1.0) {
        canvas.scale(scaleX, scaleY);
      }
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    } else {
      final yOffset = y - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(x, yOffset));
    }

    canvas.restore();
  }

  int _calculateStaffPosition(Pitch pitch, Clef clef) {
    if (clef.type != 'g') return 0;
    const int baseStep = 4;
    const int baseOctave = 4;
    const int basePosition = -2;

    const stepToDiatonic = {'C': 0, 'D': 1, 'E': 2, 'F': 3, 'G': 4, 'A': 5, 'B': 6};
    int pitchStep = stepToDiatonic[pitch.step]!;
    int diatonicDistance = (pitchStep - baseStep) + ((pitch.octave - baseOctave) * 7);
    return basePosition + diatonicDistance;
  }
}