// example/lib/examples/beams_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Um widget de página que demonstra a renderização de barras de ligação (beams).
class BeamsExample extends StatelessWidget {
  const BeamsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Grupo de Colcheias (Eighth notes)
    final List<MusicalElement> eighthNoteBeams = [
      Clef(clefType: ClefType.treble),
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.end,
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.end,
      ),
    ];

    // Grupo de Semicolcheias (Sixteenth notes)
    final List<MusicalElement> sixteenthNoteBeams = [
      Clef(clefType: ClefType.treble),
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 5),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.end,
      ),
    ];

    // Grupo Misto
    final List<MusicalElement> mixedBeams = [
      Clef(clefType: ClefType.treble),
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.end,
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Família de Símbolos: Barras de Ligação'),
        backgroundColor: Colors.brown.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Barras de Ligação Simples (Colcheias)',
              description:
                  'Grupos de colcheias ligadas por uma única barra. Verifique a inclinação e a espessura da barra.',
              elements: eighthNoteBeams,
            ),
            _buildSection(
              title: 'Barras de Ligação Duplas (Semicolcheias)',
              description:
                  'Grupo de semicolcheias ligadas por duas barras. Atualmente, o renderer pode mostrar apenas uma barra; a implementação de barras múltiplas é um próximo passo.',
              elements: sixteenthNoteBeams,
            ),
            _buildSection(
              title: 'Grupos Mistos',
              description:
                  'Um grupo misto de colcheias e semicolcheias. A renderização correta de barras secundárias para as semicolcheias é uma funcionalidade avançada.',
              elements: mixedBeams,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma seção de teste.
  Widget _buildSection({
    required String title,
    required String description,
    required List<MusicalElement> elements,
  }) {
    final staff = Staff();
    final measure = Measure();
    for (final element in elements) {
      measure.add(element);
    }
    staff.add(measure);

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: MusicScore(
                staff: staff,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
