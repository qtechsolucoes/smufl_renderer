// example/lib/examples/percussion_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class PercussionExample extends StatelessWidget {
  const PercussionExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo de percussão com diferentes elementos
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'percussion'));
    measure1.add(TimeSignature(numerator: 4, denominator: 4));

    // Padrão de bateria básico
    measure1.add(Note(
      pitch: const Pitch(step: 'F', octave: 4), // Bumbo
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
      dynamicElement: Dynamic(type: DynamicType.forte),
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'A', octave: 4), // Caixa
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'F', octave: 4), // Bumbo
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'A', octave: 4), // Caixa
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    final measure2 = Measure();

    // Padrão com semicolcheias
    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
    ));

    measure2.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.eighth),
    ));

    measure2.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.eighth),
      articulations: [ArticulationType.accent],
    ));

    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.sixteenth),
    ));

    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.sixteenth),
    ));

    measure2.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
    ));

    final measure3 = Measure();

    // Fill de bateria
    measure3.add(Note(
      pitch: const Pitch(step: 'D', octave: 5), // Tom agudo
      duration: const Duration(DurationType.sixteenth),
      articulations: [ArticulationType.accent],
    ));

    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 5), // Tom médio
      duration: const Duration(DurationType.sixteenth),
    ));

    measure3.add(Note(
      pitch: const Pitch(step: 'A', octave: 4), // Caixa
      duration: const Duration(DurationType.sixteenth),
      articulations: [ArticulationType.staccato],
    ));

    measure3.add(Note(
      pitch: const Pitch(step: 'G', octave: 4), // Tom grave
      duration: const Duration(DurationType.sixteenth),
    ));

    // Acorde final (crash + bumbo)
    measure3.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'F', octave: 4), // Bumbo
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: const Pitch(step: 'G', octave: 5), // Crash
          duration: const Duration(DurationType.half),
        ),
      ],
      duration: const Duration(DurationType.half),
      dynamic: Dynamic(type: DynamicType.fortississimo),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
    ));

    // Pausa final
    measure3.add(Rest(duration: const Duration(DurationType.quarter)));

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
                    'Exemplo de Percussão',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Padrão de bateria com diferentes elementos:\\n'
                    '• Clave de percussão\\n'
                    '• Padrão básico de rock (bumbo + caixa)\\n'
                    '• Variações rítmicas com semicolcheias\\n'
                    '• Fill de bateria com tom-tons\\n'
                    '• Articulações (acentos, staccato)\\n'
                    '• Dinâmicas de percussão (f, fff)\\n'
                    '• Acorde final com crash e fermata',
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