// example/lib/examples/complete_notation_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo demonstrando todos os símbolos musicais, figuras, articulações,
/// ornamentos e elementos implementados seguindo as especificações SMuFL
class CompleteNotationExample extends StatelessWidget {
  const CompleteNotationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notação Musical Completa - SMuFL'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demonstração Completa da Implementação SMuFL',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 1. TODAS AS FIGURAS DE DURAÇÃO
            _buildSection('1. Todas as Figuras Rítmicas (Semibreve até Semifusa)', _createDurationExamples()),

            // 2. PONTOS DE AUMENTO
            _buildSection('2. Pontos de Aumento (Posicionamento Correto)', _createDottedNoteExamples()),

            // 3. ARTICULAÇÕES COM POSICIONAMENTO CORRETO
            _buildSection('3. Articulações (Posicionamento baseado na Direção da Haste)', _createArticulationPositionExamples()),

            // 4. AGRUPAMENTO INTELIGENTE DE BARRAS (MELHORADO)
            _buildSection('4. Beams Múltiplos: Colcheias, Semicolcheias, Fusas e Semifusas', _createAdvancedBeamExamples()),

            // 5. QUIÁLTERAS
            _buildSection('5. Quiálteras (Tercinas, Quintinas)', _createTupletExamples()),

            // 6. ORNAMENTOS POSICIONADOS CORRETAMENTE
            _buildSection('6. Ornamentos (Posicionamento Acima da Nota)', _createOrnamentPositionExamples()),

            // 7. ACIDENTES MICROTONAIS
            _buildSection('7. Acidentes Microtonais e Avançados', _createMicrotonalExamples()),

            // 8. DINÂMICAS E EXPRESSÕES
            _buildSection('8. Dinâmicas e Expressões', _createDynamicExpressionExamples()),

            // 9. LIGADURAS E FRASEADOS
            _buildSection('9. Ligaduras de Valor e Expressão', _createSlurTieExamples()),

            // 10. ELEMENTOS CONTEMPORÂNEOS
            _buildSection('10. Notação Contemporânea', _createContemporaryExamples()),

            const SizedBox(height: 30),
            const Text(
              'Implementação Completa SMuFL 1.5\n'
              '✓ Posicionamento correto de articulações\n'
              '✓ Pontos de aumento maiores e bem posicionados\n'
              '✓ Agrupamento inteligente de barras\n'
              '✓ Todas as figuras (semibreve até semifusa)\n'
              '✓ Ornamentos posicionados conforme especificações\n'
              '✓ Metadata Bravura como referência',
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
                  articulationColor: Colors.red,
                  beamColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === 1. TODAS AS FIGURAS DE DURAÇÃO ===
  List<MusicalElement> _createDurationExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Semibreve
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.whole),
      ),

      // Mínima
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.half),
      ),

      // Semínima
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),

      // Colcheia
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),

      // Semicolcheia
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.sixteenth),
      ),

      // Fusa
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.thirtySecond),
      ),

      // Semifusa
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.sixtyFourth),
      ),
    ];
  }

  // === 2. PONTOS DE AUMENTO ===
  List<MusicalElement> _createDottedNoteExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 6, denominator: 8),

      // Mínima pontuada
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.half, dots: 1),
      ),

      // Semínima pontuada
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter, dots: 1),
      ),

      // Colcheia pontuada
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.eighth, dots: 1),
      ),

      // Nota com duplo ponto
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.quarter, dots: 2),
      ),
    ];
  }

  // === 3. ARTICULAÇÕES COM POSICIONAMENTO CORRETO ===
  List<MusicalElement> _createArticulationPositionExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Notas agudas (haste para baixo) - articulações acima
      Note(
        pitch: const Pitch(step: 'G', octave: 5),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.staccato],
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 5),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.accent],
      ),

      // Notas graves (haste para cima) - articulações abaixo
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

      // Semibreve (sem haste) - articulações acima
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.whole),
        articulations: [ArticulationType.staccatissimo],
      ),
    ];
  }

  // === 4. AGRUPAMENTO INTELIGENTE DE BARRAS ===

  // === 4B. BEAMS MÚLTIPLOS AVANÇADOS ===
  List<MusicalElement> _createAdvancedBeamExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Grupo 1: Colcheias simples
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.start,
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.eighth),
        beam: BeamType.end,
      ),

      // Grupo 2: Semicolcheias (2 beams)
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
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        beam: BeamType.end,
      ),

      // Grupo 3: Fusas (3 beams)
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
      ),

      // Grupo 4: Semifusas (4 beams)
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

  // === 5. QUIÁLTERAS ===
  List<MusicalElement> _createTupletExamples() {
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
          ),
          Note(
            pitch: const Pitch(step: 'D', octave: 4),
            duration: const Duration(DurationType.eighth),
          ),
          Note(
            pitch: const Pitch(step: 'E', octave: 4),
            duration: const Duration(DurationType.eighth),
          ),
        ],
        notes: [],
        showBracket: true,
        showNumber: true,
        ratio: const TupletRatio(3, 2),
        bracket: true,
      ),

      // Quintina de semicolcheias
      Tuplet(
        actualNotes: 5,
        normalNotes: 4,
        elements: [
          Note(
            pitch: const Pitch(step: 'F', octave: 4),
            duration: const Duration(DurationType.sixteenth),
          ),
          Note(
            pitch: const Pitch(step: 'G', octave: 4),
            duration: const Duration(DurationType.sixteenth),
          ),
          Note(
            pitch: const Pitch(step: 'A', octave: 4),
            duration: const Duration(DurationType.sixteenth),
          ),
          Note(
            pitch: const Pitch(step: 'B', octave: 4),
            duration: const Duration(DurationType.sixteenth),
          ),
          Note(
            pitch: const Pitch(step: 'C', octave: 5),
            duration: const Duration(DurationType.sixteenth),
          ),
        ],
        notes: [],
        showBracket: true,
        showNumber: true,
        ratio: const TupletRatio(5, 4),
        bracket: true,
      ),
    ];
  }

  // === 6. ORNAMENTOS POSICIONADOS CORRETAMENTE ===
  List<MusicalElement> _createOrnamentPositionExamples() {
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

  // === 7. ACIDENTES MICROTONAIS ===
  List<MusicalElement> _createMicrotonalExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Acidentes básicos
      Note(
        pitch: Pitch.withAccidental(step: 'C', octave: 4, accidentalType: AccidentalType.sharp),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: Pitch.withAccidental(step: 'D', octave: 4, accidentalType: AccidentalType.flat),
        duration: const Duration(DurationType.quarter),
      ),

      // Acidentes microtonais
      Note(
        pitch: Pitch.withAccidental(step: 'E', octave: 4, accidentalType: AccidentalType.quarterToneSharp),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: Pitch.withAccidental(step: 'F', octave: 4, accidentalType: AccidentalType.quarterToneFlat),
        duration: const Duration(DurationType.quarter),
      ),
    ];
  }

  // === 8. DINÂMICAS E EXPRESSÕES ===
  List<MusicalElement> _createDynamicExpressionExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

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

      // Crescendo
      Dynamic(type: DynamicType.crescendo, isHairpin: true, length: 100),
    ];
  }

  // === 9. LIGADURAS ===
  List<MusicalElement> _createSlurTieExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Ligadura de valor (tie)
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        tie: TieType.start,
      ),
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
        tie: TieType.end,
      ),

      // Ligadura de expressão (slur)
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
        slur: SlurType.start,
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter),
        slur: SlurType.end,
      ),
    ];
  }

  // === 10. ELEMENTOS CONTEMPORÂNEOS ===
  List<MusicalElement> _createContemporaryExamples() {
    return [
      Clef(clefType: ClefType.treble),
      TimeSignature(numerator: 4, denominator: 4),

      // Cluster
      Cluster(
        type: ClusterType.tone,
        lowestNote: const Pitch(step: 'C', octave: 4),
        highestNote: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.half),
      ),

      // Harmônicos
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.quarter),
        articulations: [ArticulationType.harmonics],
      ),

      // Respiração
      Breath(type: BreathType.comma),

      // Caesura
      Caesura(type: CaesuraType.short),
    ];
  }
}