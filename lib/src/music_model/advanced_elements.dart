// lib/src/music_model/advanced_elements.dart

import 'musical_element.dart';

// === TÉCNICAS DE EXECUÇÃO (ELEMENTO QUE FALTAVA) ===

/// Tipos de técnicas de execução.
enum TechniqueType {
  pizzicato,
  snapPizzicato,
  colLegno,
  bowOnBridge,
  bowOnTailpiece,
  sulTasto,
  sulPonticello,
  martellato,
  ricochet,
  jet,
  vibrato,
  naturalHarmonic,
  artificialHarmonic,
}

/// Representa uma técnica de execução específica.
class PlayingTechnique extends MusicalElement {
  final TechniqueType type;

  PlayingTechnique({required this.type});
}

// === ORNAMENTOS AVANÇADOS ===

/// Tipos de ornamentos disponíveis
enum OrnamentType {
  trill,
  trillFlat,
  trillNatural,
  trillSharp,
  mordent,
  invertedMordent, // CORRIGIDO: Adicionado
  shortTrill,
  turn,
  turnInverted,
  invertedTurn, // CORRIGIDO: Adicionado
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
  fermataBelow, // CORRIGIDO: Adicionado
  fermataBelowInverted, // CORRIGIDO: Adicionado
  schleifer, // CORRIGIDO: Adicionado
  mordentUpperPrefix, // CORRIGIDO: Adicionado
  mordentLowerPrefix, // CORRIGIDO: Adicionado
  trillLigature, // CORRIGIDO: Adicionado
  haydn, // CORRIGIDO: Adicionado
  zigZagLineNoRightEnd, // CORRIGIDO: Adicionado
  zigZagLineWithRightEnd, // CORRIGIDO: Adicionado
  arpeggio,
  grace,
}

/// Representa um ornamento musical
class Ornament extends MusicalElement {
  final OrnamentType type;
  final bool above;
  final String? text;
  final Pitch? alternatePitch;

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
  pianississimo,
  pianissimo,
  piano,
  mezzoPiano,
  mezzoForte,
  forte,
  fortissimo,
  fortississimo,
  pppp,
  ppppp,
  pppppp,
  ffff,
  fffff,
  ffffff,
  sforzando,
  sforzandoFF,
  sforzandoPiano,
  sforzandoPianissimo, // CORRIGIDO: Adicionado
  rinforzando,
  fortePiano, // CORRIGIDO: "fortepiano" para "fortePiano"
  crescendo,
  diminuendo,
  niente, // CORRIGIDO: Adicionado
  ppp, // CORRIGIDO: Adicionado
  pp, // CORRIGIDO: Adicionado
  p, // CORRIGIDO: Adicionado
  mp, // CORRIGIDO: Adicionado
  mf, // CORRIGIDO: Adicionado
  f, // CORRIGIDO: Adicionado
  ff, // CORRIGIDO: Adicionado
  fff, // CORRIGIDO: Adicionado
  custom,
}

/// Representa uma indicação dinâmica
class Dynamic extends MusicalElement {
  final DynamicType type;
  final String? customText;
  final bool isHairpin;
  final double? length;

  Dynamic({
    required this.type,
    this.customText,
    this.isHairpin = false,
    this.length,
  });
}

// === ACORDES ===

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

  Note get highestNote {
    return notes.reduce(
      (a, b) => a.pitch.midiNumber > b.pitch.midiNumber ? a : b,
    );
  }

  Note get lowestNote {
    return notes.reduce(
      (a, b) => a.pitch.midiNumber < b.pitch.midiNumber ? a : b,
    );
  }
}

// === QUIÁLTERAS ===

class TupletRatio {
  final int actualNotes;
  final int normalNotes;

  const TupletRatio(this.actualNotes, this.normalNotes);
}

class Tuplet extends MusicalElement {
  final int actualNotes;
  final int normalNotes;
  final List<MusicalElement> elements;
  final List<Note> notes;
  final bool showBracket;
  final bool showNumber;
  final TupletRatio ratio;
  final bool bracket;

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

enum SlurDirection { up, down, auto }

class AdvancedSlur extends MusicalElement {
  final SlurType type;
  final SlurDirection direction;
  final int? voiceNumber;
  final String? id;

  AdvancedSlur({
    required this.type,
    this.direction = SlurDirection.auto,
    this.voiceNumber,
    this.id,
  });
}

// === MÚLTIPLAS VOZES ===

class Voice {
  final int number;
  final List<MusicalElement> elements;
  final String? name;

  Voice({required this.number, this.elements = const [], this.name});

  void add(MusicalElement element) => elements.add(element);
}

class MultiVoiceMeasure extends Measure {
  final Map<int, Voice> voices = {};

  void addVoice(Voice voice) {
    voices[voice.number] = voice;
  }

  Voice? getVoice(int number) => voices[number];

  List<int> get voiceNumbers => voices.keys.toList()..sort();
}

// === REPETIÇÕES AVANÇADAS ===

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
  // Novos tipos de repetição
  segnoSquare,
  codaSquare,
  repeat1Bar,
  repeat2Bars,
  repeat4Bars,
  simile,
  percentRepeat,
}

class RepeatMark extends MusicalElement {
  final RepeatType type;
  final String? label;
  final int? times;

  RepeatMark({required this.type, this.label, this.times});
}

// === TEXTOS E EXPRESSÕES ===

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

enum TextPlacement { above, below, inside }

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

class TempoMark extends MusicalElement {
  final DurationType beatUnit;
  final int? bpm;
  final String? text;
  final bool showMetronome;

  TempoMark({
    required this.beatUnit,
    this.bpm,
    this.text,
    this.showMetronome = true,
  });
}

// === BARRAS DE COMPASSO AVANÇADAS ===

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

class AdvancedBarline extends MusicalElement {
  final BarlineType type;
  final RepeatMark? repeatMark;
  final String? rehearsalLetter;

  AdvancedBarline({required this.type, this.repeatMark, this.rehearsalLetter});
}

// === LINHAS DE PROLONGAMENTO ===

enum LineType { solid, dashed, dotted, wavy, zigzag, trill, glissando, octave }

class Line extends MusicalElement {
  final LineType type;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final String? text;
  final bool showArrow;

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

enum BreathType { comma, tick, upbow, caesura, shortCaesura, longCaesura }

class Breath extends MusicalElement {
  final BreathType type;

  Breath({required this.type});
}

// === HARMÔNICOS ===

enum HarmonicType { natural, artificial, touched, sounding }

class Harmonic extends MusicalElement {
  final HarmonicType type;
  final Pitch? soundingPitch;

  Harmonic({required this.type, this.soundingPitch});
}

// === SINAIS DE OITAVA ===

enum OctaveType {
  octave8va,      // 8va (uma oitava acima)
  octave8vb,      // 8vb (uma oitava abaixo)
  octave15ma,     // 15ma (duas oitavas acima)
  octave15mb,     // 15mb (duas oitavas abaixo)
  octave22ma,     // 22ma (três oitavas acima)
  octave22mb,     // 22mb (três oitavas abaixo)
}

class OctaveMark extends MusicalElement {
  final OctaveType type;
  final double? length; // Comprimento da linha
  final bool showBracket;
  final String? text; // Texto customizado (ex: "loco")

  OctaveMark({
    required this.type,
    this.length,
    this.showBracket = true,
    this.text,
  });

  /// Retorna o glifo SMuFL apropriado
  String get glyphName {
    switch (type) {
      case OctaveType.octave8va:
        return 'ottava';
      case OctaveType.octave8vb:
        return 'ottavaBassa';
      case OctaveType.octave15ma:
        return 'quindicesima';
      case OctaveType.octave15mb:
        return 'quindicesimaAlta';
      case OctaveType.octave22ma:
        return 'ventiduesima';
      case OctaveType.octave22mb:
        return 'ventiduesimaAlta';
    }
  }

  /// Retorna o número do deslocamento de oitava
  int get octaveShift {
    switch (type) {
      case OctaveType.octave8va:
        return 1;
      case OctaveType.octave8vb:
        return -1;
      case OctaveType.octave15ma:
        return 2;
      case OctaveType.octave15mb:
        return -2;
      case OctaveType.octave22ma:
        return 3;
      case OctaveType.octave22mb:
        return -3;
    }
  }
}

// === CLUSTERS E NOTAÇÃO CONTEMPORÂNEA ===

enum ClusterType {
  tone,           // Cluster de tons
  semitone,       // Cluster de semitons
  microtone,      // Cluster microtonal
  white,          // Somente teclas brancas
  black,          // Somente teclas pretas
}

class Cluster extends MusicalElement {
  final ClusterType type;
  final Pitch lowestNote;
  final Pitch highestNote;
  final Duration duration;
  final bool showBracket;

  Cluster({
    required this.type,
    required this.lowestNote,
    required this.highestNote,
    required this.duration,
    this.showBracket = true,
  });
}

// === SÍMBOLOS DE MÉTRICA E MARCAÇÃO TEMPORAL ===

enum MetronomeMarkType {
  note,           // Nota + BPM
  equation,       // Nota = Nota
  range,          // Faixa de BPM
  approximate,    // BPM aproximado
}

class MetronomeMark extends MusicalElement {
  final MetronomeMarkType type;
  final DurationType? leftNote;
  final DurationType? rightNote;
  final int? bpm;
  final int? minBpm;
  final int? maxBpm;
  final bool showParentheses;

  MetronomeMark({
    required this.type,
    this.leftNote,
    this.rightNote,
    this.bpm,
    this.minBpm,
    this.maxBpm,
    this.showParentheses = false,
  });
}

// === CAESURAS E RESPIRAÇÕES AVANÇADAS ===

enum CaesuraType {
  short,          // Caesura curta
  long,           // Caesura longa
  thick,          // Caesura grossa
  curved,         // Caesura curva
  double,         // Caesura dupla
}

class Caesura extends MusicalElement {
  final CaesuraType type;

  Caesura({required this.type});

  String get glyphName {
    switch (type) {
      case CaesuraType.short:
        return 'caesuraShort';
      case CaesuraType.long:
        return 'caesura';
      case CaesuraType.thick:
        return 'caesuraThick';
      case CaesuraType.curved:
        return 'caesuraCurved';
      case CaesuraType.double:
        return 'caesura';
    }
  }
}
