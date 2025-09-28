// lib/src/rendering/advanced_painter.dart

import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../smufl/smufl_coordinates.dart';
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
    final positions = sortedNotes
        .map((note) => _calculateStaffPosition(note.pitch, clef))
        .toList();

    bool stemsGoUp = (positions.reduce((a, b) => a + b) / positions.length) < 0;

    // Desenha as cabeças das notas
    double xOffset = 0;
    for (int i = 0; i < sortedNotes.length; i++) {
      final note = sortedNotes[i];
      final staffPos = positions[i];

      // Verifica se precisa deslocar para evitar sobreposição (segundas)
      if (i > 0 && (positions[i] - positions[i - 1]).abs() <= 1) {
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
      _drawChordStem(
        canvas,
        position,
        positions,
        stemsGoUp,
        staffSpace,
        theme,
        metadata,
      );
    }

    // Desenha ornamentos do acorde
    for (final ornament in chord.ornaments) {
      _drawOrnament(canvas, ornament, position, staffSpace, metadata, theme, chord.duration.type.glyphName);
    }

    // Desenha dinâmica se presente
    if (chord.dynamic != null) {
      _drawDynamic(
        canvas,
        chord.dynamic!,
        position,
        staffSpace,
        metadata,
        theme,
        chord.duration.type.glyphName,
      );
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
    final stemEndY = stemsGoUp
        ? stemStartY - stemHeight
        : stemStartY + stemHeight;

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
    String noteGlyph,
  ) {
    _drawOrnament(canvas, ornament, position, staffSpace, metadata, theme, noteGlyph);
  }

  void _drawOrnament(
    Canvas canvas,
    Ornament ornament,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
    String noteGlyph,
  ) {
    String? glyphName = _getOrnamentGlyph(ornament.type);
    if (glyphName == null) return;

    // Obter dimensões da cabeça da nota para centralização
    final bbox = metadata.getGlyphBBox(noteGlyph);
    final noteheadWidth = (bbox?['bBoxNE']?[0] ?? 1.18) * staffSpace;
    final noteheadHeight = (bbox?['bBoxNE']?[1] ?? 0.5) * staffSpace;

    // Posicionamento correto dos ornamentos SEMPRE ACIMA da nota
    // Centralizado na cabeça da nota e um pouco acima
    final ornamentX = position.dx + (noteheadWidth / 2);
    final ornamentY = position.dy - (noteheadHeight * 0.5 + staffSpace * 0.8);

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.ornamentColor ?? theme.noteheadColor,
      x: ornamentX,
      y: ornamentY,
      fontSize: staffSpace * 2.5, // Tamanho proporcional
      metadata: metadata,
    );

    // Desenha texto adicional se presente
    if (ornament.text != null) {
      _drawText(
        canvas,
        ornament.text!,
        Offset(position.dx + staffSpace, ornamentY),
        theme.textStyle ?? const TextStyle(color: Colors.black, fontSize: 12),
      );
    }
  }

  String? _getOrnamentGlyph(OrnamentType type) {
    // Mapeamento baseado nas imagens de referência e SMuFL oficial
    const ornamentGlyphs = {
      // Trilos - baseado na primeira imagem
      OrnamentType.trill: 'ornamentTrill',
      OrnamentType.trillFlat: 'ornamentTrillFlat',
      OrnamentType.trillNatural: 'ornamentTrillNatural',
      OrnamentType.trillSharp: 'ornamentTrillSharp',
      OrnamentType.shortTrill: 'ornamentShortTrill',

      // Mordentes - variações mostradas nas imagens
      OrnamentType.mordent: 'ornamentMordent',
      OrnamentType.invertedMordent: 'ornamentMordentInverted',
      OrnamentType.mordentUpperPrefix: 'ornamentMordentUpperPrefix',
      OrnamentType.mordentLowerPrefix: 'ornamentMordentLowerPrefix',

      // Grupetos (turns)
      OrnamentType.turn: 'ornamentTurn',
      OrnamentType.invertedTurn: 'ornamentTurnInverted',
      OrnamentType.turnSlash: 'ornamentTurnSlash',

      // Apoggiaturas e acciaccaturas
      OrnamentType.appoggiaturaUp: 'ornamentAppoggiaturaUp',
      OrnamentType.appoggiaturaDown: 'ornamentAppoggiaturaDown',
      OrnamentType.acciaccatura: 'ornamentAppoggiaturaDown',

      // Fermatas
      OrnamentType.fermata: 'fermataAbove',
      OrnamentType.fermataBelow: 'fermataBelow',
      OrnamentType.fermataBelowInverted: 'fermataBelow',

      // Ornamentos especiais
      OrnamentType.schleifer: 'ornamentSchleifer',
      OrnamentType.shake: 'ornamentShake3',
      OrnamentType.wavyLine: 'ornamentPrecompSlide',
      OrnamentType.trillLigature: 'ornamentTrillLigature',
      OrnamentType.haydn: 'ornamentHaydn',

      // Linhas e deslizamentos
      OrnamentType.zigZagLineNoRightEnd: 'ornamentZigZagLineNoRightEnd',
      OrnamentType.zigZagLineWithRightEnd: 'ornamentZigZagLineWithRightEnd',

      // Ornamentos adicionais das imagens
      OrnamentType.glissando: 'glissandoUp',
      OrnamentType.portamento: 'ornamentPrecompSlide',
      OrnamentType.slide: 'glissandoUp',
      OrnamentType.scoop: 'ornamentPrecompSlide',
      OrnamentType.fall: 'ornamentPrecompSlide',
      OrnamentType.doit: 'ornamentPrecompSlide',
      OrnamentType.plop: 'ornamentPrecompSlide',
      OrnamentType.bend: 'ornamentPrecompSlide',
      OrnamentType.zigzagLine: 'ornamentZigZagLineWithRightEnd',
      OrnamentType.arpeggio: 'arpeggiato',
      OrnamentType.grace: 'ornamentAppoggiaturaDown',
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
    String noteGlyph,
  ) {
    _drawDynamic(canvas, dynamic, position, staffSpace, metadata, theme, noteGlyph);
  }

  void _drawDynamic(
    Canvas canvas,
    Dynamic dynamic,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
    String noteGlyph,
  ) {
    if (dynamic.isHairpin) {
      _drawHairpin(canvas, dynamic, position, staffSpace, theme);
    } else {
      // Usar coordenadas SMuFL para posicionamento preciso
      final coordinates = SmuflAdvancedCoordinates(staffSpace: staffSpace, metadata: metadata);
      final dynamicY = coordinates.getDynamicY(noteGlyph, position.dy);
      
      String? glyphName = _getDynamicGlyph(dynamic.type);
      if (glyphName != null) {
        _drawGlyph(
          canvas: canvas,
          glyphName: glyphName,
          color: theme.dynamicColor ?? theme.noteheadColor,
          x: position.dx,
          y: dynamicY,
          fontSize: staffSpace * 2.5,
          metadata: metadata,
        );
      } else if (dynamic.customText != null) {
        _drawText(
          canvas,
          dynamic.customText!,
          Offset(position.dx, dynamicY),
          theme.dynamicTextStyle ??
              const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
        );
      }
    }
  }

  String? _getDynamicGlyph(DynamicType type) {
    // Mapeamento completo baseado na imagem de dinâmicas e SMuFL oficial
    const dynamicGlyphs = {
      // Dinâmicas básicas
      DynamicType.pianississimo: 'dynamicPPP',
      DynamicType.pianissimo: 'dynamicPP',
      DynamicType.piano: 'dynamicPiano',
      DynamicType.mezzoPiano: 'dynamicMP',
      DynamicType.mezzoForte: 'dynamicMF',
      DynamicType.forte: 'dynamicForte',
      DynamicType.fortissimo: 'dynamicFF',
      DynamicType.fortississimo: 'dynamicFFF',

      // Versões com abreviações (mais comuns)
      DynamicType.pppp: 'dynamicPPPP',
      DynamicType.ppppp: 'dynamicPPPPP',
      DynamicType.pppppp: 'dynamicPPPPPP',
      DynamicType.ppp: 'dynamicPPP',
      DynamicType.pp: 'dynamicPP',
      DynamicType.p: 'dynamicPiano',
      DynamicType.mp: 'dynamicMP',
      DynamicType.mf: 'dynamicMF',
      DynamicType.f: 'dynamicForte',
      DynamicType.ff: 'dynamicFF',
      DynamicType.fff: 'dynamicFFF',
      DynamicType.ffff: 'dynamicFFFF',
      DynamicType.fffff: 'dynamicFFFFF',
      DynamicType.ffffff: 'dynamicFFFFFF',

      // Dinâmicas especiais - baseado na imagem de referência
      DynamicType.sforzando: 'dynamicSforzando1',
      DynamicType.sforzandoFF: 'dynamicSforzatoFF',
      DynamicType.sforzandoPiano: 'dynamicSforzatoPiano',
      DynamicType.sforzandoPianissimo: 'dynamicSforzatoPianissimo',
      DynamicType.rinforzando: 'dynamicRinforzando1',
      DynamicType.fortePiano: 'dynamicFortePiano',
      DynamicType.niente: 'dynamicNiente',

      // Note: crescendo e diminuendo são tratados como hairpins,
      // não como glifos únicos, então não aparecem aqui
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
    final avgY =
        elementPositions.map((p) => p.dy).reduce((a, b) => a + b) /
        elementPositions.length;
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
        theme.tupletTextStyle ??
            const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
      );
    }
  }

  // === DESENHO DE TEXTOS ===

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
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

  // === DESENHO DE SINAIS DE REPETIÇÃO ===

  void drawRepeatMark(
    Canvas canvas,
    RepeatMark repeat,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    String? glyphName = _getRepeatGlyph(repeat.type);
    if (glyphName == null) return;

    double fontSize = staffSpace * 4;
    Color color = theme.repeatColor ?? theme.noteheadColor;

    // Ajustar posição baseado no tipo
    double yOffset = 0.0;
    switch (repeat.type) {
      case RepeatType.segno:
      case RepeatType.segnoSquare:
        yOffset = -staffSpace * 2; // Acima da pauta
        break;
      case RepeatType.coda:
      case RepeatType.codaSquare:
        yOffset = -staffSpace * 2; // Acima da pauta
        break;
      case RepeatType.fine:
        yOffset = -staffSpace * 3; // Bem acima da pauta
        fontSize = staffSpace * 2; // Menor para texto
        break;
      default:
        yOffset = 0.0;
        break;
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: color,
      x: position.dx,
      y: position.dy + yOffset,
      fontSize: fontSize,
      metadata: metadata,
    );

    // Desenhar etiqueta se presente
    if (repeat.label != null) {
      _drawText(
        canvas,
        repeat.label!,
        Offset(position.dx, position.dy + yOffset + staffSpace),
        theme.repeatTextStyle ??
            const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
      );
    }
  }

  String? _getRepeatGlyph(RepeatType type) {
    const repeatGlyphs = {
      RepeatType.segno: 'segno',
      RepeatType.segnoSquare: 'segno',
      RepeatType.coda: 'coda',
      RepeatType.codaSquare: 'codaSquare',
      RepeatType.dalSegno: 'segno',
      RepeatType.daCapo: null, // Texto apenas
      RepeatType.fine: null, // Texto apenas
      RepeatType.repeat1Bar: 'repeat1Bar',
      RepeatType.repeat2Bars: 'repeat2Bars',
      RepeatType.repeat4Bars: 'repeat4Bars',
      RepeatType.simile: 'simile',
      RepeatType.percentRepeat: 'repeat1Bar',
    };
    return repeatGlyphs[type];
  }

  // === DESENHO DE SINAIS DE OITAVA ===

  void drawOctaveMark(
    Canvas canvas,
    OctaveMark octave,
    Offset startPosition,
    Offset endPosition,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    final length = octave.length ?? (endPosition.dx - startPosition.dx);
    final isAbove = octave.octaveShift > 0;
    final yPosition = isAbove
        ? startPosition.dy - staffSpace * 3
        : startPosition.dy + staffSpace * 3;

    // Desenhar o número (8, 15, 22)
    final octaveNumber = (octave.octaveShift.abs() * 7) + 1;
    final numberText = octaveNumber.toString();

    final textStyle = TextStyle(
      fontSize: staffSpace * 1.5,
      color: theme.octaveColor ?? theme.noteheadColor,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: numberText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Posição do número
    final numberOffset = Offset(
      startPosition.dx,
      yPosition - textPainter.height / 2,
    );
    textPainter.paint(canvas, numberOffset);

    // Desenhar linha tracejada
    if (octave.showBracket && length > staffSpace) {
      _drawOctaveLine(
        canvas,
        startPosition.dx + textPainter.width + staffSpace * 0.2,
        endPosition.dx,
        yPosition,
        theme.octaveColor ?? theme.noteheadColor,
        isAbove,
        staffSpace,
      );
    }
  }

  void _drawOctaveLine(
    Canvas canvas,
    double startX,
    double endX,
    double y,
    Color color,
    bool isAbove,
    double staffSpace,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Linha principal
    canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);

    // Ganchos nas extremidades
    final hookHeight = staffSpace * 0.3;
    final hookDirection = isAbove ? hookHeight : -hookHeight;

    // Gancho inicial
    canvas.drawLine(
      Offset(startX, y),
      Offset(startX, y + hookDirection),
      paint,
    );

    // Gancho final
    canvas.drawLine(
      Offset(endX, y),
      Offset(endX, y + hookDirection),
      paint,
    );
  }

  // === DESENHO DE CLUSTERS ===

  void drawCluster(
    Canvas canvas,
    Cluster cluster,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
    Clef clef,
  ) {
    final lowestStaffPos = _calculateStaffPosition(cluster.lowestNote, clef);
    final highestStaffPos = _calculateStaffPosition(cluster.highestNote, clef);

    final lowestY = position.dy - (lowestStaffPos * staffSpace / 2);
    final highestY = position.dy - (highestStaffPos * staffSpace / 2);

    final clusterHeight = lowestY - highestY;

    // Desenhar bloco sólido do cluster
    final paint = Paint()
      ..color = theme.clusterColor ?? theme.noteheadColor
      ..style = PaintingStyle.fill;

    final clusterWidth = staffSpace * 2;
    final rect = Rect.fromLTWH(
      position.dx,
      highestY,
      clusterWidth,
      clusterHeight,
    );

    canvas.drawRect(rect, paint);

    // Desenhar colchete se solicitado
    if (cluster.showBracket) {
      _drawClusterBracket(
        canvas,
        position.dx - staffSpace * 0.5,
        highestY,
        lowestY,
        staffSpace,
        theme.clusterColor ?? theme.noteheadColor,
      );
    }
  }

  void _drawClusterBracket(
    Canvas canvas,
    double x,
    double topY,
    double bottomY,
    double staffSpace,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final bracketWidth = staffSpace * 0.3;

    // Linha vertical
    canvas.drawLine(Offset(x, topY), Offset(x, bottomY), paint);

    // Gancho superior
    canvas.drawLine(
      Offset(x, topY),
      Offset(x + bracketWidth, topY),
      paint,
    );

    // Gancho inferior
    canvas.drawLine(
      Offset(x, bottomY),
      Offset(x + bracketWidth, bottomY),
      paint,
    );
  }

  // === DESENHO DE CAESURAS ===

  void drawCaesura(
    Canvas canvas,
    Caesura caesura,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
  ) {
    _drawGlyph(
      canvas: canvas,
      glyphName: caesura.glyphName,
      color: theme.caesuraColor ?? theme.noteheadColor,
      x: position.dx,
      y: position.dy,
      fontSize: staffSpace * 3,
      metadata: metadata,
    );
  }

  // === DESENHO DE ARTICULAÇÕES ===

  void drawArticulation(
    Canvas canvas,
    ArticulationType articulation,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
    String noteGlyph,
    bool above,
  ) {
    _drawArticulation(canvas, articulation, position, staffSpace, metadata, theme, noteGlyph, above);
  }

  void _drawArticulation(
    Canvas canvas,
    ArticulationType articulation,
    Offset position,
    double staffSpace,
    SmuflMetadata metadata,
    MusicScoreTheme theme,
    String noteGlyph,
    bool above,
  ) {
    String? glyphName = _getArticulationGlyph(articulation);
    if (glyphName == null) return;

    // Usar coordenadas SMuFL para posicionamento preciso
    final coordinates = SmuflAdvancedCoordinates(staffSpace: staffSpace, metadata: metadata);
    final articulationY = coordinates.getArticulationY(
      noteGlyph,
      glyphName,
      position.dy,
      above,
    );

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.articulationColor,
      x: position.dx,
      y: articulationY,
      fontSize: staffSpace * 2.5,
      metadata: metadata,
    );
  }

  String? _getArticulationGlyph(ArticulationType type) {
    // Mapeamento completo de articulações SMuFL
    const articulationGlyphs = {
      // Articulações básicas
      ArticulationType.staccato: 'augmentationDot',
      ArticulationType.staccatissimo: 'articStaccatissimoAbove',
      ArticulationType.accent: 'articAccentAbove',
      ArticulationType.strongAccent: 'articMarcatoAbove',
      ArticulationType.tenuto: 'articTenutoAbove',
      ArticulationType.marcato: 'articMarcatoAbove',
      ArticulationType.portato: 'articTenutoStaccatoAbove',

      // Técnicas para instrumentos de corda
      ArticulationType.upBow: 'stringsUpBow',
      ArticulationType.downBow: 'stringsDownBow',
      ArticulationType.harmonics: 'stringsHarmonic',
      ArticulationType.pizzicato: 'pluckedPizzicatoAbove',
      ArticulationType.snap: 'pluckedSnapPizzicatoAbove',
      ArticulationType.thumb: 'pluckedThumbPosition',

      // Técnicas para instrumentos de metal
      ArticulationType.stopped: 'brassMuteClosed',
      ArticulationType.open: 'brassmuteOpen',
      ArticulationType.halfStopped: 'brassMuteHalfClosed',

      // Note: Legato é normalmente representado por slurs,
      // não por símbolos pontuais, então não incluímos aqui
    };
    return articulationGlyphs[type];
  }

  // === DESENHO DE BARRAS (BEAMS) ===

  void drawBeam(
    Canvas canvas,
    List<Offset> positions,
    double staffSpace,
    MusicScoreTheme theme,
    SmuflMetadata metadata,
    DurationType durationType,
  ) {
    if (positions.length < 2) return;

    final paint = Paint()
      ..color = theme.beamColor ?? Colors.black
      ..style = PaintingStyle.fill;

    // Usar coordenadas SMuFL para posicionamento preciso
    final coordinates = SmuflAdvancedCoordinates(staffSpace: staffSpace, metadata: metadata);
    final beamHeight = coordinates.getBeamHeight(durationType);

    // Determinar direção das hastes baseado na posição média das notas
    final avgY = positions.map((p) => p.dy).reduce((a, b) => a + b) / positions.length;
    final staffCenter = positions.first.dy; // Assumindo que a primeira nota está na pauta
    final stemUp = avgY > staffCenter;

    // Calcular posições Y das beams baseado nas âncoras SMuFL
    final beamPositionsY = coordinates.calculateBeamPositions(
      positions.map((p) => p.dy).toList(),
      stemUp,
    );

    // Desenhar beam(s) baseado na duração
    final numBeams = _getNumBeams(durationType);
    for (int beamIndex = 0; beamIndex < numBeams; beamIndex++) {
      _drawSingleBeam(
        canvas,
        positions,
        beamPositionsY,
        beamHeight,
        beamIndex,
        stemUp,
        paint,
        staffSpace,
      );
    }
  }

  /// Desenha uma única beam
  void _drawSingleBeam(
    Canvas canvas,
    List<Offset> positions,
    List<double> beamPositionsY,
    double beamHeight,
    int beamIndex,
    bool stemUp,
    Paint paint,
    double staffSpace,
  ) {
    final beamOffset = stemUp 
        ? -beamHeight * (beamIndex + 1) - (staffSpace * 0.2 * beamIndex)
        : beamHeight * (beamIndex + 1) + (staffSpace * 0.2 * beamIndex);

    final path = Path();
    
    // Primeira posição
    final startX = positions.first.dx;
    final startY = beamPositionsY.first + beamOffset;
    
    // Última posição
    final endX = positions.last.dx;
    final endY = beamPositionsY.last + beamOffset;
    
    // Construir path da beam
    path.moveTo(startX, startY);
    path.lineTo(endX, endY);
    path.lineTo(endX, endY + (stemUp ? -beamHeight : beamHeight));
    path.lineTo(startX, startY + (stemUp ? -beamHeight : beamHeight));
    path.close();
    
    canvas.drawPath(path, paint);
  }

  /// Retorna número de beams baseado na duração
  int _getNumBeams(DurationType durationType) {
    switch (durationType) {
      case DurationType.eighth:
        return 1;
      case DurationType.sixteenth:
        return 2;
      case DurationType.thirtySecond:
        return 3;
      case DurationType.sixtyFourth:
        return 4;
      default:
        return 1;
    }
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
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    } else {
      final yOffset = y - (textPainter.height / 2);
      textPainter.paint(canvas, Offset(x, yOffset));
    }

    canvas.restore();
  }

  int _calculateStaffPosition(Pitch pitch, Clef clef) {
    // Cálculo baseado no novo sistema de claves
    int baseStep, baseOctave, basePosition;

    switch (clef.actualClefType) {
      case ClefType.treble: // Clave de Sol
        baseStep = 4; // G
        baseOctave = 4;
        basePosition = clef.referenceLinePosition; // Sol na 2ª linha
        break;
      case ClefType.bass:
      case ClefType.bassThirdLine:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        baseStep = 3; // F
        baseOctave = 3;
        basePosition = clef.referenceLinePosition; // Fá na 4ª linha
        break;
      case ClefType.soprano:
      case ClefType.mezzoSoprano:
      case ClefType.alto:
      case ClefType.tenor:
      case ClefType.baritone:
      case ClefType.c8vb:
        baseStep = 0; // C
        baseOctave = 4;
        basePosition = clef.referenceLinePosition; // Varia conforme a posição
        break;
      default:
        return 0;
    }

    const stepToDiatonic = {
      'C': 0,
      'D': 1,
      'E': 2,
      'F': 3,
      'G': 4,
      'A': 5,
      'B': 6,
    };
    int pitchStep = stepToDiatonic[pitch.step]!;
    int diatonicDistance = (pitchStep - baseStep) + ((pitch.octave + clef.octaveShift - baseOctave) * 7);
    return basePosition + diatonicDistance;
  }
}
