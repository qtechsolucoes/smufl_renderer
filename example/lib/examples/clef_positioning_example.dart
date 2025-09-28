// example/lib/examples/clef_positioning_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo demonstrando o posicionamento correto das claves conforme especificações
class ClefPositioningExample extends StatelessWidget {
  const ClefPositioningExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posicionamento Correto das Claves'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Claves Posicionadas Corretamente',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // CLAVES DE SOL
            _buildSection('Claves de Sol', _createTrebleClefExamples()),

            // CLAVES DE FÁ (3ª e 4ª linha)
            _buildSection('Claves de Fá (3ª e 4ª linha)', _createBassClefExamples()),

            // CLAVES DE DÓ (todas as posições)
            _buildSection('Claves de Dó (1ª a 5ª linha)', _createCClefExamples()),

            // ARTICULAÇÕES POSICIONADAS CORRETAMENTE
            _buildSection('Articulações (Posicionamento baseado na Haste)', _createArticulationExamples()),

            // ORNAMENTOS POSICIONADOS CORRETAMENTE
            _buildSection('Ornamentos (Sempre acima da nota)', _createOrnamentExamples()),

            const SizedBox(height: 30),
            const Text(
              'Especificações Implementadas:\n'
              '✓ Clave de Fá: 3ª linha (Fá) e 4ª linha (posição padrão)\n'
              '✓ Clave de Dó: 1ª linha (soprano), 2ª linha (mezzo-soprano), 3ª linha (alto/viola), 4ª linha (tenor), 5ª linha (barítono)\n'
              '✓ Articulações: posicionamento correto baseado na direção da haste\n'
              '✓ Ornamentos: sempre acima da nota conforme tradição musical\n'
              '✓ Tamanhos e espaçamentos conforme metadata SMuFL',
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
              height: 120,
              child: MusicScore(
                staff: Staff()..add(Measure()..elements.addAll(elements)),
                theme: const MusicScoreTheme(
                  staffLineColor: Colors.black87,
                  noteheadColor: Colors.black,
                  clefColor: Colors.blue,
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

  // === CLAVES DE SOL ===
  List<MusicalElement> _createTrebleClefExamples() {
    return [
      Clef(clefType: ClefType.treble),
      Note(
        pitch: const Pitch(step: 'G', octave: 4), // Sol na 2ª linha
        duration: const Duration(DurationType.whole),
      ),

      Clef(clefType: ClefType.treble8va),
      Note(
        pitch: const Pitch(step: 'G', octave: 5), // 8ª acima
        duration: const Duration(DurationType.whole),
      ),
    ];
  }

  // === CLAVES DE FÁ (3ª e 4ª linha) ===
  List<MusicalElement> _createBassClefExamples() {
    return [
      // Clave de Fá na 4ª linha (padrão)
      Clef(clefType: ClefType.bass),
      Note(
        pitch: const Pitch(step: 'F', octave: 3), // Fá na 4ª linha
        duration: const Duration(DurationType.whole),
      ),

      // Clave de Fá na 3ª linha
      Clef(clefType: ClefType.bassThirdLine),
      Note(
        pitch: const Pitch(step: 'F', octave: 3), // Fá na 3ª linha
        duration: const Duration(DurationType.whole),
      ),
    ];
  }

  // === CLAVES DE DÓ (1ª a 5ª linha) ===
  List<MusicalElement> _createCClefExamples() {
    return [
      // 1ª linha - Soprano
      Clef(clefType: ClefType.soprano),
      Note(
        pitch: const Pitch(step: 'C', octave: 4), // Dó na 1ª linha
        duration: const Duration(DurationType.half),
      ),

      // 2ª linha - Mezzo-soprano
      Clef(clefType: ClefType.mezzoSoprano),
      Note(
        pitch: const Pitch(step: 'C', octave: 4), // Dó na 2ª linha
        duration: const Duration(DurationType.half),
      ),

      // 3ª linha - Alto (viola)
      Clef(clefType: ClefType.alto),
      Note(
        pitch: const Pitch(step: 'C', octave: 4), // Dó na 3ª linha
        duration: const Duration(DurationType.half),
      ),

      // 4ª linha - Tenor
      Clef(clefType: ClefType.tenor),
      Note(
        pitch: const Pitch(step: 'C', octave: 4), // Dó na 4ª linha
        duration: const Duration(DurationType.half),
      ),

      // 5ª linha - Barítono
      Clef(clefType: ClefType.baritone),
      Note(
        pitch: const Pitch(step: 'C', octave: 4), // Dó na 5ª linha
        duration: const Duration(DurationType.half),
      ),
    ];
  }

  // === ARTICULAÇÕES COM POSICIONAMENTO CORRETO ===
  List<MusicalElement> _createArticulationExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Notas agudas (haste para baixo) - articulações ACIMA
      Note(
        pitch: const Pitch(step: 'A', octave: 5),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.staccato],
      ),
      Note(
        pitch: const Pitch(step: 'G', octave: 5),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.accent],
      ),

      // Notas graves (haste para cima) - articulações ABAIXO
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.tenuto],
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.marcato],
      ),

      // Semibreve (sem haste) - articulações ACIMA
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.whole),
        articulations: [ArticulationType.staccatissimo],
      ),
    ];
  }

  // === ORNAMENTOS COM POSICIONAMENTO CORRETO ===
  List<MusicalElement> _createOrnamentExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Ornamentos sempre acima da nota
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        ornaments: [Ornament(type: OrnamentType.trill)],
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
        ornaments: [Ornament(type: OrnamentType.mordent)],
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter),
        ornaments: [Ornament(type: OrnamentType.turn)],
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.quarter),
        ornaments: [Ornament(type: OrnamentType.fermata)],
      ),
    ];
  }
}