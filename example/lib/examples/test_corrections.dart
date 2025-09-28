// example/test_corrections.dart
// Arquivo de teste para verificar as correções do staff_renderer.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste de Correções SMuFL',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Correções SMuFL'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestCard(
              'Teste 1: Claves',
              'Verifica posicionamento correto das claves',
              _createClefTest(),
            ),
            const SizedBox(height: 16),
            _buildTestCard(
              'Teste 2: Hastes e Articulações',
              'Verifica independência entre hastes e articulações',
              _createStemTest(),
            ),
            const SizedBox(height: 16),
            _buildTestCard(
              'Teste 3: Beams',
              'Verifica agrupamento de colcheias',
              _createBeamTest(),
            ),
            const SizedBox(height: 16),
            _buildTestCard(
              'Teste 4: Acordes',
              'Verifica posicionamento de acordes com segundas',
              _createChordTest(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(String title, String description, Staff staff) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: MusicScore(
                staff: staff,
                theme: const MusicScoreTheme(),
                staffSpace: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === TESTES ESPECÍFICOS ===

  static Staff _createClefTest() {
    final staff = Staff();

    // Teste com clave de Sol
    final measure1 = Measure();
    measure1.add(Clef(clefType: ClefType.treble));
    measure1.add(TimeSignature(numerator: 4, denominator: 4));

    // G4 - deve ficar exatamente na 2ª linha
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    // B4 - linha central
    measure1.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    // Teste com clave de Fá
    final measure2 = Measure();
    measure2.add(Clef(clefType: ClefType.bass));

    // F3 - deve ficar exatamente na 4ª linha
    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 3),
      duration: const Duration(DurationType.quarter),
    ));

    // D3 - linha central
    measure2.add(Note(
      pitch: const Pitch(step: 'D', octave: 3),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure1);
    staff.add(measure2);

    return staff;
  }

  static Staff _createStemTest() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Nota grave - haste para cima, articulação embaixo
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.staccato],
    ));

    // Nota aguda - haste para baixo, articulação em cima
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 6),
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.accent],
    ));

    // Nota na linha central - teste de estabilidade
    measure.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.tenuto],
    ));

    // Colcheia com bandeirola para cima
    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 4),
      duration: const Duration(DurationType.eighth),
    ));

    // Semicolcheia com bandeirola para baixo
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 5),
      duration: const Duration(DurationType.sixteenth),
    ));

    // Pausa
    measure.add(Rest(
      duration: const Duration(DurationType.eighth),
    ));

    staff.add(measure);
    return staff;
  }

  static Staff _createBeamTest() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Grupo de colcheias ascendente
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 5),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.start,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 5),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.inner,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 5),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.inner,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 5),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.end,
    ));

    // Grupo de semicolcheias descendente
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.start,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.inner,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.inner,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.end,
    ));

    staff.add(measure);
    return staff;
  }

  static Staff _createChordTest() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Acorde C maior (sem segundas)
    measure.add(Chord(
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
    ));

    // Cluster com segundas adjacentes
    measure.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 5),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'D', octave: 5),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'E', octave: 5),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
    ));

    // Acorde com segundas e articulações
    measure.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'F', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'G', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'A', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: const Pitch(step: 'B', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.accent],
    ));

    // Pausa para finalizar
    measure.add(Rest(
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);
    return staff;
  }
}
