// example/lib/examples/advanced_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class AdvancedExample extends StatelessWidget {
  const AdvancedExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo avançado: música com acidentes, ornamentos e dinâmicas
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(2)); // Ré maior (2 sustenidos)
    measure1.add(TimeSignature(numerator: 3, denominator: 4));

    // Nota com trinado
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'F',
        octave: 4,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.quarter),
      ornaments: [Ornament(type: OrnamentType.trill, above: true)],
      dynamicElement: Dynamic(type: DynamicType.forte),
    ));

    // Nota com mordente
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.quarter),
      ornaments: [Ornament(type: OrnamentType.mordent, above: true)],
      articulations: [ArticulationType.staccato],
    ));

    // Nota com grupeto
    measure1.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.quarter),
      ornaments: [Ornament(type: OrnamentType.turn, above: true)],
      articulations: [ArticulationType.accent],
    ));

    final measure2 = Measure();

    // Acorde com dinâmica
    measure2.add(Chord(
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
      ],
      duration: const Duration(DurationType.quarter),
      dynamic: Dynamic(type: DynamicType.pianissimo),
    ));

    // Nota com microtom
    measure2.add(Note(
      pitch: Pitch.withAccidental(
        step: 'B',
        octave: 4,
        accidentalType: AccidentalType.quarterToneSharp,
      ),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.tenuto],
    ));

    // Pausa com fermata
    measure2.add(Rest(
      duration: const Duration(DurationType.quarter),
      ornaments: [Ornament(type: OrnamentType.fermata, above: true)],
    ));

    final measure3 = Measure();

    // Quiáltera (3:2)
    final tupletNotes = [
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.eighth),
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),
    ];

    measure3.add(Tuplet(
      actualNotes: 3,
      normalNotes: 2,
      elements: tupletNotes,
    ));

    // Crescendo
    measure3.add(Dynamic(
      type: DynamicType.crescendo,
      isHairpin: true,
      length: 60.0,
    ));

    // Nota final com sforzando
    measure3.add(Note(
      pitch: const Pitch(step: 'D', octave: 5),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.sforzando),
      articulations: [ArticulationType.accent],
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
                    'Exemplo Avançado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elementos avançados de notação musical:\n'
                    '• Armadura de clave (Ré maior)\n'
                    '• Ornamentos (trinado, mordente, grupeto, fermata)\n'
                    '• Acidentes (sustenido, quarto de tom)\n'
                    '• Articulações (staccato, accent, tenuto)\n'
                    '• Dinâmicas (forte, pianíssimo, sforzando, crescendo)\n'
                    '• Acordes\n'
                    '• Quiálteras (3:2)',
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
                    theme: MusicScoreTheme.colorful(),
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