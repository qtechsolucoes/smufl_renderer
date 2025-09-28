// example/lib/examples/advanced_features_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo demonstrando todas as funcionalidades avançadas implementadas:
/// - Ornamentos (trilos, mordentes, grupetos, etc.)
/// - Dinâmicas (forte, piano, crescendo, etc.)
/// - Articulações (staccato, accent, tenuto, etc.)
/// - Sistema inteligente de union de figuras (beams)
/// - Durações expandidas (fusa, semifusa)
class AdvancedFeaturesExample extends StatelessWidget {
  const AdvancedFeaturesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionalidades Avançadas - SMuFL Renderer'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demonstração das Funcionalidades Avançadas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildSection(
              'Ornamentos (Trilos, Mordentes, Grupetos)',
              _createOrnamentsExample(),
            ),

            _buildSection(
              'Dinâmicas (Forte, Piano, Crescendo)',
              _createDynamicsExample(),
            ),

            _buildSection(
              'Articulações (Staccato, Accent, Tenuto)',
              _createArticulationsExample(),
            ),

            _buildSection(
              'Sistema Inteligente de União de Figuras',
              _createBeamingExample(),
            ),

            _buildSection(
              'Durações Expandidas (Fusa, Semifusa)',
              _createExtendedDurationsExample(),
            ),

            _buildSection(
              'Crescendo e Diminuendo (Hairpins)',
              _createHairpinsExample(),
            ),

            _buildSection(
              'Quiálteras (Tuplets)',
              _createTupletsExample(),
            ),

            _buildSection(
              'Exemplo Completo - Todos os Recursos',
              _createCompleteExample(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget musicScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: musicScore,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// Exemplo com ornamentos variados
  Widget _createOrnamentsExample() {
    final staff = Staff();
    final measure = Measure();

    // Adicionar clave e fórmula de compasso
    measure.add(Clef(type: 'g'));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com ornamentos - incluindo pontos de aumento
    measure.add(Note(
      pitch: Pitch.fromString('C4'),
      duration: const Duration(DurationType.quarter, dots: 1), // Semínima pontuada
      ornaments: [Ornament(type: OrnamentType.trill, above: true)],
    ));

    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.eighth),
      ornaments: [Ornament(type: OrnamentType.mordent, above: true)],
    ));

    measure.add(Note(
      pitch: Pitch.fromString('E4'),
      duration: const Duration(DurationType.quarter, dots: 2), // Duplo ponto
      ornaments: [Ornament(type: OrnamentType.turn, above: true)],
    ));

    measure.add(Note(
      pitch: Pitch.fromString('F4'),
      duration: const Duration(DurationType.sixteenth),
      ornaments: [Ornament(type: OrnamentType.fermata, above: true)],
    ));

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }

  /// Exemplo com dinâmicas variadas
  Widget _createDynamicsExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com dinâmicas
    measure.add(Note(
      pitch: Pitch.fromString('C4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.piano),
    ));

    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.mezzoForte),
    ));

    measure.add(Note(
      pitch: Pitch.fromString('E4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.forte),
    ));

    measure.add(Note(
      pitch: Pitch.fromString('F4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.sforzando),
    ));

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }

  /// Exemplo com articulações variadas
  Widget _createArticulationsExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com articulações
    measure.add(Note(
      pitch: Pitch.fromString('C4'),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
    ));

    measure.add(Note(
      pitch: Pitch.fromString('E4'),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.tenuto],
    ));

    measure.add(Note(
      pitch: Pitch.fromString('F4'),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.marcato],
    ));

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }

  /// Exemplo demonstrando o sistema inteligente de beaming
  Widget _createBeamingExample() {
    final staff = Staff();

    // Primeiro compasso: 4/4 - agrupamento simples
    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(TimeSignature(numerator: 4, denominator: 4));

    // Duas colcheias por tempo (4 grupos)
    for (int beat = 0; beat < 4; beat++) {
      measure1.add(Note(
        pitch: Pitch.fromString('C4'),
        duration: const Duration(DurationType.eighth),
      ));
      measure1.add(Note(
        pitch: Pitch.fromString('D4'),
        duration: const Duration(DurationType.eighth),
      ));
    }

    // Segundo compasso: 6/8 - agrupamento composto
    final measure2 = Measure();
    measure2.add(TimeSignature(numerator: 6, denominator: 8));

    // Três colcheias por tempo (2 grupos)
    for (int beat = 0; beat < 2; beat++) {
      measure2.add(Note(
        pitch: Pitch.fromString('E4'),
        duration: const Duration(DurationType.eighth),
      ));
      measure2.add(Note(
        pitch: Pitch.fromString('F4'),
        duration: const Duration(DurationType.eighth),
      ));
      measure2.add(Note(
        pitch: Pitch.fromString('G4'),
        duration: const Duration(DurationType.eighth),
      ));
    }

    staff.add(measure1);
    staff.add(measure2);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }

  /// Exemplo com as novas durações (fusa e semifusa)
  Widget _createExtendedDurationsExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Semínima seguida de subdivisões progressivas
    measure.add(Note(
      pitch: Pitch.fromString('C4'),
      duration: const Duration(DurationType.quarter),
    ));

    // Duas colcheias
    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.eighth),
    ));
    measure.add(Note(
      pitch: Pitch.fromString('E4'),
      duration: const Duration(DurationType.eighth),
    ));

    // Quatro semicolcheias
    for (int i = 0; i < 4; i++) {
      measure.add(Note(
        pitch: Pitch.fromString('F4'),
        duration: const Duration(DurationType.sixteenth),
      ));
    }

    // Oito fusas
    for (int i = 0; i < 8; i++) {
      measure.add(Note(
        pitch: Pitch.fromString('G4'),
        duration: const Duration(DurationType.thirtySecond),
      ));
    }

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }

  /// Exemplo completo combinando todos os recursos
  Widget _createCompleteExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(2)); // Ré maior
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Nota com tudo: ornamento, dinâmica e articulação
    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.quarter),
      ornaments: [Ornament(type: OrnamentType.trill, above: true)],
      dynamicElement: Dynamic(type: DynamicType.forte),
      articulations: [ArticulationType.accent],
    ));

    // Grupo de colcheias com articulações
    measure.add(Note(
      pitch: Pitch.fromString('F#4'),
      duration: const Duration(DurationType.eighth),
      articulations: [ArticulationType.staccato],
    ));
    measure.add(Note(
      pitch: Pitch.fromString('A4'),
      duration: const Duration(DurationType.eighth),
      articulations: [ArticulationType.tenuto],
    ));

    // Semicolcheias com ornamentos
    measure.add(Note(
      pitch: Pitch.fromString('B4'),
      duration: const Duration(DurationType.sixteenth),
      ornaments: [Ornament(type: OrnamentType.mordent, above: true)],
    ));
    measure.add(Note(
      pitch: Pitch.fromString('A4'),
      duration: const Duration(DurationType.sixteenth),
    ));
    measure.add(Note(
      pitch: Pitch.fromString('G4'),
      duration: const Duration(DurationType.sixteenth),
    ));
    measure.add(Note(
      pitch: Pitch.fromString('F#4'),
      duration: const Duration(DurationType.sixteenth),
    ));

    // Fusas finais
    for (int i = 0; i < 4; i++) {
      measure.add(Note(
        pitch: Pitch.fromString('D4'),
        duration: const Duration(DurationType.thirtySecond),
      ));
    }

    // Nota final com fermata
    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.quarter),
      ornaments: [Ornament(type: OrnamentType.fermata, above: true)],
      dynamicElement: Dynamic(type: DynamicType.piano),
    ));

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 16.0,
    );
  }

  /// Exemplo com crescendo e diminuendo
  Widget _createHairpinsExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com crescendo e diminuendo
    measure.add(Note(
      pitch: Pitch.fromString('C4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.piano),
    ));

    measure.add(Note(
      pitch: Pitch.fromString('D4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(
        type: DynamicType.crescendo,
        isHairpin: true,
        length: 50.0,
      ),
    ));

    measure.add(Note(
      pitch: Pitch.fromString('E4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(type: DynamicType.forte),
    ));

    measure.add(Note(
      pitch: Pitch.fromString('F4'),
      duration: const Duration(DurationType.quarter),
      dynamicElement: Dynamic(
        type: DynamicType.diminuendo,
        isHairpin: true,
        length: 50.0,
      ),
    ));

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }

  /// Exemplo com quiálteras
  Widget _createTupletsExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Tercina
    final tripletNotes = [
      Note(pitch: Pitch.fromString('C4'), duration: const Duration(DurationType.eighth)),
      Note(pitch: Pitch.fromString('D4'), duration: const Duration(DurationType.eighth)),
      Note(pitch: Pitch.fromString('E4'), duration: const Duration(DurationType.eighth)),
    ];

    measure.add(Tuplet(
      actualNotes: 3,
      normalNotes: 2,
      elements: tripletNotes,
      showBracket: true,
      showNumber: true,
    ));

    // Nota normal
    measure.add(Note(
      pitch: Pitch.fromString('F4'),
      duration: const Duration(DurationType.quarter),
    ));

    // Quintina
    final quintoletNotes = [
      Note(pitch: Pitch.fromString('G4'), duration: const Duration(DurationType.sixteenth)),
      Note(pitch: Pitch.fromString('A4'), duration: const Duration(DurationType.sixteenth)),
      Note(pitch: Pitch.fromString('B4'), duration: const Duration(DurationType.sixteenth)),
      Note(pitch: Pitch.fromString('C5'), duration: const Duration(DurationType.sixteenth)),
      Note(pitch: Pitch.fromString('D5'), duration: const Duration(DurationType.sixteenth)),
    ];

    measure.add(Tuplet(
      actualNotes: 5,
      normalNotes: 4,
      elements: quintoletNotes,
      showBracket: true,
      showNumber: true,
    ));

    staff.add(measure);

    return MusicScore(
      staff: staff,
      theme: MusicScoreTheme.colorful(),
      staffSpace: 14.0,
    );
  }
}