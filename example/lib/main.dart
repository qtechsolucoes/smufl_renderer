// example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo para testar Ligaduras de Valor (Ties).
    final staff = Staff();

    // --- Compasso 1: Prepara e inicia a ligadura ---
    final measure1 = Measure();
    measure1.add(Clef());
    measure1.add(KeySignature(0));
    measure1.add(TimeSignature(numerator: 4, denominator: 4));
    measure1.add(
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
    );
    measure1.add(
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
    );
    measure1.add(
      Note(
        pitch: const Pitch(step: 'C', octave: 5), // Esta nota...
        duration: const Duration(DurationType.half),
        tie: TieType.start, // ...inicia a ligadura.
      ),
    );

    // --- Compasso 2: Conclui a ligadura e continua a música ---
    final measure2 = Measure();
    measure2.add(
      Note(
        pitch: const Pitch(step: 'C', octave: 5), // ...é ligada a esta nota.
        duration: const Duration(DurationType.quarter),
        tie: TieType.end, // ...que termina a ligadura.
      ),
    );
    measure2.add(
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
    );
    measure2.add(Rest(duration: const Duration(DurationType.half)));

    staff.add(measure1);
    staff.add(measure2);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SMuFL Renderer - Ligaduras')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MusicScore(staff: staff),
          ),
        ),
      ),
    );
  }
}
