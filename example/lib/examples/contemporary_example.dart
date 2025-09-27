// example/lib/examples/contemporary_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class ContemporaryExample extends StatelessWidget {
  const ContemporaryExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo de música contemporânea com técnicas avançadas
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(-3)); // Mi♭ maior
    measure1.add(TimeSignature(numerator: 7, denominator: 8));

    // Sequência com técnicas estendidas
    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'G',
        octave: 4,
        accidentalType: AccidentalType.quarterToneSharp,
      ),
      duration: const Duration(DurationType.eighth),
      ornaments: [
        Ornament(type: OrnamentType.shake, above: true),
      ],
      techniques: [
        PlayingTechnique(type: TechniqueType.glissando),
      ],
      dynamicElement: Dynamic(type: DynamicType.pianississimo),
    ));

    measure1.add(Note(
      pitch: const Pitch(step: 'A', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      articulations: [ArticulationType.staccato],
      ornaments: [
        Ornament(type: OrnamentType.trillSharp, above: true),
      ],
    ));

    measure1.add(Note(
      pitch: Pitch.withAccidental(
        step: 'F',
        octave: 3,
        accidentalType: AccidentalType.threeQuarterToneFlat,
      ),
      duration: const Duration(DurationType.sixteenth),
      techniques: [
        PlayingTechnique(type: TechniqueType.harmonic),
      ],
    ));

    // Cluster de quartos de tom
    measure1.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 4),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'C',
            octave: 4,
            accidentalType: AccidentalType.quarterToneSharp,
          ),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'C',
            octave: 4,
            accidentalType: AccidentalType.sharp,
          ),
          duration: const Duration(DurationType.quarter),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'C',
            octave: 4,
            accidentalType: AccidentalType.threeQuarterToneSharp,
          ),
          duration: const Duration(DurationType.quarter),
        ),
      ],
      duration: const Duration(DurationType.quarter),
      dynamic: Dynamic(type: DynamicType.sforzando),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
    ));

    // Pausa com respiração
    measure1.add(Rest(
      duration: const Duration(DurationType.eighth),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
    ));

    measure1.add(Breath(type: BreathType.caesura));

    final measure2 = Measure();

    // Quiáltera complexa (5:4)
    final complexTupletNotes = [
      Note(
        pitch: const Pitch(step: 'E', octave: 5),
        duration: const Duration(DurationType.sixteenth),
        articulations: [ArticulationType.accent],
      ),
      Note(
        pitch: Pitch.withAccidental(
          step: 'D',
          octave: 5,
          accidentalType: AccidentalType.quarterToneFlat,
        ),
        duration: const Duration(DurationType.sixteenth),
        techniques: [
          PlayingTechnique(type: TechniqueType.pizzicato),
        ],
      ),
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.sixteenth),
        ornaments: [
          Ornament(type: OrnamentType.turn, above: true),
        ],
      ),
      Note(
        pitch: Pitch.withAccidental(
          step: 'B',
          octave: 4,
          accidentalType: AccidentalType.quarterToneSharp,
        ),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.sixteenth),
        articulations: [ArticulationType.tenuto],
      ),
    ];

    measure2.add(Tuplet(
      actualNotes: 5,
      normalNotes: 4,
      elements: complexTupletNotes,
      showBracket: true,
      showNumber: true,
    ));

    // Dinâmica crescendo
    measure2.add(Dynamic(
      type: DynamicType.crescendo,
      isHairpin: true,
      length: 80.0,
    ));

    // Glissando final
    measure2.add(Note(
      pitch: const Pitch(step: 'G', octave: 3),
      duration: const Duration(DurationType.quarter),
      techniques: [
        PlayingTechnique(type: TechniqueType.glissando),
      ],
      dynamicElement: Dynamic(type: DynamicType.fortississimo),
    ));

    final measure3 = Measure();

    // Técnicas modernas finais
    measure3.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.eighth),
      techniques: [
        PlayingTechnique(type: TechniqueType.flutterTongue),
      ],
      ornaments: [
        Ornament(type: OrnamentType.wavyLine, above: true),
      ],
    ));

    measure3.add(Note(
      pitch: const Pitch(step: 'E', octave: 4),
      duration: const Duration(DurationType.eighth),
      techniques: [
        PlayingTechnique(type: TechniqueType.bisbigliando),
      ],
    ));

    // Acorde final com técnicas estendidas
    measure3.add(Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 3),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: Pitch.withAccidental(
            step: 'F',
            octave: 4,
            accidentalType: AccidentalType.quarterToneSharp,
          ),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: const Pitch(step: 'B', octave: 5),
          duration: const Duration(DurationType.half),
        ),
      ],
      duration: const Duration(DurationType.half),
      dynamic: Dynamic(type: DynamicType.niente),
      ornaments: [
        Ornament(type: OrnamentType.fermata, above: true),
      ],
      techniques: [
        PlayingTechnique(type: TechniqueType.harmonic),
      ],
    ));

    staff.add(measure1);
    staff.add(measure2);
    staff.add(measure3);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exemplo Contemporâneo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Música contemporânea com técnicas avançadas:\\n'
                    '• Fórmula de compasso assimétrica (7/8)\\n'
                    '• Microtonalidade (quartos e três quartos de tom)\\n'
                    '• Clusters harmônicos\\n'
                    '• Quiálteras complexas (5:4)\\n'
                    '• Técnicas estendidas (glissando, harmônicos, pizzicato)\\n'
                    '• Ornamentos modernos (shake, wavy line)\\n'
                    '• Dinâmicas extremas (ppp, fff, niente)\\n'
                    '• Respirações e cesuras',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: 350,
                  child: MusicScore(
                    staff: staff,
                    theme: MusicScoreTheme.dark(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}