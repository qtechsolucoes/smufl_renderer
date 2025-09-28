// lib/src/rendering/staff_coordinate_system.dart

import 'dart:ui';

/// Sistema de coordenadas baseado em staff spaces para posicionamento preciso
/// de elementos musicais, seguindo padrões SMuFL.
class StaffCoordinateSystem {
  final double staffSpace;
  final Offset staffBaseline; // Linha central da pauta (3ª linha)

  StaffCoordinateSystem({
    required this.staffSpace,
    required this.staffBaseline,
  });

  /// Retorna a posição Y de uma linha específica da pauta
  /// Linhas: 1 (inferior) até 5 (superior) - numeração padrão musical
  /// Linha 3 é o baseline (centro)
  double getStaffLineY(int lineNumber) {
    // Corrigir numeração: linha 1 = inferior, linha 5 = superior
    final offsetFromBaseline = (lineNumber - 3) * staffSpace;
    return staffBaseline.dy - offsetFromBaseline;
  }

  /// Retorna a posição Y de um espaço específico da pauta
  /// Espaços: 1 (entre linhas 1-2) até 4 (entre linhas 4-5)
  double getStaffSpaceY(int spaceNumber) {
    // Corrigir numeração: espaço 1 = inferior, espaço 4 = superior
    final offsetFromBaseline = (spaceNumber - 2.5) * staffSpace;
    return staffBaseline.dy - offsetFromBaseline;
  }

  /// Converte posição de nota (step + octave) para posição Y na pauta
  /// Para clave de sol: G4 fica na linha 2, C5 no espaço acima da pauta
  double getNoteY(String step, int octave, {String clef = 'treble'}) {
    if (clef == 'treble' || clef == 'g') {
      return _getTrebleClefNoteY(step, octave);
    }
    // Adicionar outras claves aqui no futuro
    return staffBaseline.dy;
  }

  double _getTrebleClefNoteY(String step, int octave) {
    // CORREÇÃO: Sistema diatônico (não cromático)
    // staffBaseline = 3ª linha da pauta (B4 na clave de Sol)
    // Cada linha/espaço = 0.5 * staffSpace

    // Mapeamento diatônico das notas (posição na escala de 7 notas)
    final stepToDiatonic = {
      'C': 0,
      'D': 1,
      'E': 2,
      'F': 3,
      'G': 4,
      'A': 5,
      'B': 6,
    };

    // B4 = linha central (baseline) = posição 0
    const refStep = 'B';
    const refOctave = 4;
    final refDiatonicPos = stepToDiatonic[refStep]!;

    // Posição diatônica da nota atual
    final noteDiatonicPos = stepToDiatonic[step.toUpperCase()] ?? 0;

    // Calcular distância em "passos" diatônicos
    final diatonicSteps =
        (noteDiatonicPos - refDiatonicPos) + ((octave - refOctave) * 7);

    // Cada passo diatônico = 0.5 * staffSpace
    final noteY = staffBaseline.dy - (diatonicSteps * staffSpace * 0.5);

    return noteY;
  }

  /// Retorna posições para acidentes na armadura de clave
  List<double> getKeySignaturePositions(int count, {String clef = 'treble'}) {
    if (clef == 'treble' || clef == 'g') {
      if (count > 0) {
        // Sustenidos em clave de sol: F# C# G# D# A# E# B#
        return [
          getNoteY('F', 5), // F#
          getNoteY('C', 5), // C#
          getNoteY('G', 5), // G#
          getNoteY('D', 5), // D#
          getNoteY('A', 4), // A#
          getNoteY('E', 5), // E#
          getNoteY('B', 4), // B#
        ].take(count).toList();
      } else {
        // Bemóis em clave de sol: Bb Eb Ab Db Gb Cb Fb
        return [
          getNoteY('B', 4), // Bb
          getNoteY('E', 5), // Eb
          getNoteY('A', 4), // Ab
          getNoteY('D', 5), // Db
          getNoteY('G', 4), // Gb
          getNoteY('C', 5), // Cb
          getNoteY('F', 4), // Fb
        ].take(count.abs()).toList();
      }
    }
    return [];
  }

  /// Calcula posição para fórmula de compasso
  /// Numerador acima da linha central, denominador abaixo
  Offset getTimeSignatureNumeratorPosition(Offset basePosition) {
    return Offset(basePosition.dx, staffBaseline.dy - (staffSpace * 0.5));
  }

  Offset getTimeSignatureDenominatorPosition(Offset basePosition) {
    return Offset(basePosition.dx, staffBaseline.dy + (staffSpace * 0.5));
  }

  /// Posição padrão para clave de sol
  /// A clave deve ser posicionada de forma que o círculo fique na 2ª linha
  Offset getClefPosition(Offset basePosition, {String clef = 'treble'}) {
    if (clef == 'treble' || clef == 'g') {
      // A clave de sol deve ficar centrada na pauta
      return Offset(basePosition.dx, staffBaseline.dy);
    }
    return basePosition;
  }

  /// Desenha as linhas da pauta
  void drawStaffLines(Canvas canvas, double width, Paint paint) {
    for (int line = 1; line <= 5; line++) {
      final y = getStaffLineY(line);
      canvas.drawLine(
        Offset(staffBaseline.dx, y),
        Offset(staffBaseline.dx + width, y),
        paint,
      );
    }
  }

  /// Calcula altura total necessária para a pauta
  double get totalStaffHeight => staffSpace * 4; // 4 espaços entre 5 linhas

  /// Margem adicional acima e abaixo da pauta para elementos externos
  double get staffMargin => staffSpace * 2;

  /// Altura total incluindo margens
  double get totalHeight => totalStaffHeight + (staffMargin * 2);

  /// Calcula a posição staff position (line number) baseado em Y
  /// Retorna valores como: -4, -3, -2, -1, 0, 1, 2, 3, 4
  /// onde 0 = linha central, positivo = acima, negativo = abaixo
  int getStaffPosition(double y) {
    final deltaY = staffBaseline.dy - y;
    final staffSpacePosition = deltaY / (staffSpace * 0.5);
    return staffSpacePosition.round();
  }
}
