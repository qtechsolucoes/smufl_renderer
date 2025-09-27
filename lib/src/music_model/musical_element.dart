// lib/src/music_model/musical_element.dart

import 'pitch.dart';
import 'duration.dart';

// Re-exporta para que o usuário do pacote tenha acesso fácil.
export 'pitch.dart';
export 'duration.dart';

/// Descreve o estado de uma nota em relação a uma barra de ligação (beam).
enum BeamType { start, inner, end }

/// Define os tipos de articulações que uma nota pode ter.
enum ArticulationType { staccato, accent, tenuto }

/// Define se uma nota inicia ou termina uma ligadura de valor (tie).
enum TieType { start, end }

/// A classe base para todos os elementos em uma partitura.
abstract class MusicalElement {}

/// Representa uma clave no início de uma pauta.
class Clef extends MusicalElement {
  final String type; // 'g', 'f', 'c'
  Clef({this.type = 'g'});
}

/// Representa a armadura de clave.
class KeySignature extends MusicalElement {
  /// Número de sustenidos (positivo) ou bemóis (negativo).
  final int count;
  KeySignature(this.count);
}

/// Representa a fórmula de compasso.
class TimeSignature extends MusicalElement {
  final int numerator;
  final int denominator;
  TimeSignature({required this.numerator, required this.denominator});
}

/// Representa uma nota musical com altura e duração.
class Note extends MusicalElement {
  final Pitch pitch;
  final Duration duration;

  /// Opcional: Define se e como a nota se conecta a uma barra de ligação.
  final BeamType? beam;

  /// Opcional: Lista de articulações para esta nota.
  final List<ArticulationType> articulations;

  /// Opcional: Define se esta nota inicia ou termina uma ligadura de valor.
  final TieType? tie;

  Note({
    required this.pitch,
    required this.duration,
    this.beam,
    this.articulations = const [],
    this.tie, // Nova propriedade
  });
}

/// Representa uma pausa.
class Rest extends MusicalElement {
  final Duration duration;
  Rest({required this.duration});
}

/// Representa uma linha de compasso.
class Barline extends MusicalElement {}

/// Representa um compasso, que contém elementos musicais.
class Measure {
  final List<MusicalElement> elements = [];
  void add(MusicalElement element) => elements.add(element);
}

/// Representa uma pauta, que contém compassos.
class Staff {
  final List<Measure> measures = [];
  void add(Measure measure) => measures.add(measure);
}
