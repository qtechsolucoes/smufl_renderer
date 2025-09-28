// example/lib/examples/comprehensive_symbols_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo demonstrando todos os símbolos musicais implementados
/// seguindo as especificações SMuFL e teoria musical
class ComprehensiveSymbolsExample extends StatelessWidget {
  const ComprehensiveSymbolsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Símbolos Musicais Completos - SMuFL'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demonstração Completa dos Símbolos Musicais',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 1. CLAVES COMPLETAS
            _buildSection(
                '1. Claves (Treble, Bass, Alto, Tenor, Percussão, Tablatura)',
                _createClefExamples()),

            // 2. ACIDENTES AVANÇADOS
            _buildSection('2. Acidentes (Básicos, Microtonais, Sagittais)',
                _createAccidentalExamples()),

            // 3. ARTICULAÇÕES
            _buildSection(
                '3. Articulações (Staccato, Tenuto, Acentos, Técnicas)',
                _createArticulationExamples()),

            // 4. ORNAMENTOS
            _buildSection(
                '4. Ornamentos (Trilos, Mordentes, Grupetos, Apoggiaturas)',
                _createOrnamentExamples()),

            // 5. DINÂMICAS
            _buildSection('5. Dinâmicas (Piano-Forte, Crescendo-Diminuendo)',
                _createDynamicExamples()),

            // 6. SINAIS DE REPETIÇÃO
            _buildSection('6. Repetições (Segno, Coda, Dal Segno, Da Capo)',
                _createRepeatExamples()),

            // 7. RESPIRAÇÕES E CAESURAS
            _buildSection('7. Respirações e Caesuras (Vírgula, Tick, Caesura)',
                _createBreathExamples()),

            // 8. SINAIS DE OITAVA
            _buildSection('8. Sinais de Oitava (8va, 8vb, 15ma, 15mb)',
                _createOctaveExamples()),

            // 9. HARMÔNICOS
            _buildSection('9. Harmônicos (Natural, Artificial)',
                _createHarmonicExamples()),

            // 10. CLUSTERS
            _buildSection('10. Clusters (Notação Contemporânea)',
                _createClusterExamples()),

            // 11. FÓRMULAS DE COMPASSO ESPECIAIS
            _buildSection('11. Compassos Especiais (Comum, Cortado)',
                _createTimeSignatureExamples()),

            const SizedBox(height: 30),
            const Text(
              'Implementação baseada nas especificações SMuFL 1.5\n'
              'Fonte: Bravura (Steinberg Media Technologies)\n'
              'Posicionamento: Coordenadas SMuFL com anchors precisos',
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
                  ornamentColor: Colors.purple,
                  dynamicColor: Colors.blue,
                  repeatColor: Colors.green,
                  octaveColor: Colors.orange,
                  clusterColor: Colors.red,
                  caesuraColor: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === EXEMPLOS DE CLAVES ===
  List<MusicalElement> _createClefExamples() {
    return [
      // Claves de Sol
      Clef(clefType: ClefType.treble),
      Clef(clefType: ClefType.treble8va),
      Clef(clefType: ClefType.treble8vb),

      // Claves de Fá (3ª e 4ª linha)
      Clef(clefType: ClefType.bass), // 4ª linha (padrão)
      Clef(clefType: ClefType.bassThirdLine), // 3ª linha

      // Claves de Dó (todas as posições)
      Clef(clefType: ClefType.soprano), // 1ª linha
      Clef(clefType: ClefType.mezzoSoprano), // 2ª linha
      Clef(clefType: ClefType.alto), // 3ª linha (viola)
      Clef(clefType: ClefType.tenor), // 4ª linha (violoncelo/fagote)
      Clef(clefType: ClefType.baritone), // 5ª linha (histórico)

      // Claves especiais
      Clef(clefType: ClefType.percussion),
      Clef(clefType: ClefType.tab6),
    ];
  }

  // === EXEMPLOS DE ACIDENTES ===
  List<MusicalElement> _createAccidentalExamples() {
    return [
      // Acidentes básicos
      Note(
        pitch: Pitch.withAccidental(
            step: 'C', octave: 4, accidentalType: AccidentalType.sharp),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: Pitch.withAccidental(
            step: 'D', octave: 4, accidentalType: AccidentalType.flat),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: Pitch.withAccidental(
            step: 'E', octave: 4, accidentalType: AccidentalType.doubleSharp),
        duration: const Duration(DurationType.quarter),
      ),

      // Acidentes microtonais
      Note(
        pitch: Pitch.withAccidental(
            step: 'F',
            octave: 4,
            accidentalType: AccidentalType.quarterToneSharp),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: Pitch.withAccidental(
            step: 'G',
            octave: 4,
            accidentalType: AccidentalType.quarterToneFlat),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: Pitch.withAccidental(
            step: 'A', octave: 4, accidentalType: AccidentalType.komaSharp),
        duration: const Duration(DurationType.quarter),
      ),
    ];
  }

  // === EXEMPLOS DE ARTICULAÇÕES ===
  List<MusicalElement> _createArticulationExamples() {
    return [
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.staccato],
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.tenuto],
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.accent],
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.marcato],
      ),
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.upBow],
      ),
    ];
  }

  // === EXEMPLOS DE ORNAMENTOS ===
  List<MusicalElement> _createOrnamentExamples() {
    return [
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

  // === EXEMPLOS DE DINÂMICAS ===
  List<MusicalElement> _createDynamicExamples() {
    return [
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        dynamicElement: Dynamic(type: DynamicType.piano),
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
        dynamicElement: Dynamic(type: DynamicType.forte),
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter),
        dynamicElement: Dynamic(type: DynamicType.sforzando),
      ),
      Dynamic(type: DynamicType.crescendo, isHairpin: true, length: 100),
    ];
  }

  // === EXEMPLOS DE REPETIÇÕES ===
  List<MusicalElement> _createRepeatExamples() {
    return [
      RepeatMark(type: RepeatType.segno),
      RepeatMark(type: RepeatType.coda),
      RepeatMark(type: RepeatType.fine, label: 'Fine'),
      RepeatMark(type: RepeatType.repeat1Bar),
      RepeatMark(type: RepeatType.simile),
    ];
  }

  // === EXEMPLOS DE RESPIRAÇÕES ===
  List<MusicalElement> _createBreathExamples() {
    return [
      Breath(type: BreathType.comma),
      Breath(type: BreathType.tick),
      Caesura(type: CaesuraType.short),
      Caesura(type: CaesuraType.thick),
    ];
  }

  // === EXEMPLOS DE SINAIS DE OITAVA ===
  List<MusicalElement> _createOctaveExamples() {
    return [
      OctaveMark(type: OctaveType.octave8va),
      OctaveMark(type: OctaveType.octave8vb),
      OctaveMark(type: OctaveType.octave15ma),
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
    ];
  }

  // === EXEMPLOS DE HARMÔNICOS ===
  List<MusicalElement> _createHarmonicExamples() {
    return [
      Harmonic(type: HarmonicType.natural),
      Harmonic(type: HarmonicType.artificial),
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.harmonics],
      ),
    ];
  }

  // === EXEMPLOS DE CLUSTERS ===
  List<MusicalElement> _createClusterExamples() {
    return [
      Cluster(
        type: ClusterType.tone,
        lowestNote: const Pitch(step: 'C', octave: 4),
        highestNote: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.half),
      ),
    ];
  }

  // === EXEMPLOS DE COMPASSOS ESPECIAIS ===
  List<MusicalElement> _createTimeSignatureExamples() {
    return [
      TimeSignature(numerator: 4, denominator: 4), // Comum (C)
      TimeSignature(numerator: 2, denominator: 2), // Cortado (ɸ)
      TimeSignature(numerator: 3, denominator: 4),
      TimeSignature(numerator: 6, denominator: 8),
    ];
  }
}
