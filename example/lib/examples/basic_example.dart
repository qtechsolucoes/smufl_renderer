// example/lib/examples/basic_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class BasicExample extends StatelessWidget {
  const BasicExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Partitura básica com elementos essenciais
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(1)); // Sol maior
    measure1.add(TimeSignature(numerator: 4, denominator: 4));
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));
    measure1.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));
    measure1.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));
    measure1.add(Note(
      pitch: const Pitch(step: 'C', octave: 5),
      duration: const Duration(DurationType.quarter),
    ));

    final measure2 = Measure();
    measure2.add(Note(
      pitch: const Pitch(step: 'D', octave: 5),
      duration: const Duration(DurationType.half),
    ));
    measure2.add(Rest(duration: const Duration(DurationType.quarter)));
    measure2.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    staff.add(measure1);
    staff.add(measure2);

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
                    'Exemplo Básico',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Uma partitura simples para demonstrar os elementos fundamentais:\\n'
                    '• Clave de Sol\\n'
                    '• Armadura de Clave (Sol Maior)\\n'
                    '• Fórmula de Compasso (4/4)\\n'
                    '• Notas com diferentes alturas e durações\\n'
                    '• Pausas\\n'
                    '• Articulações (Staccato)',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // AQUI ESTÁ A CORREÇÃO:
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
                  height: 150, // Altura mais compacta para a partitura
                  child: MusicScore(
                    staff: staff,
                    staffSpace: 12.0, // Tamanho mais apropriado
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
