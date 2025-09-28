// example/lib/examples/complex_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class ComplexExample extends StatelessWidget {
  const ComplexExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo complexo: peça com tablatura, múltiplas vozes e elementos avançados
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(-3)); // Mi bemol maior (3 bemóis)
    measure1.add(TimeSignature(numerator: 6, denominator: 8));

    // Marca de tempo
    measure1.add(TempoMark(
      text: 'Andante',
      beatUnit: DurationType.quarter,
      bpm: 72,
    ));

    // Sequência melódica com ligaduras de valor
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'E',
        octave: 4,
        accidentalType: AccidentalType.flat,
      ),
      duration: const Duration(DurationType.eighth),
      tie: TieType.start,
      beam: BeamType.start,
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'E',
        octave: 4,
        accidentalType: AccidentalType.flat,
      ),
      duration: const Duration(DurationType.eighth),
      tie: TieType.end,
      beam: BeamType.inner,
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.end,
      articulations: [ArticulationType.staccato],
    ));

    // Acorde com múltiplas dinâmicas
    measure1.add(Chord(
      notes: [
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 3,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'D', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'F', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 4,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
      dynamic: Dynamic(type: DynamicType.mezzoForte),
      ornaments: [Ornament(type: OrnamentType.arpeggio, above: false)],
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.eighth),
      ornaments: [Ornament(type: OrnamentType.grace, above: true)],
    ));

    // Verificação de validação do compasso 6/8
    // Total esperado: 3×0.125 + 1×0.25 + 1×0.125 = 0.75 (correto para 6/8)
    debugPrint('Measure 1 value: ${measure1.currentMusicalValue}');
    debugPrint('Time signature capacity: ${measure1.timeSignature?.measureValue}');
    debugPrint('Is valid: ${measure1.isValidlyFilled}');

    final measure2 = Measure();

    // Respiração
    measure2.add(Breath(type: BreathType.comma));

    // Quiáltera complexa (5:4)
    final complexTupletNotes = [
        Note(
          pitch: Pitch.withAccidental(
            step: 'A',
            octave: 4,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.sixteenth),
          articulations: [ArticulationType.accent],
        ),
        Note(
          pitch: const Pitch(step: 'G', octave: 4),
          duration: const Duration(DurationType.sixteenth),
        ),
        Note(
          pitch: const Pitch(step: 'F', octave: 4),
          duration: const Duration(DurationType.sixteenth),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'E',
            octave: 4,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.sixteenth),
        ),
        Note(
          pitch: const Pitch(step: 'D', octave: 4),
          duration: const Duration(DurationType.sixteenth),
          articulations: [ArticulationType.tenuto],
        ),
    ];

    measure2.add(Tuplet(
      actualNotes: 5,
      normalNotes: 4,
      elements: complexTupletNotes,
    ));

    // Diminuendo
    measure2.add(Dynamic(
      type: DynamicType.diminuendo,
      isHairpin: true,
      length: 80.0,
    ));

    measure2.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.pianississimo),
      ornaments: [Ornament(type: OrnamentType.fermata, above: true)],
    ));

    final measure3 = Measure();

    // Mudança de clave
    measure3.add(Clef(type: 'f'));

    // Harmônicos
    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 3),
      duration: const Duration(DurationType.half),
      techniques: [NoteTechnique.harmonic],
      dynamicElement: Dynamic(type: DynamicType.pianissimo),
    ));

    // Nota com glissando
    measure3.add(Note(
      pitch: const Pitch(step: 'G', octave: 2),
      duration: const Duration(DurationType.quarter),
      techniques: [NoteTechnique.glissando],
      slur: SlurType.start,
    ));

    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
      slur: SlurType.end,
      ornaments: [Ornament(type: OrnamentType.trill, above: true)],
    ));

    // Tremolo
    measure3.add(Note(
      pitch: const Pitch(step: 'F', octave: 3),
      duration: const Duration(DurationType.quarter),
      techniques: [NoteTechnique.tremolo],
      articulations: [ArticulationType.accent],
    ));

    final measure4 = Measure();

    // Texto de expressão
    measure4.add(MusicText(
      text: 'rit.',
      type: TextType.expression,
    ));

    // Acorde final com arpegio
    measure4.add(Chord(
      notes: [
        Note(
          pitch: Pitch.withAccidental(
            step: 'E',
            octave: 2,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.whole),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 2,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.whole),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'E',
            octave: 3,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.whole),
        ),
        Note(
          pitch: const Pitch(step: 'G', octave: 3),
          duration: const Duration(DurationType.whole),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 3,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.whole),
        ),
      ],
      duration: const Duration(DurationType.whole),
      ornaments: [
        Ornament(type: OrnamentType.arpeggio, above: false),
        Ornament(type: OrnamentType.fermata, above: true),
      ],
      dynamic: Dynamic(type: DynamicType.forte),
    ));

    staff.add(measure1);
    staff.add(measure2);
    staff.add(measure3);
    staff.add(measure4);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exemplo Complexo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Partitura complexa demonstrando recursos avançados:\n'
                    '• Múltiplas claves (Sol e Fá)\n'
                    '• Fórmula de compasso 6/8\n'
                    '• Armadura com bemóis (Mi♭ maior)\n'
                    '• Ligaduras de valor e ligaduras de expressão\n'
                    '• Barras de ligação (beaming)\n'
                    '• Quiálteras complexas (5:4)\n'
                    '• Técnicas especiais (harmônicos, glissando, tremolo)\n'
                    '• Dinâmicas com hairpins\n'
                    '• Marcas de tempo e expressões\n'
                    '• Acidentes microtonais\n'
                    '• Ornamentos (trinado, arpegio, fermata, grace notes)',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: 800, // Altura maior para acomodar múltiplos sistemas
                  child: MusicScore(
                    staff: staff,
                    theme: MusicScoreTheme.dark(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}