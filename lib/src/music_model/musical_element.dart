// lib/src/music_model/musical_element.dart

import 'pitch.dart';
import 'duration.dart';
import 'advanced_elements.dart';

// Re-exporta para que o usuário do pacote tenha acesso fácil.
export 'pitch.dart';
export 'duration.dart';
export 'advanced_elements.dart';

/// Descreve o estado de uma nota em relação a uma barra de ligação (beam).
enum BeamType { start, inner, end }

/// Define os tipos de articulações que uma nota pode ter.
enum ArticulationType { staccato, accent, tenuto }

/// Define se uma nota inicia ou termina uma ligadura de valor (tie).
enum TieType { start, end }

/// Define se uma nota inicia ou termina uma ligadura de expressão (slur).
enum SlurType { start, end }

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

  final BeamType? beam;
  final List<ArticulationType> articulations;
  final TieType? tie;

  /// Opcional: Define se esta nota inicia ou termina uma ligadura de expressão.
  final SlurType? slur;

  /// Lista de ornamentos aplicados à nota (forward declaration)
  final List<dynamic> ornaments;

  /// Dinâmica específica da nota (forward declaration)
  final dynamic dynamicElement;

  /// Técnicas especiais da nota (forward declaration)
  final List<dynamic> techniques;

  Note({
    required this.pitch,
    required this.duration,
    this.beam,
    this.articulations = const [],
    this.tie,
    this.slur,
    this.ornaments = const [],
    this.dynamicElement,
    this.techniques = const [],
  });
}

/// Representa uma pausa.
class Rest extends MusicalElement {
  final Duration duration;

  /// Lista de ornamentos aplicados à pausa (ex: fermata)
  final List<dynamic> ornaments;

  Rest({required this.duration, this.ornaments = const []});
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
