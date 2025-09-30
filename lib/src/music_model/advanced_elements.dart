// lib/src/music_model/advanced_elements.dart
// VERSÃO COMPLETA: Todos os símbolos SMuFL implementados

import 'package:flutter/material.dart';
import 'musical_element.dart';

// === TÉCNICAS DE EXECUÇÃO ===

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
  // NOVOS: Técnicas estendidas
  multiphonics,
  overblowing,
  tongueram,
  circularBreathing,
  flutter,
  whistle,
  growl,
}

class PlayingTechnique extends MusicalElement {
  final TechniqueType type;
  final String? text;

  PlayingTechnique({required this.type, this.text});
}

// === ORNAMENTOS COMPLETOS ===

enum OrnamentType {
  // Básicos
  trill,
  trillFlat,
  trillNatural,
  trillSharp,
  mordent,
  invertedMordent,
  shortTrill,
  turn,
  turnInverted,
  invertedTurn,
  turnSlash,

  // Apoggiaturas
  appoggiaturaUp,
  appoggiaturaDown,
  acciaccatura,

  // Glissandos
  glissando,
  portamento,
  slide,
  scoop,
  fall,
  doit,
  plop,
  bend,

  // Avançados
  shake,
  wavyLine,
  zigzagLine,
  fermata,
  fermataBelow,
  fermataBelowInverted,
  schleifer,
  mordentUpperPrefix,
  mordentLowerPrefix,
  trillLigature,
  haydn,
  zigZagLineNoRightEnd,
  zigZagLineWithRightEnd,
  arpeggio,
  grace,

  // NOVOS: Ornamentos barrocos e clássicos
  pralltriller,
  mordentWithUpperPrefix,
  slideUp,
  slideDown,
  doubleTongue,
  tripleTongue,
}

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

// === DINÂMICAS COMPLETAS ===

enum DynamicType {
  // Básicas
  pianississimo,
  pianissimo,
  piano,
  mezzoPiano,
  mezzoForte,
  forte,
  fortissimo,
  fortississimo,

  // Extremas
  pppp,
  ppppp,
  pppppp,
  ffff,
  fffff,
  ffffff,

  // Abreviações
  ppp,
  pp,
  p,
  mp,
  mf,
  f,
  ff,
  fff,

  // Especiais
  sforzando,
  sforzandoFF,
  sforzandoPiano,
  sforzandoPianissimo,
  rinforzando,
  fortePiano,
  crescendo,
  diminuendo,
  niente,

  // NOVOS: Dinâmicas especiais
  subito,
  possibile,
  menoMosso,
  piuMosso,
  custom,
}

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

// === REPETIÇÕES COMPLETAS ===

enum RepeatType {
  start,
  end,
  segno,
  coda,
  dalSegno,
  dalSegnoAlCoda,
  dalSegnoAlFine,
  daCapo,
  daCapoAlCoda,
  daCapoAlFine,
  fine,
  toCoda,
  segnoSquare,
  codaSquare,
  repeat1Bar,
  repeat2Bars,
  repeat4Bars,
  simile,
  percentRepeat,
  // NOVOS
  repeatDots,
  repeatLeft,
  repeatRight,
  repeatBoth,
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
  // NOVOS
  dedication,
  rights,
  partName,
  instrument,
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
  // NOVOS
  chokeSymbol,
  damp,
  dampAll,
  openRim,
  closedRim,
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

// === BARRAS DE COMPASSO COMPLETAS ===

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
  // NOVOS
  heavy,
  heavyHeavy,
  none,
}

class AdvancedBarline extends MusicalElement {
  final BarlineType type;
  final RepeatMark? repeatMark;
  final String? rehearsalLetter;

  AdvancedBarline({required this.type, this.repeatMark, this.rehearsalLetter});
}

// === LINHAS DE PROLONGAMENTO ===

enum LineType {
  solid,
  dashed,
  dotted,
  wavy,
  zigzag,
  trill,
  glissando,
  octave,
  // NOVOS
  pedal,
  bracket,
  voltaBracket,
}

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

enum BreathType {
  comma,
  tick,
  upbow,
  caesura,
  shortCaesura,
  longCaesura,
  // NOVOS
  chokeCymbal,
}

class Breath extends MusicalElement {
  final BreathType type;

  Breath({required this.type});
}

// === HARMÔNICOS ===

enum HarmonicType {
  natural,
  artificial,
  touched,
  sounding,
  // NOVOS
  stringHarmonic,
  brassHarmonic,
}

class Harmonic extends MusicalElement {
  final HarmonicType type;
  final Pitch? soundingPitch;

  Harmonic({required this.type, this.soundingPitch});
}

// === SINAIS DE OITAVA ===

enum OctaveType {
  octave8va,
  octave8vb,
  octave15ma,
  octave15mb,
  octave22ma,
  octave22mb,
}

class OctaveMark extends MusicalElement {
  final OctaveType type;
  final double? length;
  final bool showBracket;
  final String? text;

  OctaveMark({
    required this.type,
    this.length,
    this.showBracket = true,
    this.text,
  });

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

// === CLUSTERS ===

enum ClusterType { tone, semitone, microtone, white, black }

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

// === METRÔNOMO ===

enum MetronomeMarkType { note, equation, range, approximate }

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

// === CAESURAS ===

enum CaesuraType { short, long, thick, curved, double }

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

// === PEDAL (NOVO) ===

enum PedalType { start, change, end, continuous }

class PedalMark extends MusicalElement {
  final PedalType type;
  final double? length;

  PedalMark({required this.type, this.length});

  String? get glyphName {
    switch (type) {
      case PedalType.start:
        return 'keyboardPedalPed';
      case PedalType.end:
        return 'keyboardPedalUp';
      case PedalType.change:
        return 'keyboardPedalSost';
      case PedalType.continuous:
        return null; // Será uma linha
    }
  }
}

// === ARPEJOS AVANÇADOS (NOVO) ===

enum ArpeggioType { standard, up, down, bracket }

class AdvancedArpeggio extends MusicalElement {
  final ArpeggioType type;
  final double height;

  AdvancedArpeggio({required this.type, required this.height});

  String get glyphName {
    switch (type) {
      case ArpeggioType.standard:
        return 'wiggleArpeggiatoUp';
      case ArpeggioType.up:
        return 'wiggleArpeggiatoUpArrow';
      case ArpeggioType.down:
        return 'wiggleArpeggiatoDownArrow';
      case ArpeggioType.bracket:
        return 'arpeggiato';
    }
  }
}

// === GRACE NOTES (NOVO) ===

class GraceNote extends MusicalElement {
  final Note note;
  final bool isAcciaccatura; // true = com barra, false = sem barra
  final bool slash;

  GraceNote({
    required this.note,
    this.isAcciaccatura = true,
    this.slash = true,
  });
}

// === TREMOLOS (NOVO) ===

enum TremoloType {
  single1, // 1 barra
  single2, // 2 barras
  single3, // 3 barras
  measured, // Tremolo medido
  unmeasured, // Tremolo não medido
  buzz, // Buzz roll (percussão)
}

class TremoloMark extends MusicalElement {
  final TremoloType type;
  final int numberOfMarks;

  TremoloMark({required this.type, this.numberOfMarks = 3});

  String? get glyphName {
    switch (type) {
      case TremoloType.single1:
        return 'tremolo1';
      case TremoloType.single2:
        return 'tremolo2';
      case TremoloType.single3:
        return 'tremolo3';
      case TremoloType.buzz:
        return 'buzzRoll';
      default:
        return 'tremolo3';
    }
  }
}

// === BENDS (NOVO - para guitarra/blues) ===

class BendMark extends MusicalElement {
  final double
  semitones; // Quantidade de bend (0.5 = meio tom, 1.0 = tom inteiro)
  final BendType bendType;
  final bool showArrow;

  BendMark({
    required this.semitones,
    required this.bendType,
    this.showArrow = true,
  });
}

enum BendType { up, down, preBend, release, bendAndRelease }

// === VOLTAGEM (NOVO - colchetes de repetição) ===

class VoltaBracket extends MusicalElement {
  final List<int> numbers; // [1, 2] para "1., 2."
  final double length;
  final String? text;

  VoltaBracket({required this.numbers, required this.length, this.text});

  String get displayText {
    if (text != null) return text!;
    return numbers.map((n) => '$n.').join(', ');
  }
}

// === SÍMBOLOS DE PERCUSSÃO (NOVO) ===

enum PercussionSymbol {
  hiHat,
  hiHatOpen,
  hiHatHalfOpen,
  snare,
  bassDrum,
  tomLow,
  tomMid,
  tomHigh,
  rideCymbal,
  crashCymbal,
  chinaCymbal,
  splashCymbal,
  cowbell,
  woodblock,
  claves,
  tambourine,
  triangle,
  shaker,
  // Técnicas
  rimshot,
  crossStick,
  ghostNote,
  flam,
  drag,
  roll,
}

class PercussionNote extends MusicalElement {
  final PercussionSymbol symbol;
  final Duration duration;
  final List<ArticulationType> articulations;

  PercussionNote({
    required this.symbol,
    required this.duration,
    this.articulations = const [],
  });

  String get glyphName {
    switch (symbol) {
      case PercussionSymbol.hiHat:
        return 'noteheadXBlack';
      case PercussionSymbol.hiHatOpen:
        return 'noteheadCircleX';
      case PercussionSymbol.snare:
        return 'noteheadBlack';
      case PercussionSymbol.bassDrum:
        return 'noteheadBlack';
      case PercussionSymbol.rideCymbal:
        return 'noteheadXBlack';
      case PercussionSymbol.crashCymbal:
        return 'noteheadXBlack';
      case PercussionSymbol.rimshot:
        return 'noteheadCircleX';
      case PercussionSymbol.crossStick:
        return 'noteheadXOrnate';
      case PercussionSymbol.ghostNote:
        return 'noteheadParenthesis';
      default:
        return 'noteheadBlack';
    }
  }
}

// === JAZZ ARTICULATION (NOVO) ===

enum JazzArticulation {
  scoop,
  plop,
  doit,
  fall,
  fallLong,
  doitLong,
  bend,
  flip,
  smear,
}

class JazzArticulationMark extends MusicalElement {
  final JazzArticulation type;

  JazzArticulationMark({required this.type});

  String get glyphName {
    switch (type) {
      case JazzArticulation.scoop:
        return 'brassBendUp';
      case JazzArticulation.plop:
        return 'brassPlop';
      case JazzArticulation.doit:
        return 'brassDoitMedium';
      case JazzArticulation.fall:
        return 'brassFallMedium';
      case JazzArticulation.fallLong:
        return 'brassFallLongRoughEnd';
      case JazzArticulation.doitLong:
        return 'brassDoitLong';
      case JazzArticulation.bend:
        return 'brassBendUp';
      case JazzArticulation.flip:
        return 'brassFlip';
      case JazzArticulation.smear:
        return 'brassSmear';
    }
  }
}

// === MARCAÇÕES DE CORDAS (NOVO - para instrumentos de cordas) ===

enum StringNumber { string1, string2, string3, string4, string5, string6 }

class StringIndicator extends MusicalElement {
  final StringNumber string;
  final bool circled;

  StringIndicator({required this.string, this.circled = true});

  String get displayText {
    final number = string.index + 1;
    return circled ? '⃝$number' : '$number';
  }
}

// === FINGER NUMBERS (NOVO - digitação) ===

enum FingerNumber {
  finger0, // Polegar ou corda solta
  finger1,
  finger2,
  finger3,
  finger4,
  finger5,
}

class Fingering extends MusicalElement {
  final FingerNumber finger;
  final FingeringPosition position;

  Fingering({required this.finger, this.position = FingeringPosition.above});

  String get glyphName {
    switch (finger) {
      case FingerNumber.finger0:
        return 'fingering0';
      case FingerNumber.finger1:
        return 'fingering1';
      case FingerNumber.finger2:
        return 'fingering2';
      case FingerNumber.finger3:
        return 'fingering3';
      case FingerNumber.finger4:
        return 'fingering4';
      case FingerNumber.finger5:
        return 'fingering5';
    }
  }
}

enum FingeringPosition { above, below, left, right }

// === MARCAÇÕES DE POSIÇÃO (NOVO - para cordas) ===

class PositionMark extends MusicalElement {
  final int position; // 1ª posição, 2ª posição, etc.
  final bool romanNumeral;

  PositionMark({required this.position, this.romanNumeral = true});

  String get displayText {
    if (romanNumeral) {
      const romanNumerals = [
        'I',
        'II',
        'III',
        'IV',
        'V',
        'VI',
        'VII',
        'VIII',
        'IX',
        'X',
      ];
      if (position >= 1 && position <= 10) {
        return romanNumerals[position - 1];
      }
    }
    return position.toString();
  }
}

// === ACCORDION REGISTER (NOVO - para acordeão) ===

enum AccordionRegister {
  bassoon,
  clarinet,
  piccolo,
  violin,
  master,
  // Registros de baixo
  bassoonBass,
  counterbass,
}

class AccordionRegisterMark extends MusicalElement {
  final AccordionRegister register;

  AccordionRegisterMark({required this.register});

  String get glyphName {
    switch (register) {
      case AccordionRegister.bassoon:
        return 'accRegisterBassoon';
      case AccordionRegister.clarinet:
        return 'accRegisterClarinet';
      case AccordionRegister.piccolo:
        return 'accRegisterPiccolo';
      case AccordionRegister.violin:
        return 'accRegisterViolin';
      case AccordionRegister.master:
        return 'accRegisterMaster';
      default:
        return 'accRegisterBassoon';
    }
  }
}

// === HARP PEDAL DIAGRAM (NOVO) ===

class HarpPedalDiagram extends MusicalElement {
  final List<HarpPedalPosition> positions; // 7 posições (D, C, B, E, F, G, A)

  HarpPedalDiagram({required this.positions});
}

enum HarpPedalPosition { flat, natural, sharp }

// === FIGURED BASS (NOVO - baixo cifrado barroco) ===

class FiguredBass extends MusicalElement {
  final List<String> figures; // ['6', '4', '#']
  final TextPlacement placement;

  FiguredBass({required this.figures, this.placement = TextPlacement.below});

  String get displayText => figures.join('\n');
}

// === CHORD SYMBOLS (NOVO - cifras de acordes) ===

enum ChordQuality {
  major,
  minor,
  diminished,
  augmented,
  dominant7,
  major7,
  minor7,
  halfDiminished7,
  diminished7,
  suspended2,
  suspended4,
  // Extensões
  add9,
  add11,
  add13,
  major9,
  minor9,
  dominant9,
  major11,
  minor11,
  dominant11,
  major13,
  minor13,
  dominant13,
}

class ChordSymbol extends MusicalElement {
  final String root; // C, D, E, F, G, A, B
  final String? accidental; // #, b, ##, bb
  final ChordQuality quality;
  final String? bass; // Para inversões (ex: C/E)
  final List<String> alterations; // ['+5', 'b9', etc.]

  ChordSymbol({
    required this.root,
    this.accidental,
    required this.quality,
    this.bass,
    this.alterations = const [],
  });

  String get displayText {
    final buffer = StringBuffer(root);
    if (accidental != null) buffer.write(accidental);
    buffer.write(_qualityToString(quality));
    for (final alt in alterations) {
      buffer.write(alt);
    }
    if (bass != null) {
      buffer.write('/$bass');
    }
    return buffer.toString();
  }

  String _qualityToString(ChordQuality quality) {
    switch (quality) {
      case ChordQuality.major:
        return '';
      case ChordQuality.minor:
        return 'm';
      case ChordQuality.diminished:
        return 'dim';
      case ChordQuality.augmented:
        return 'aug';
      case ChordQuality.dominant7:
        return '7';
      case ChordQuality.major7:
        return 'maj7';
      case ChordQuality.minor7:
        return 'm7';
      case ChordQuality.halfDiminished7:
        return 'ø7';
      case ChordQuality.diminished7:
        return 'dim7';
      case ChordQuality.suspended2:
        return 'sus2';
      case ChordQuality.suspended4:
        return 'sus4';
      case ChordQuality.add9:
        return 'add9';
      case ChordQuality.add11:
        return 'add11';
      case ChordQuality.add13:
        return 'add13';
      case ChordQuality.major9:
        return 'maj9';
      case ChordQuality.minor9:
        return 'm9';
      case ChordQuality.dominant9:
        return '9';
      case ChordQuality.major11:
        return 'maj11';
      case ChordQuality.minor11:
        return 'm11';
      case ChordQuality.dominant11:
        return '11';
      case ChordQuality.major13:
        return 'maj13';
      case ChordQuality.minor13:
        return 'm13';
      case ChordQuality.dominant13:
        return '13';
    }
  }
}

// === FRETBOARD DIAGRAM (NOVO - para guitarra) ===

class FretboardDiagram extends MusicalElement {
  final int numberOfStrings;
  final int numberOfFrets;
  final Map<int, int> fingering; // string -> fret (0 = solta, -1 = muda)
  final int? barrePosition; // Traste da pestana
  final String? chordName;

  FretboardDiagram({
    this.numberOfStrings = 6,
    this.numberOfFrets = 5,
    required this.fingering,
    this.barrePosition,
    this.chordName,
  });
}

// === MULTIMEASURE REST (NOVO) ===

class MultiMeasureRest extends MusicalElement {
  final int numberOfMeasures;
  final bool showNumber;

  MultiMeasureRest({required this.numberOfMeasures, this.showNumber = true});

  String get glyphName {
    if (numberOfMeasures == 1) return 'restWhole';
    return 'restMaxima'; // Para múltiplos compassos
  }
}

// === SLASH NOTATION (NOVO - notação rítmica) ===

class SlashNotation extends MusicalElement {
  final Duration duration;
  final bool showStem;
  final int? count; // Para repetições

  SlashNotation({required this.duration, this.showStem = true, this.count});

  String get glyphName => 'noteheadSlashWhite';
}

// === STAFF CHANGE (NOVO - mudança de pauta em piano) ===

enum StaffChangeDirection { upper, lower }

class StaffChange extends MusicalElement {
  final StaffChangeDirection direction;

  StaffChange({required this.direction});
}

// === OTTAVA BRACKET (NOVO - colchete de oitava estendido) ===

class OttavaBracket extends MusicalElement {
  final OctaveType type;
  final double startX;
  final double endX;
  final double y;
  final bool showNumber;
  final bool showBracket;

  OttavaBracket({
    required this.type,
    required this.startX,
    required this.endX,
    required this.y,
    this.showNumber = true,
    this.showBracket = true,
  });
}

// === HAIRPIN (NOVO - crescendo/diminuendo estendido) ===

class HairpinLine extends MusicalElement {
  final bool isCrescendo; // true = crescendo, false = diminuendo
  final double startX;
  final double endX;
  final double y;
  final double height;

  HairpinLine({
    required this.isCrescendo,
    required this.startX,
    required this.endX,
    required this.y,
    this.height = 0.5,
  });
}

// === GLISSANDO LINE (NOVO) ===

class GlissandoLine extends MusicalElement {
  final Offset startPosition;
  final Offset endPosition;
  final bool wavy; // true = ondulado, false = reto
  final bool showText;
  final String? text; // "gliss." ou "port."

  GlissandoLine({
    required this.startPosition,
    required this.endPosition,
    this.wavy = false,
    this.showText = true,
    this.text,
  });
}

// === SCORDATURA (NOVO - afinação não padrão) ===

class ScordaturaMark extends MusicalElement {
  final Map<int, Pitch> tuning; // string number -> pitch
  final bool showClef;

  ScordaturaMark({required this.tuning, this.showClef = true});
}

// === MUTE/UNMUTE (NOVO - para sopros) ===

enum MuteType { straight, cup, harmon, plunger, bucket, practice, open }

class MuteMark extends MusicalElement {
  final MuteType type;
  final bool isActive; // true = colocar surdina, false = tirar surdina

  MuteMark({required this.type, this.isActive = true});

  String? get glyphName {
    if (!isActive) return 'brassMuteOpen';

    switch (type) {
      case MuteType.straight:
        return 'brassmuteOpen'; // Placeholder
      case MuteType.cup:
        return 'brassMuteClosed';
      case MuteType.harmon:
        return 'brassMuteHalfClosed';
      case MuteType.plunger:
        return 'brassMuteClosed';
      case MuteType.open:
        return 'brassMuteOpen';
      default:
        return 'brassMuteClosed';
    }
  }
}

// === SNAP PIZZICATO (NOVO - bartók pizzicato) ===

class SnapPizzicatoMark extends MusicalElement {
  final bool above;

  SnapPizzicatoMark({this.above = true});

  String get glyphName =>
      above ? 'pluckedSnapPizzicatoAbove' : 'pluckedSnapPizzicatoBelow';
}

// === TIME SIGNATURE SPECIAL (NOVO - compassos especiais) ===

class SpecialTimeSignature extends MusicalElement {
  final SpecialTimeSigType type;

  SpecialTimeSignature({required this.type});

  String get glyphName {
    switch (type) {
      case SpecialTimeSigType.common:
        return 'timeSigCommon';
      case SpecialTimeSigType.cut:
        return 'timeSigCutCommon';
      case SpecialTimeSigType.plus:
        return 'timeSigPlus';
      case SpecialTimeSigType.bracket:
        return 'timeSigBracketLeft';
    }
  }
}

enum SpecialTimeSigType { common, cut, plus, bracket }

// === CLEF CHANGE (NOVO - mudança de clave no meio do compasso) ===

class ClefChange extends MusicalElement {
  final Clef newClef;
  final bool small; // true = clave pequena (advertência)

  ClefChange({required this.newClef, this.small = false});
}

// === KEY SIGNATURE CHANGE (NOVO) ===

class KeySignatureChange extends MusicalElement {
  final KeySignature newKeySignature;
  final bool showNaturals; // Mostrar bequadros cancelando armadura anterior

  KeySignatureChange({required this.newKeySignature, this.showNaturals = true});
}
