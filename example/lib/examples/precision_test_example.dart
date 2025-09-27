// example/lib/examples/precision_test_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo específico para testar a precisão do posicionamento musical
/// Baseado nos valores oficiais do metadata do Bravura
class PrecisionTestExample extends StatelessWidget {
  const PrecisionTestExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Precisão - Bravura SMuFL'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TestHeader(),
            SizedBox(height: 20),
            _ClefPositioningTest(),
            SizedBox(height: 30),
            _NotePositioningTest(),
            SizedBox(height: 30),
            _AccidentalTest(),
            SizedBox(height: 30),
            _ChordTest(),
            SizedBox(height: 30),
            _ComplexScoreTest(),
          ],
        ),
      ),
    );
  }
}

class _TestHeader extends StatelessWidget {
  const _TestHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Testes de Precisão Musical',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Validação do posicionamento correto baseado no metadata oficial '
              'do Bravura SMuFL. Todos os elementos devem estar alinhados '
              'perfeitamente usando os valores oficiais de bounding boxes.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ClefPositioningTest extends StatelessWidget {
  const _ClefPositioningTest();

  @override
  Widget build(BuildContext context) {
    // Teste das três claves principais com posicionamento correto
    final staff = Staff();

    // Primeiro compasso - Clave de sol
    final measure1 = Measure();
    measure1.add(Clef(type: 'g')); // Clave de sol na 2ª linha
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4), // G4 na 2ª linha
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure1);

    // Segundo compasso - Clave de fá
    final measure2 = Measure();
    measure2.add(Clef(type: 'f')); // Clave de fá na 4ª linha
    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 3), // F3 na 4ª linha
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure2);

    // Terceiro compasso - Clave de dó
    final measure3 = Measure();
    measure3.add(Clef(type: 'c')); // Clave de dó na 3ª linha
    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // C4 na 3ª linha
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure3);

    return _TestSection(
      title: '1. Teste de Posicionamento de Claves',
      description: 'As claves devem estar perfeitamente alinhadas com suas linhas de referência.',
      staff: staff,
    );
  }
}

class _NotePositioningTest extends StatelessWidget {
  const _NotePositioningTest();

  @override
  Widget build(BuildContext context) {
    // Teste de notas em diferentes posições com hastes corretas
    final staff = Staff();

    // Primeiro compasso
    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(Note(
      pitch: const Pitch(step: 'C', octave: 5), // C5 - haste para baixo
      duration: const Duration(DurationType.quarter),
    ));
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4), // G4 - haste para cima
      duration: const Duration(DurationType.quarter),
    ));
    measure1.add(Note(
      pitch: const Pitch(step: 'D', octave: 4), // D4 - haste para cima
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure1);

    // Segundo compasso - Teste de linhas suplementares
    final measure2 = Measure();
    measure2.add(Note(
      pitch: const Pitch(step: 'A', octave: 5), // A5 - linha suplementar superior
      duration: const Duration(DurationType.quarter),
    ));
    measure2.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // C4 - linha suplementar inferior
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure2);

    return _TestSection(
      title: '2. Teste de Posicionamento de Notas e Hastes',
      description: 'Hastes devem estar na posição correta baseada no bounding box oficial.',
      staff: staff,
    );
  }
}

class _AccidentalTest extends StatelessWidget {
  const _AccidentalTest();

  @override
  Widget build(BuildContext context) {
    // Teste de acidentes com espaçamento correto
    final staff = Staff();

    // Primeiro compasso
    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(2)); // 2 sustenidos
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'F',
        octave: 4,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.quarter),
    ));
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'B',
        octave: 4,
        accidentalType: AccidentalType.flat,
      ),
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure1);

    // Segundo compasso
    final measure2 = Measure();
    measure2.add(KeySignature(-3)); // 3 bemóis
    measure2.add(Note(
      pitch: Pitch.withAccidental(
        step: 'E',
        octave: 4,
        accidentalType: AccidentalType.natural,
      ),
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure2);

    return _TestSection(
      title: '3. Teste de Acidentes e Armaduras',
      description: 'Acidentes devem usar as larguras oficiais do metadata Bravura.',
      staff: staff,
    );
  }
}

class _ChordTest extends StatelessWidget {
  const _ChordTest();

  @override
  Widget build(BuildContext context) {
    // Teste de acordes com notas adjacentes
    final staff = Staff();

    final measure = Measure();
    measure.add(Clef(type: 'g'));

    // Acorde com intervalo de segunda (notas adjacentes)
    final chord1 = Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'D', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
    );
    measure.add(chord1);

    // Acorde com intervalo maior
    final chord2 = Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'E', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'G', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
    );
    measure.add(chord2);

    staff.add(measure);

    return _TestSection(
      title: '4. Teste de Acordes',
      description: 'Notas adjacentes devem ter offset horizontal para evitar sobreposição.',
      staff: staff,
    );
  }
}

class _ComplexScoreTest extends StatelessWidget {
  const _ComplexScoreTest();

  @override
  Widget build(BuildContext context) {
    // Teste complexo com vários elementos
    final staff = Staff();

    // Primeiro compasso
    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(1)); // 1 sustenido
    measure1.add(TimeSignature(numerator: 4, denominator: 4));
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.staccato],
    ));
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'A',
        octave: 4,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.eighth),
    ));
    measure1.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.eighth),
    ));
    staff.add(measure1);

    // Segundo compasso
    final measure2 = Measure();
    measure2.add(Rest(duration: const Duration(DurationType.quarter)));

    final chord = Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 5),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: const Pitch(step: 'E', octave: 5),
          duration: const Duration(DurationType.half),
        ),
      ],
      duration: const Duration(DurationType.half),
    );
    measure2.add(chord);

    measure2.add(Note(
      pitch: const Pitch(step: 'D', octave: 5),
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.accent],
    ));
    staff.add(measure2);

    return _TestSection(
      title: '5. Teste Complexo Completo',
      description: 'Combinação de todos os elementos com espaçamento e posicionamento precisos.',
      staff: staff,
    );
  }
}

class _TestSection extends StatelessWidget {
  final String title;
  final String description;
  final Staff staff;

  const _TestSection({
    required this.title,
    required this.description,
    required this.staff,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: MusicScore(
                staff: staff,
                theme: MusicScoreTheme(
                  // Tema otimizado para teste de precisão
                  staffLineColor: Colors.black,
                  clefColor: Colors.blue.shade800,
                  noteheadColor: Colors.black,
                  stemColor: Colors.black,
                  keySignatureColor: Colors.purple.shade700,
                  timeSignatureColor: Colors.green.shade700,
                  accidentalColor: Colors.red.shade700,
                  articulationColor: Colors.orange.shade700,
                  restColor: Colors.grey.shade600,
                  barlineColor: Colors.black,
                  showLedgerLines: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}