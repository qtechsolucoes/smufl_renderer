// example/lib/examples/microtonal_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class MicrotonalExample extends StatelessWidget {
  const MicrotonalExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo de música microtonal com notação de quartos de tom
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(0)); // Dó maior
    measure1.add(TimeSignature(numerator: 4, denominator: 4));

    // Escala microtonal ascendente
    measure1.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.eighth),
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'C',
        octave: 4,
        accidentalType: AccidentalType.quarterToneSharp,
      ),
      duration: const Duration(DurationType.eighth),
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'D',
        octave: 4,
        accidentalType: AccidentalType.quarterToneFlat,
      ),
      duration: const Duration(DurationType.eighth),
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'D', octave: 4),
      duration: const Duration(DurationType.eighth),
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'E',
        octave: 4,
        accidentalType: AccidentalType.threeQuarterToneFlat,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    final measure2 = Measure();

    // Acorde microtonal
    measure2.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'G', octave: 4),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 4,
            accidentalType: AccidentalType.quarterToneFlat,
          ),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'D',
            octave: 5,
            accidentalType: AccidentalType.quarterToneSharp,
          ),
          duration: const Duration(DurationType.half),
        ),
      ],
      duration: const Duration(DurationType.half),
      dynamic: Dynamic(type: DynamicType.piano),
    ));

    // Ornamento microtonal
    measure2.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.quarter),
      ornaments: [
        Ornament(type: OrnamentType.mordent, above: true),
      ],
    ));

    final measure3 = Measure();

    // Sequência final com saltos microtonais
    measure3.add(Note(
      pitch: Pitch.withAccidental(
        step: 'F',
        octave: 5,
        accidentalType: AccidentalType.threeQuarterToneSharp,
      ),
      duration: const Duration(DurationType.eighth),
    ));

    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.eighth),
    ));

    measure3.add(Rest(duration: const Duration(DurationType.quarter)));

    measure3.add(Note(
      pitch: Pitch.withAccidental(
        step: 'G',
        octave: 3,
        accidentalType: AccidentalType.quarterToneSharp,
      ),
      duration: const Duration(DurationType.half),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
      dynamicElement: Dynamic(type: DynamicType.pianissimo),
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
                    'Exemplo Microtonal',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Música com notação microtonal:\\n'
                    '• Uso de acidentes de quarto de tom (sharp e flat)\\n'
                    '• Acidentes de três quartos de tom\\n'
                    '• Acordes com intervalos microtonais\\n'
                    '• Escalas e melodias que exploram a microtonalidade',
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
