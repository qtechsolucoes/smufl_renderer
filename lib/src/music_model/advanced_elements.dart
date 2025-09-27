// lib/src/music_model/advanced_elements.dart

import 'musical_element.dart';

// === ORNAMENTOS AVANÇADOS ===

/// Tipos de ornamentos disponíveis
enum OrnamentType {
  trill,
  trillFlat,
  trillNatural,
  trillSharp,
  mordent,
  shortTrill,
  turn,
  turnInverted,
  turnSlash,
  appoggiaturaUp,
  appoggiaturaDown,
  acciaccatura,
  glissando,
  portamento,
  slide,
  scoop,
  fall,
  doit,
  plop,
  bend,
  shake,
  wavyLine,
  zigzagLine,
  fermata,
  arpeggio,
  grace,
}

/// Representa um ornamento musical
class Ornament extends MusicalElement {
  final OrnamentType type;
  final bool above; // Se o ornamento fica acima ou abaixo da nota
  final String? text; // Texto adicional se necessário
  final Pitch? alternatePitch; // Para ornamentos que especificam altura

  Ornament({
    required this.type,
    this.above = true,
    this.text,
    this.alternatePitch,
  });
}

// === DINÂMICAS AVANÇADAS ===

/// Tipos de dinâmicas disponíveis
enum DynamicType {
  // Dinâmicas básicas
  pianississimo, // ppp
  pianissimo, // pp
  piano, // p
  mezzoPiano, // mp
  mezzoForte, // mf
  forte, // f
  fortissimo, // ff
  fortississimo, // fff

  // Dinâmicas extremas
  pppp, ppppp, pppppp,
  ffff, fffff, ffffff,

  // Acentos
  sforzando,
  sforzandoFF,
  sforzandoPiano,
  rinforzando,
  fortepiano,

  // Crescendos e diminuendos
  crescendo,
  diminuendo,

  // Personalizadas
  custom,
}

/// Representa uma indicação dinâmica
class Dynamic extends MusicalElement {
  final DynamicType type;
  final String? customText; // Para dinâmicas personalizadas
  final bool isHairpin; // Se é um crescendo/diminuendo
  final double? length; // Comprimento para hairpins

  Dynamic({
    required this.type,
    this.customText,
    this.isHairpin = false,
    this.length,
  });
}

// === ACORDES ===

/// Representa um acorde (múltiplas notas simultâneas)
class Chord extends MusicalElement {
  final List<Note> notes;
  final Duration duration;
  final List<ArticulationType> articulations;
  final TieType? tie;
  final SlurType? slur;
  final BeamType? beam;
  final List<Ornament> ornaments;
  final Dynamic? dynamic;

  Chord({
    required this.notes,
    required this.duration,
    this.articulations = const [],
    this.tie,
    this.slur,
    this.beam,
    this.ornaments = const [],
    this.dynamic,
  });

  /// Retorna a nota mais aguda do acorde
  Note get highestNote {
    return notes.reduce((a, b) =>
      a.pitch.midiNumber > b.pitch.midiNumber ? a : b);
  }

  /// Retorna a nota mais grave do acorde
  Note get lowestNote {
    return notes.reduce((a, b) =>
      a.pitch.midiNumber < b.pitch.midiNumber ? a : b);
  }
}

// === QUIÁLTERAS ===

/// Representa uma proporção de quiáltera
class TupletRatio {
  final int actualNotes;
  final int normalNotes;

  const TupletRatio(this.actualNotes, this.normalNotes);
}

/// Representa uma quiáltera (tuplet)
class Tuplet extends MusicalElement {
  final int actualNotes; // Quantidade real de notas
  final int normalNotes; // Quantidade normal no tempo
  final List<MusicalElement> elements; // Notas ou outros elementos
  final List<Note> notes; // Lista específica de notas para compatibilidade
  final bool showBracket; // Se mostra colchete
  final bool showNumber; // Se mostra número
  final TupletRatio ratio; // Proporção da quiáltera
  final bool bracket; // Alias para showBracket

  Tuplet({
    required this.actualNotes,
    required this.normalNotes,
    required this.elements,
    List<Note>? notes,
    this.showBracket = true,
    this.showNumber = true,
    TupletRatio? ratio,
    bool? bracket,
  }) : notes = notes ?? elements.whereType<Note>().toList(),
       ratio = ratio ?? TupletRatio(actualNotes, normalNotes),
       bracket = bracket ?? showBracket;
}

// === LIGADURAS AVANÇADAS ===

/// Tipos de ligaduras
enum SlurDirection { up, down, auto }

/// Ligadura avançada com mais controle
class AdvancedSlur extends MusicalElement {
  final SlurType type;
  final SlurDirection direction;
  final int? voiceNumber; // Para múltiplas vozes
  final String? id; // Identificador único para ligaduras complexas

  AdvancedSlur({
    required this.type,
    this.direction = SlurDirection.auto,
    this.voiceNumber,
    this.id,
  });
}

// === MÚLTIPLAS VOZES ===

/// Representa uma voz musical independente
class Voice {
  final int number;
  final List<MusicalElement> elements;
  final String? name;

  Voice({
    required this.number,
    this.elements = const [],
    this.name,
  });

  void add(MusicalElement element) => elements.add(element);
}

/// Compasso com múltiplas vozes
class MultiVoiceMeasure extends Measure {
  final Map<int, Voice> voices = {};

  void addVoice(Voice voice) {
    voices[voice.number] = voice;
  }

  Voice? getVoice(int number) => voices[number];

  List<int> get voiceNumbers => voices.keys.toList()..sort();
}

// === REPETIÇÕES AVANÇADAS ===

/// Tipos de repetição
enum RepeatType {
  start,
  end,
  segno,
  coda,
  dalSegno,
  dalSegnoAlCoda,
  daCapo,
  daCapoAlCoda,
  fine,
  toCoda,
}

/// Marcas de repetição
class RepeatMark extends MusicalElement {
  final RepeatType type;
  final String? label; // Para repetições numeradas (1., 2., etc.)
  final int? times; // Quantas vezes repetir

  RepeatMark({
    required this.type,
    this.label,
    this.times,
  });
}

// === TEXTOS E EXPRESSÕES ===

/// Tipos de texto musical
enum TextType {
  lyrics,
  chord,
  rehearsal,
  tempo,
  expression,
  instruction,
  copyright,
  title,
  subtitle,
  composer,
  arranger,
  dynamics,
}

/// Posicionamento do texto
enum TextPlacement { above, below, inside }

/// Texto musical
class MusicText extends MusicalElement {
  final String text;
  final TextType type;
  final TextPlacement placement;
  final String? fontFamily;
  final double? fontSize;
  final bool? bold;
  final bool? italic;

  MusicText({
    required this.text,
    required this.type,
    this.placement = TextPlacement.above,
    this.fontFamily,
    this.fontSize,
    this.bold,
    this.italic,
  });
}

// === TÉCNICAS ESPECIAIS ===

/// Técnicas especiais para notas
enum NoteTechnique {
  harmonic,
  glissando,
  tremolo,
  bend,
  slide,
  vibrato,
  tapping,
  hammer,
  pullOff,
  pinchHarmonic,
  artificialHarmonic,
  palmMute,
  deadNote,
  ghost,
}

// === INDICAÇÕES DE TEMPO ===

/// Indicação de tempo (metrônomo)
class TempoMark extends MusicalElement {
  final DurationType beatUnit; // Unidade de tempo
  final int? bpm; // Batidas por minuto
  final String? text; // Texto descritivo (Allegro, Andante, etc.)
  final bool showMetronome; // Se mostra o símbolo de metrônomo

  TempoMark({
    required this.beatUnit,
    this.bpm,
    this.text,
    this.showMetronome = true,
  });
}

// === BARRAS DE COMPASSO AVANÇADAS ===

/// Tipos de barra de compasso
enum BarlineType {
  single,
  double,
  final_,
  repeatStart,
  repeatEnd,
  repeatBoth,
  thick,
  thin,
  dashed,
  dotted,
  invisible,
  short,
  tick,
}

/// Barra de compasso avançada
class AdvancedBarline extends MusicalElement {
  final BarlineType type;
  final RepeatMark? repeatMark;
  final String? rehearsalLetter;

  AdvancedBarline({
    required this.type,
    this.repeatMark,
    this.rehearsalLetter,
  });
}

// === LINHAS DE PROLONGAMENTO ===

/// Tipos de linha
enum LineType {
  solid,
  dashed,
  dotted,
  wavy,
  zigzag,
  trill,
  glissando,
  octave,
}

/// Linha de prolongamento ou conexão
class Line extends MusicalElement {
  final LineType type;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final String? text; // Texto que acompanha a linha
  final bool showArrow; // Se mostra seta no final

  Line({
    required this.type,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.text,
    this.showArrow = false,
  });
}

// === RESPIRAÇÕES E CESURAS ===

/// Tipos de respiração
enum BreathType {
  comma,
  tick,
  upbow,
  caesura,
  shortCaesura,
  longCaesura,
}

/// Marca de respiração ou cesura
class Breath extends MusicalElement {
  final BreathType type;

  Breath({required this.type});
}

// === HARMÔNICOS ===

/// Tipos de harmônico
enum HarmonicType {
  natural,
  artificial,
  touched,
  sounding,
}

/// Harmônico
class Harmonic extends MusicalElement {
  final HarmonicType type;
  final Pitch? soundingPitch; // Altura resultante

  Harmonic({
    required this.type,
    this.soundingPitch,
  });
}