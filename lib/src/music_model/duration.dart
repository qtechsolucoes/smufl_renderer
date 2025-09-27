// lib/src/music_model/duration.dart

/// Define os tipos de duração rítmica.
enum DurationType {
  whole(4.0, 'noteheadWhole'),
  half(2.0, 'noteheadHalf'),
  quarter(1.0, 'noteheadBlack'),
  eighth(0.5, 'noteheadBlack'),
  sixteenth(0.25, 'noteheadBlack');

  /// O valor numérico relativo (semínima = 1.0).
  final double value;

  /// O nome do glifo SMuFL para a cabeça da nota.
  final String glyphName;

  const DurationType(this.value, this.glyphName);
}

/// Representa a duração de uma nota ou pausa.
class Duration {
  /// O tipo de duração (semibreve, mínima, etc.).
  final DurationType type;

  /// O número de pontos de aumento.
  final int dots;

  const Duration(this.type, {this.dots = 0});
}
