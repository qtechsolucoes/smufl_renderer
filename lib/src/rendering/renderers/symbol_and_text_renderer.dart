// lib/src/rendering/renderers/symbol_and_text_renderer.dart

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

/// Renderizador especialista para elementos de notação baseados em símbolos e texto,
/// como dinâmicas, marcas de tempo, repetições, etc.
class SymbolAndTextRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;

  SymbolAndTextRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
  });

  void renderRepeatMark(RepeatMark repeatMark, Offset basePosition) {
    final glyphName = _getRepeatMarkGlyph(repeatMark.type);
    if (glyphName == null) return;

    final signY = coordinates.staffBaseline.dy - (coordinates.staffSpace * 4.0);

    _drawGlyph(
      glyphName: glyphName,
      position: Offset(basePosition.dx, signY),
      size: glyphSize * 1.1,
      color: theme.repeatColor ?? theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  String? _getRepeatMarkGlyph(RepeatType type) {
    const repeatGlyphs = {
      RepeatType.segno: 'segno',
      RepeatType.coda: 'coda',
      // Adicione outros glifos de repetição aqui
    };
    return repeatGlyphs[type];
  }

  void renderDynamic(Dynamic dynamic, Offset basePosition) {
    if (dynamic.isHairpin) {
      _renderHairpin(dynamic, basePosition);
      return;
    }

    final glyphName = _getDynamicGlyph(dynamic.type);
    final dynamicY =
        coordinates.staffBaseline.dy + (coordinates.staffSpace * 3.0);

    if (glyphName != null) {
      _drawGlyph(
        glyphName: glyphName,
        position: Offset(basePosition.dx, dynamicY),
        size: glyphSize * 0.9,
        color: theme.dynamicColor ?? theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    } else if (dynamic.customText != null) {
      _drawText(
        text: dynamic.customText!,
        position: Offset(basePosition.dx, dynamicY),
        style:
            theme.dynamicTextStyle ??
            TextStyle(
              fontSize: glyphSize * 0.4,
              fontStyle: FontStyle.italic,
              color: theme.dynamicColor ?? theme.noteheadColor,
            ),
      );
    }
  }

  void _renderHairpin(Dynamic dynamic, Offset basePosition) {
    final length = dynamic.length ?? coordinates.staffSpace * 4;
    final hairpinY =
        coordinates.staffBaseline.dy + (coordinates.staffSpace * 3.0);
    final height = coordinates.staffSpace * 0.5;

    final paint = Paint()
      ..color = theme.dynamicColor ?? theme.noteheadColor
      ..strokeWidth = metadata.getEngravingDefault('thinBarlineThickness');

    if (dynamic.type == DynamicType.crescendo) {
      canvas.drawLine(
        Offset(basePosition.dx, hairpinY + height),
        Offset(basePosition.dx + length, hairpinY),
        paint,
      );
      canvas.drawLine(
        Offset(basePosition.dx, hairpinY - height),
        Offset(basePosition.dx + length, hairpinY),
        paint,
      );
    } else if (dynamic.type == DynamicType.diminuendo) {
      canvas.drawLine(
        Offset(basePosition.dx, hairpinY),
        Offset(basePosition.dx + length, hairpinY + height),
        paint,
      );
      canvas.drawLine(
        Offset(basePosition.dx, hairpinY),
        Offset(basePosition.dx + length, hairpinY - height),
        paint,
      );
    }
  }

  String? _getDynamicGlyph(DynamicType type) {
    const dynamicGlyphs = {
      DynamicType.p: 'dynamicPiano',
      DynamicType.mp: 'dynamicMezzoPiano',
      DynamicType.mf: 'dynamicMezzoForte',
      DynamicType.f: 'dynamicForte',
      DynamicType.pp: 'dynamicPP',
      DynamicType.ff: 'dynamicFF',
      DynamicType.sforzando: 'dynamicSforzando1',
      // Adicione outros
    };
    return dynamicGlyphs[type];
  }

  void renderMusicText(MusicText text, Offset basePosition) {
    double yOffset = 0;
    switch (text.placement) {
      case TextPlacement.above:
        yOffset = -coordinates.staffSpace * 2.5;
        break;
      case TextPlacement.below:
        yOffset = coordinates.staffSpace * 2.5;
        break;
      case TextPlacement.inside:
        yOffset = 0;
        break;
    }
    _drawText(
      text: text.text,
      position: Offset(basePosition.dx, coordinates.staffBaseline.dy + yOffset),
      style: text.type == TextType.tempo
          ? (theme.tempoTextStyle ?? const TextStyle())
          : (theme.textStyle ?? const TextStyle()),
    );
  }

  void renderTempoMark(TempoMark tempo, Offset basePosition) {
    String text = tempo.text ?? '';
    if (tempo.bpm != null) {
      text += ' (♩ = ${tempo.bpm})';
    }
    _drawText(
      text: text,
      position: Offset(
        basePosition.dx,
        coordinates.staffBaseline.dy - (coordinates.staffSpace * 3.5),
      ),
      style:
          theme.tempoTextStyle ?? const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  void renderBreath(Breath breath, Offset basePosition) {
    final glyphName = 'breathMarkComma'; // Simplificado
    _drawGlyph(
      glyphName: glyphName,
      position: Offset(basePosition.dx, coordinates.getStaffLineY(4)),
      size: glyphSize * 0.7,
      color: theme.breathColor ?? theme.noteheadColor,
      centerHorizontally: true,
      centerVertically: true,
    );
  }

  void renderCaesura(Caesura caesura, Offset basePosition) {
    _drawGlyph(
      glyphName: caesura.glyphName,
      position: Offset(basePosition.dx, coordinates.getStaffLineY(5)),
      size: glyphSize,
      color: theme.caesuraColor ?? theme.noteheadColor,
      centerHorizontally: true,
      centerVertically: true,
    );
  }

  void renderOctaveMark(OctaveMark octaveMark, Offset basePosition) {
    // A lógica completa para linhas tracejadas de oitava é complexa e
    // se encaixaria melhor no GroupRenderer. Por enquanto, desenhamos o símbolo.
    _drawText(
      text: octaveMark.type == OctaveType.octave8va ? '8va' : '8vb',
      position: Offset(
        basePosition.dx,
        coordinates.staffBaseline.dy - (coordinates.staffSpace * 3.5),
      ),
      style:
          theme.octaveTextStyle ??
          const TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // Métodos auxiliares
  void _drawText({
    required String text,
    required Offset position,
    required TextStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawGlyph({
    required String glyphName,
    required Offset position,
    required double size,
    required Color color,
    bool centerVertically = false,
    bool centerHorizontally = false,
  }) {
    final character = metadata.getCodepoint(glyphName);
    if (character.isEmpty) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: size,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    double yOffset = centerVertically ? -textPainter.height * 0.5 : 0;
    double xOffset = centerHorizontally ? -textPainter.width * 0.5 : 0;
    textPainter.paint(
      canvas,
      Offset(position.dx + xOffset, position.dy + yOffset),
    );
  }
}
