// example/lib/examples/beams_and_tuplets_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo dedicado demonstrando beams múltiplos e quiálteras (tercinas, quintinas)
/// com posicionamento correto das articulações e ornamentos
class BeamsAndTupletsExample extends StatelessWidget {
  const BeamsAndTupletsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beams e Quiálteras'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demonstração de Beams Múltiplos e Quiálteras',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 1. BEAMS SIMPLES E MÚLTIPLOS
            _buildSection('1. Colcheias, Semicolcheias, Fusas e Semifusas', _createBeamExamples()),

            // 2. TERCINAS
            _buildSection('2. Tercinas (Triplets)', _createTripletExamples()),

            // 3. QUINTINAS E OUTRAS QUIÁLTERAS
            _buildSection('3. Quintinas e Outras Quiálteras', _createAdvancedTupletExamples()),

            // 4. ARTICULAÇÕES E ORNAMENTOS CORRIGIDOS
            _buildSection('4. Articulações e Ornamentos (Posicionamento Correto)', _createArticulationExamples()),

            // 5. SINAIS DE REPETIÇÃO
            _buildSection('5. Sinais de Repetição', _createRepeatSignsExamples()),

            const SizedBox(height: 30),
            const Text(
              'Funcionalidades Demonstradas:\n'
              '✓ Beams múltiplos (1-4 níveis)\n'
              '✓ Tercinas com agrupamento correto\n'
              '✓ Quintinas e outras quiálteras\n'
              '✓ Articulações centralizadas na cabeça da nota\n'
              '✓ Ornamentos sempre acima e centralizados\n'
              '✓ Posicionamento baseado na direção da haste\n'
              '✓ Sinais de repetição (barras de repetição, símbolos)',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<MusicalElement> elements) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: MusicScore(
                staff: Staff()..add(Measure()..elements.addAll(elements)),
                theme: const MusicScoreTheme(
                  staffLineColor: Colors.black87,
                  noteheadColor: Colors.black,
                  stemColor: Colors.black,
                  articulationColor: Colors.red,
                  ornamentColor: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === 1. BEAMS MÚLTIPLOS ===
  List<MusicalElement> _createBeamExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // 1. Duas colcheias simples
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.start,
        articulations: [ArticulationType.staccato],
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.end,
      ),

      // 2. Quatro semicolcheias (2 beams)
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.inner,
      ),
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.inner,
        articulations: [ArticulationType.accent],
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.end,
      ),

      // 3. Oito fusas (3 beams)
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.thirtySecond),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.thirtySecond),
        beam: BeamType.inner,
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 5),
        duration: const Duration(DurationType.thirtySecond),
        beam: BeamType.inner,
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 5),
        duration: const Duration(DurationType.thirtySecond),
        beam: BeamType.end,
        ornaments: [Ornament(type: OrnamentType.trill)],
      ),

      // 4. Quatro semifusas (4 beams)
      Note(
        pitch: const Pitch(step: 'F', octave: 5),
        duration: const Duration(DurationType.sixtyFourth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'G', octave: 5),
        duration: const Duration(DurationType.sixtyFourth),
        beam: BeamType.inner,
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 5),
        duration: const Duration(DurationType.sixtyFourth),
        beam: BeamType.inner,
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 5),
        duration: const Duration(DurationType.sixtyFourth),
        beam: BeamType.end,
      ),
    ];
  }

  // === 2. TERCINAS ===
  List<MusicalElement> _createTripletExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Tercina de colcheias
      Tuplet(
        actualNotes: 3,
        normalNotes: 2,
        elements: [
          Note(
            pitch: const Pitch(step: 'C', octave: 4),
            duration: const Duration(DurationType.eighth),
            beam: BeamType.start,
            articulations: [ArticulationType.staccato],
          ),
          Note(
            pitch: const Pitch(step: 'E', octave: 4),
            duration: const Duration(DurationType.eighth),
            beam: BeamType.inner,
          ),
          Note(
            pitch: const Pitch(step: 'G', octave: 4),
            duration: const Duration(DurationType.eighth),
            beam: BeamType.end,
            articulations: [ArticulationType.accent],
          ),
        ],
      ),

      // Tercina de semicolcheias
      Tuplet(
        actualNotes: 3,
        normalNotes: 2,
        elements: [
          Note(
            pitch: const Pitch(step: 'A', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.start,
          ),
          Note(
            pitch: const Pitch(step: 'B', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
            ornaments: [Ornament(type: OrnamentType.mordent)],
          ),
          Note(
            pitch: const Pitch(step: 'C', octave: 5),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.end,
          ),
        ],
      ),
    ];
  }

  // === 3. QUINTINAS E OUTRAS QUIÁLTERAS ===
  List<MusicalElement> _createAdvancedTupletExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Quintina (5 notas no tempo de 4)
      Tuplet(
        actualNotes: 5,
        normalNotes: 4,
        elements: [
          Note(
            pitch: const Pitch(step: 'C', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.start,
          ),
          Note(
            pitch: const Pitch(step: 'D', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
          ),
          Note(
            pitch: const Pitch(step: 'E', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
            articulations: [ArticulationType.tenuto],
          ),
          Note(
            pitch: const Pitch(step: 'F', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
          ),
          Note(
            pitch: const Pitch(step: 'G', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.end,
          ),
        ],
      ),

      // Sextina (6 notas no tempo de 4)
      Tuplet(
        actualNotes: 6,
        normalNotes: 4,
        elements: [
          Note(
            pitch: const Pitch(step: 'A', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.start,
          ),
          Note(
            pitch: const Pitch(step: 'B', octave: 4),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
          ),
          Note(
            pitch: const Pitch(step: 'C', octave: 5),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
          ),
          Note(
            pitch: const Pitch(step: 'D', octave: 5),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
            ornaments: [Ornament(type: OrnamentType.turn)],
          ),
          Note(
            pitch: const Pitch(step: 'E', octave: 5),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.inner,
          ),
          Note(
            pitch: const Pitch(step: 'F', octave: 5),
            duration: const Duration(DurationType.sixteenth),
            beam: BeamType.end,
          ),
        ],
      ),
    ];
  }

  // === 4. ARTICULAÇÕES E ORNAMENTOS CORRIGIDOS ===
  List<MusicalElement> _createArticulationExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Notas graves (haste para cima) - articulações abaixo
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.staccato],
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.accent],
      ),

      // Notas agudas (haste para baixo) - articulações acima
      Note(
        pitch: const Pitch(step: 'A', octave: 5),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.tenuto],
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 5),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.marcato],
      ),

      // Semibreve com ornamento sempre acima
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.whole),
        ornaments: [Ornament(type: OrnamentType.fermata)],
        articulations: [ArticulationType.staccatissimo],
      ),
    ];
  }

  // === 5. SINAIS DE REPETIÇÃO ===
  List<MusicalElement> _createRepeatSignsExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Início de repetição
      AdvancedBarline(type: BarlineType.repeatStart),

      // Algumas notas
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
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.quarter),
      ),

      // Fim de repetição
      AdvancedBarline(type: BarlineType.repeatEnd),

      // Marca de repetição de compasso
      RepeatMark(type: RepeatType.repeat1Bar),

      // Mais algumas notas
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.half),
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.half),
      ),

      // Repetição de 2 compassos
      RepeatMark(type: RepeatType.repeat2Bars),
    ];
  }
}