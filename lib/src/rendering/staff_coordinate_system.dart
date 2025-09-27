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
  /// Linhas: 1 (superior) até 5 (inferior)
  /// Linha 3 é o baseline (centro)
  double getStaffLineY(int lineNumber) {
    // Linhas são numeradas de 1-5, com 3 sendo o centro
    final offsetFromBaseline = (3 - lineNumber) * staffSpace;
    return staffBaseline.dy + offsetFromBaseline;
  }

  /// Retorna a posição Y de um espaço específico da pauta
  /// Espaços: 1 (entre linhas 1-2) até 4 (entre linhas 4-5)
  double getStaffSpaceY(int spaceNumber) {
    // Espaços são meio staff space acima/abaixo das linhas
    final offsetFromBaseline = (3.5 - spaceNumber) * staffSpace;
    return staffBaseline.dy + offsetFromBaseline;
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
    // Clave de sol padrão: G4 fica na 2ª linha (linha inferior = 1)
    // staffBaseline representa a 3ª linha (linha central)

    // Posições das linhas:
    // Linha 1 (inferior): staffBaseline.dy + staffSpace
    // Linha 2: staffBaseline.dy
    // Linha 3 (central): staffBaseline.dy - staffSpace
    // Linha 4: staffBaseline.dy - (staffSpace * 2)
    // Linha 5 (superior): staffBaseline.dy - (staffSpace * 3)

    final Map<String, double> notePositions = {
      // Octave 4 - referência principal
      'C4': staffBaseline.dy + (staffSpace * 2.0), // Linha suplementar abaixo
      'D4': staffBaseline.dy + (staffSpace * 1.5), // Espaço abaixo da pauta
      'E4': staffBaseline.dy + (staffSpace * 1.0), // 1ª linha (inferior)
      'F4': staffBaseline.dy + (staffSpace * 0.5), // 1º espaço
      'G4': staffBaseline.dy + (staffSpace * 0.0), // 2ª linha
      'A4': staffBaseline.dy - (staffSpace * 0.5), // 2º espaço
      'B4': staffBaseline.dy - (staffSpace * 1.0), // 3ª linha (central/baseline)

      // Octave 5
      'C5': staffBaseline.dy - (staffSpace * 1.5), // 3º espaço
      'D5': staffBaseline.dy - (staffSpace * 2.0), // 4ª linha
      'E5': staffBaseline.dy - (staffSpace * 2.5), // 4º espaço
      'F5': staffBaseline.dy - (staffSpace * 3.0), // 5ª linha (superior)
      'G5': staffBaseline.dy - (staffSpace * 3.5), // Espaço acima da pauta
      'A5': staffBaseline.dy - (staffSpace * 4.0), // Linha suplementar acima
      'B5': staffBaseline.dy - (staffSpace * 4.5),
    };

    final key = '$step$octave';
    return notePositions[key] ?? staffBaseline.dy;
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
  /// Numerador na 4ª linha, denominador na 2ª linha
  Offset getTimeSignatureNumeratorPosition(Offset basePosition) {
    return Offset(basePosition.dx, getStaffLineY(4));
  }

  Offset getTimeSignatureDenominatorPosition(Offset basePosition) {
    return Offset(basePosition.dx, getStaffLineY(2));
  }

  /// Posição padrão para clave de sol
  /// A clave deve ser posicionada de forma que o círculo fique na 2ª linha
  Offset getClefPosition(Offset basePosition, {String clef = 'treble'}) {
    if (clef == 'treble' || clef == 'g') {
      // A clave de sol deve ter seu ponto de referência na 2ª linha (G4)
      // Baseado nos metadados Bravura, ajustamos para que fique corretamente posicionada
      return Offset(basePosition.dx, staffBaseline.dy + (staffSpace * 0.3));
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
}