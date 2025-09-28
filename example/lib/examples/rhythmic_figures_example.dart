// example/lib/examples/rhythmic_figures_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Um widget de página que demonstra a renderização de todas as figuras rítmicas (notas e pausas).
class RhythmicFiguresExample extends StatelessWidget {
  const RhythmicFiguresExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de todas as durações a serem exibidas
    const List<DurationType> allDurations = [
      DurationType.whole,
      DurationType.half,
      DurationType.quarter,
      DurationType.eighth,
      DurationType.sixteenth,
      DurationType.thirtySecond,
      DurationType.sixtyFourth,
    ];

    // Cria os elementos musicais para as notas
    final List<MusicalElement> noteElements = [
      Clef(clefType: ClefType.treble),
      ...allDurations.map((type) {
        return Note(
          pitch: const Pitch(step: 'B', octave: 4),
          duration: Duration(type),
        );
      }),
    ];

    // Cria os elementos musicais para as pausas
    final List<MusicalElement> restElements = [
      Clef(clefType: ClefType.treble),
      ...allDurations.map((type) {
        return Rest(duration: Duration(type));
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Família de Símbolos: Figuras Rítmicas'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Figuras de Notas',
              description:
                  'Exibe todas as durações de notas, da Semibreve (whole) à Semifusa (sixty-fourth). Verifique a aparência da cabeça da nota, haste e bandeirolas.',
              elements: noteElements,
            ),
            _buildSection(
              title: 'Figuras de Pausa',
              description:
                  'Exibe as pausas correspondentes a cada duração. Verifique o design e o alinhamento vertical de cada pausa na pauta.',
              elements: restElements,
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
