// lib/src/music_model/musical_element.dart

import 'pitch.dart';
import 'duration.dart';

// Re-exporta para que o usuário do pacote tenha acesso fácil.
export 'pitch.dart';
export 'duration.dart';
export 'advanced_elements.dart';

// Import das classes avançadas necessárias
import 'advanced_elements.dart';

/// Descreve o estado de uma nota em relação a uma barra de ligação (beam).
enum BeamType { start, inner, end }

/// Define os tipos de articulações que uma nota pode ter.
enum ArticulationType {
  staccato,         // Ponto
  staccatissimo,    // Ponto triangular
  accent,           // Acento
  strongAccent,     // Acento forte
  tenuto,           // Traço
  marcato,          // Combinação de acento e tenuto
  legato,           // Ligado (normalmente como slur)
  portato,          // Combinação de staccato e tenuto
  upBow,            // Arco para cima (cordas)
  downBow,          // Arco para baixo (cordas)
  harmonics,        // Harmônicos
  pizzicato,        // Pizzicato
  snap,             // Snap pizzicato
  thumb,            // Dedilhado com polegar
  stopped,          // Notas abafadas (metal)
  open,             // Notas abertas (metal)
  halfStopped,      // Meio abafado (metal)
}

/// Define se uma nota inicia ou termina uma ligadura de valor (tie).
enum TieType { start, end }

/// Define se uma nota inicia ou termina uma ligadura de expressão (slur).
enum SlurType { start, end }

/// A classe base para todos os elementos em uma partitura.
abstract class MusicalElement {}

/// Tipos de claves musicais disponíveis
enum ClefType {
  /// Clave de Sol (G clef)
  treble,
  /// Clave de Sol 8ª acima
  treble8va,
  /// Clave de Sol 8ª abaixo
  treble8vb,
  /// Clave de Sol 15ª acima
  treble15ma,
  /// Clave de Sol 15ª abaixo
  treble15mb,
  /// Clave de Fá (F clef) - 4ª linha (posição padrão)
  bass,
  /// Clave de Fá na 3ª linha
  bassThirdLine,
  /// Clave de Fá 8ª acima
  bass8va,
  /// Clave de Fá 8ª abaixo
  bass8vb,
  /// Clave de Fá 15ª acima
  bass15ma,
  /// Clave de Fá 15ª abaixo
  bass15mb,

  /// Clave de Dó na 1ª linha (soprano)
  soprano,
  /// Clave de Dó na 2ª linha (mezzo-soprano)
  mezzoSoprano,
  /// Clave de Dó na 3ª linha (alto/viola)
  alto,
  /// Clave de Dó na 4ª linha (tenor)
  tenor,
  /// Clave de Dó na 5ª linha (baritono - histórico)
  baritone,
  /// Clave de Dó 8ª abaixo
  c8vb,
  /// Clave de percussão 1
  percussion,
  /// Clave de percussão 2
  percussion2,
  /// Clave de tablatura 6 cordas
  tab6,
  /// Clave de tablatura 4 cordas
  tab4,
}

/// Representa uma clave no início de uma pauta.
class Clef extends MusicalElement {
  final ClefType clefType;
  final int? staffPosition; // Para claves de Dó que podem variar de posição

  Clef({this.clefType = ClefType.treble, this.staffPosition, String? type}) {
    // Backward compatibility - se type for fornecido, converta para ClefType
    if (type != null) {
      switch (type) {
        case 'g':
          _clefType = ClefType.treble;
          break;
        case 'f':
          _clefType = ClefType.bass;
          break;
        case 'c':
          _clefType = ClefType.alto;
          break;
        default:
          _clefType = ClefType.treble;
      }
    } else {
      _clefType = clefType;
    }
  }

  ClefType _clefType = ClefType.treble;

  /// Getter para o tipo de clave atual
  ClefType get actualClefType => _clefType;

  /// Retorna o glifo SMuFL correspondente à clave
  String get glyphName {
    switch (_clefType) {
      case ClefType.treble:
        return 'gClef';
      case ClefType.treble8va:
        return 'gClef8va';
      case ClefType.treble8vb:
        return 'gClef8vb';
      case ClefType.treble15ma:
        return 'gClef15ma';
      case ClefType.treble15mb:
        return 'gClef15mb';
      case ClefType.bass:
      case ClefType.bassThirdLine:
        return 'fClef';
      case ClefType.bass8va:
        return 'fClef8va';
      case ClefType.bass8vb:
        return 'fClef8vb';
      case ClefType.bass15ma:
        return 'fClef15ma';
      case ClefType.bass15mb:
        return 'fClef15mb';
      case ClefType.soprano:
      case ClefType.mezzoSoprano:
      case ClefType.alto:
      case ClefType.tenor:
      case ClefType.baritone:
        return 'cClef';
      case ClefType.c8vb:
        return 'cClef8vb';
      case ClefType.percussion:
        return 'unpitchedPercussionClef1';
      case ClefType.percussion2:
        return 'unpitchedPercussionClef2';
      case ClefType.tab6:
        return '6stringTabClef';
      case ClefType.tab4:
        return '4stringTabClef';
    }
  }

  /// Retorna a posição da linha de referência da clave no pentagrama
  /// (0 = linha central, positivo = acima, negativo = abaixo)
  int get referenceLinePosition {
    switch (_clefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        return 2; // Sol na 2ª linha
      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        return -2; // Fá na 4ª linha (posição padrão)
      case ClefType.bassThirdLine:
        return -1; // Fá na 3ª linha

      // Claves de Dó em todas as posições
      case ClefType.soprano:
        return 2; // Dó na 1ª linha
      case ClefType.mezzoSoprano:
        return 1; // Dó na 2ª linha
      case ClefType.alto:
        return 0; // Dó na 3ª linha (linha central)
      case ClefType.tenor:
        return -1; // Dó na 4ª linha
      case ClefType.baritone:
        return -2; // Dó na 5ª linha
      case ClefType.c8vb:
        return 0; // Dó na 3ª linha (oitava abaixo)
      case ClefType.percussion:
      case ClefType.percussion2:
      case ClefType.tab6:
      case ClefType.tab4:
        return 0; // Centralizada
    }
  }

  /// Retorna o deslocamento de oitava aplicado pela clave
  int get octaveShift {
    switch (_clefType) {
      case ClefType.treble8va:
      case ClefType.bass8va:
        return 1;
      case ClefType.treble8vb:
      case ClefType.bass8vb:
      case ClefType.c8vb:
        return -1;
      case ClefType.treble15ma:
      case ClefType.bass15ma:
        return 2;
      case ClefType.treble15mb:
      case ClefType.bass15mb:
        return -2;
      default:
        return 0;
    }
  }

  /// Backward compatibility - DEPRECATED: Use actualClefType instead
  @Deprecated('Use actualClefType instead. This getter will be removed in future versions.')
  String get type => _getCompatibilityType();

  String _getCompatibilityType() {
    switch (_clefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        return 'g';
      case ClefType.bass:
      case ClefType.bassThirdLine:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        return 'f';
      case ClefType.soprano:
      case ClefType.mezzoSoprano:
      case ClefType.alto:
      case ClefType.tenor:
      case ClefType.baritone:
      case ClefType.c8vb:
        return 'c';
      default:
        return 'g';
    }
  }

  /// Obtém a posição vertical da linha de referência da clave no pentagrama
  /// conforme especificações SMuFL (em unidades staff space)
  double get referenceLineOffsetSmufl {
    switch (_clefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        return -1.0; // Sol na 2ª linha (1 staff space abaixo do centro)
      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        return 1.0; // Fá na 4ª linha (1 staff space acima do centro)
      case ClefType.bassThirdLine:
        return 0.0; // Fá na 3ª linha (linha central)
      case ClefType.soprano:
        return -2.0; // Dó na 1ª linha
      case ClefType.mezzoSoprano:
        return -1.0; // Dó na 2ª linha
      case ClefType.alto:
        return 0.0; // Dó na 3ª linha (linha central)
      case ClefType.tenor:
        return 1.0; // Dó na 4ª linha
      case ClefType.baritone:
        return 2.0; // Dó na 5ª linha
      case ClefType.c8vb:
        return 0.0; // Dó na 3ª linha (oitava abaixo)
      case ClefType.percussion:
      case ClefType.percussion2:
      case ClefType.tab6:
      case ClefType.tab4:
        return 0.0; // Centralizada
    }
  }
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

  /// Calcula o valor total permitido no compasso.
  /// Fórmula: numerator × (1 / denominator)
  double get measureValue => numerator * (1.0 / denominator);
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

  /// Lista de ornamentos aplicados à nota
  final List<Ornament> ornaments;

  /// Dinâmica específica da nota
  final Dynamic? dynamicElement;

  /// Técnicas especiais da nota
  final List<PlayingTechnique> techniques;

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
  final List<Ornament> ornaments;

  Rest({required this.duration, this.ornaments = const []});
}



/// Representa uma linha de compasso.
class Barline extends MusicalElement {}

/// Representa um compasso, que contém elementos musicais.
class Measure {
  final List<MusicalElement> elements = [];
  void add(MusicalElement element) => elements.add(element);

  /// Calcula o valor total atual das figuras musicais no compasso.
  double get currentMusicalValue {
    double total = 0.0;
    for (final element in elements) {
      if (element is Note) {
        total += element.duration.realValue;
      } else if (element is Rest) {
        total += element.duration.realValue;
      } else if (element.runtimeType.toString() == 'Chord') {
        // Usar reflexão para evitar import circular
        final dynamic chord = element;
        if (chord.duration != null) {
          total += chord.duration.realValue;
        }
      } else if (element.runtimeType.toString() == 'Tuplet') {
        // Calcular valor da quiáltera baseado na razão
        final dynamic tuplet = element;
        double tupletValue = 0.0;

        // Somar duração de todas as notas da quiáltera
        for (final tupletElement in tuplet.elements) {
          if (tupletElement is Note) {
            tupletValue += tupletElement.duration.realValue;
          } else if (tupletElement.runtimeType.toString() == 'Chord') {
            final dynamic chord = tupletElement;
            if (chord.duration != null) {
              tupletValue += chord.duration.realValue;
            }
          }
        }

        // Aplicar a razão da quiáltera (normalNotes / actualNotes)
        if (tuplet.actualNotes > 0) {
          tupletValue = tupletValue * (tuplet.normalNotes / tuplet.actualNotes);
        }

        total += tupletValue;
      }
    }
    return total;
  }

  /// Obtém a fórmula de compasso ativa neste compasso.
  TimeSignature? get timeSignature {
    for (final element in elements) {
      if (element is TimeSignature) {
        return element;
      }
    }
    return null;
  }

  /// Verifica se o compasso está corretamente preenchido.
  bool get isValidlyFilled {
    final ts = timeSignature;
    if (ts == null) return true; // Sem fórmula = sem validação
    return currentMusicalValue == ts.measureValue;
  }

  /// Verifica se ainda há espaço para adicionar uma duração específica.
  bool canAddDuration(Duration duration) {
    final ts = timeSignature;
    if (ts == null) return true; // Sem fórmula = sempre pode adicionar
    return currentMusicalValue + duration.realValue <= ts.measureValue;
  }

  /// Calcula quanto tempo ainda resta no compasso.
  double get remainingValue {
    final ts = timeSignature;
    if (ts == null) return double.infinity;
    return ts.measureValue - currentMusicalValue;
  }
}

/// Representa uma pauta, que contém compassos.
class Staff {
  final List<Measure> measures = [];
  void add(Measure measure) => measures.add(measure);
}
