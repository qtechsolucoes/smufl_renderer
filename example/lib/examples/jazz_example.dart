// example/lib/examples/jazz_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class JazzExample extends StatelessWidget {
  const JazzExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo de jazz com acordes complexos e ornamentação
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(2)); // Ré maior
    measure1.add(TimeSignature(numerator: 4, denominator: 4));

    // Marcação de tempo jazz
    measure1.add(TempoMark(
      text: 'Swing ♪ = ♪♪',
      beatUnit: DurationType.eighth,
      bpm: 120,
    ));

    // Acorde de Dmaj7 com ornamentação
    measure1.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'D', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'F',
            octave: 4,
            accidentalType: AccidentalType.sharp,
          ),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'A', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'C',
            octave: 5,
            accidentalType: AccidentalType.sharp,
          ),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
      dynamic: Dynamic(type: DynamicType.mezzoForte),
    ));

    // Linha melódica com blue notes
    measure1.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.eighth),
      ornaments: [
        Ornament(type: OrnamentType.shortTrill, above: true),
      ],
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'G',
        octave: 4,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.eighth),
      articulations: [ArticulationType.staccato],
    ));

    // Bend (blue note)
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'F',
        octave: 4,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.quarter),
      techniques: [
        PlayingTechnique(type: TechniqueType.glissando),
      ],
      ornaments: [
        Ornament(type: OrnamentType.mordent, above: true),
      ],
    ));

    final measure2 = Measure();

    // Acorde de G7 (dominante)
    measure2.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'G', octave: 3),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'B', octave: 3),
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
      ],
      duration: const Duration(DurationType.quarter),
      dynamic: Dynamic(type: DynamicType.forte),
    ));

    // Escala cromática descendente (jazz run)
    final jazzRunNotes = [
      Note(
        pitch: const Pitch(step: 'D', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: Pitch.withAccidental(
          step: 'C',
          octave: 5,
          accidentalType: AccidentalType.sharp,
        ),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: Pitch.withAccidental(
          step: 'B',
          octave: 4,
          accidentalType: AccidentalType.flat,
        ),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.sixteenth),
      ),
    ];

    measure2.add(Tuplet(
      actualNotes: 6,
      normalNotes: 4,
      elements: jazzRunNotes,
      showBracket: false,
      showNumber: false,
    ));

    // Nota longa com vibrato
    measure2.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.quarter),
      ornaments: [
        Ornament(type: OrnamentType.wavyLine, above: true),
      ],
      articulations: [ArticulationType.tenuto],
    ));

    final measure3 = Measure();

    // Acorde de Em7b5 (subdominante menor)
    measure3.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'E', octave: 4),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: const Pitch(step: 'G', octave: 4),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 4,
            accidentalType: AccidentalType.flat,
          ),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: const Pitch(step: 'D', octave: 5),
          duration: const Duration(DurationType.half),
        ),
      ],
      duration: const Duration(DurationType.half),
      dynamic: Dynamic(type: DynamicType.mezzoPiano),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
    ));

    // Final com diminuendo
    measure3.add(Dynamic(
      type: DynamicType.diminuendo,
      isHairpin: true,
      length: 60.0,
    ));

    // Respiração de frase jazz
    measure3.add(Breath(type: BreathType.comma));

    // Resolução final em Dmaj7
    measure3.add(Note(
      pitch: const Pitch(step: 'D', octave: 4),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.pianissimo),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
    ));

    staff.add(measure1);
    staff.add(measure2);
    staff.add(measure3);

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
                    'Exemplo de Jazz',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Música jazz com harmonias complexas:\\n'
                    '• Marcação de tempo swing\\n'
                    '• Acordes extensos (Dmaj7, G7, Em7b5)\\n'
                    '• Blue notes e cromatismos\\n'
                    '• Jazz runs (escalas cromáticas)\\n'
                    '• Ornamentação característica (trills, mordents)\\n'
                    '• Técnicas de expressão (glissando, vibrato)\\n'
                    '• Respirações de frase\\n'
                    '• Dinâmicas expressivas com hairpins',
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
                  height: 300,
                  child: MusicScore(
                    staff: staff,
                    theme: MusicScoreTheme.elegant(),
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