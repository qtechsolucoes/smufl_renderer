// example/lib/examples/microtonal_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class MicrotonalExample extends StatelessWidget {
  const MicrotonalExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo avançado: música microtonal com quartos de tom
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(0)); // Dó maior
    measure1.add(TimeSignature(numerator: 4, denominator: 4));

    // Série microtonal com quartos de tom
    measure1.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.mezzoForte),
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'C',
        octave: 4,
        accidentalType: AccidentalType.quarterToneSharp,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'C',
        octave: 4,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'C',
        octave: 4,
        accidentalType: AccidentalType.threeQuarterToneSharp,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    final measure2 = Measure();

    // Série descendente microtonal
    measure2.add(Note(
      pitch: const Pitch(step: 'D', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    measure2.add(Note(
      pitch: Pitch.withAccidental(
        step: 'D',
        octave: 4,
        accidentalType: AccidentalType.quarterToneFlat,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    measure2.add(Note(
      pitch: Pitch.withAccidental(
        step: 'D',
        octave: 4,
        accidentalType: AccidentalType.flat,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    measure2.add(Note(
      pitch: Pitch.withAccidental(
        step: 'D',
        octave: 4,
        accidentalType: AccidentalType.threeQuarterToneFlat,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    final measure3 = Measure();

    // Acorde microtonal
    measure3.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'E', octave: 4),
          duration: const Duration(DurationType.whole),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'G',
            octave: 4,
            accidentalType: AccidentalType.quarterToneSharp,
          ),
          duration: const Duration(DurationType.whole),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'B',
            octave: 4,
            accidentalType: AccidentalType.quarterToneFlat,
          ),
          duration: const Duration(DurationType.whole),
        ),
      ],
      duration: const Duration(DurationType.whole),
      dynamic: Dynamic(type: DynamicType.fortissimo),
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
                    'Exemplo Microtonal',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Música microtonal com quartos de tom:\\n'
                    '• Série ascendente de quartos de tom em Dó\\n'
                    '• Série descendente de quartos de tom em Ré\\n'
                    '• Acorde microtonal com fermata\\n'
                    '• Acidentes microtonais: ♯₄, ♯¾, ♭₄, ♭¾\\n'
                    '• Dinâmicas variadas (mf, ff)',
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
                    theme: MusicScoreTheme.modern(),
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