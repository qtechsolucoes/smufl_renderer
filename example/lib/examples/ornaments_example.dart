// example/lib/examples/ornaments_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Widget que demonstra a renderização de ornamentos musicais
class OrnamentsExample extends StatelessWidget {
  const OrnamentsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Família de Símbolos: Ornamentos'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'Trinados (Trilos) - Acima',
              description: 'Trinados simples e com alterações cromáticas posicionados acima.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'G', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.trill, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.trillSharp, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'B', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.trillFlat, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'C', octave: 5),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.trillNatural, above: true)],
                ),
              ],
            ),
            _buildSection(
              title: 'Trinados (Trilos) - Abaixo',
              description: 'Trinados posicionados abaixo das notas.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'F', octave: 5),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.trill, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'G', octave: 5),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.shortTrill, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 5),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.trillLigature, above: false)],
                ),
                Rest(duration: const Duration(DurationType.half)),
              ],
            ),
            _buildSection(
              title: 'Mordentes - Acima',
              description: 'Mordentes superiores e inferiores posicionados acima.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'F', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.mordent, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'G', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.invertedMordent, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.mordentUpperPrefix, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'B', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.mordentLowerPrefix, above: true)],
                ),
              ],
            ),
            _buildSection(
              title: 'Mordentes - Abaixo',
              description: 'Mordentes posicionados abaixo das notas.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'C', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.mordent, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'D', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.invertedMordent, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'E', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.mordentUpperPrefix, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'F', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.mordentLowerPrefix, above: false)],
                ),
              ],
            ),
            _buildSection(
              title: 'Grupetos',
              description: 'Grupetos simples, invertidos e com corte.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'E', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.turn)],
                ),
                Note(
                  pitch: const Pitch(step: 'F', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.turnInverted)],
                ),
                Note(
                  pitch: const Pitch(step: 'G', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.invertedTurn)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.turnSlash)],
                ),
              ],
            ),
            _buildSection(
              title: 'Apojaturas',
              description: 'Apojaturas superiores e inferiores, e acciaccaturas.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'C', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.appoggiaturaUp)],
                ),
                Note(
                  pitch: const Pitch(step: 'D', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.appoggiaturaDown)],
                ),
                Note(
                  pitch: const Pitch(step: 'E', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.acciaccatura)],
                ),
                Rest(duration: const Duration(DurationType.quarter)),
              ],
            ),
            _buildSection(
              title: 'Glissandos e Portamentos',
              description: 'Efeitos de escorregamento entre notas.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'G', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.glissando)],
                ),
                Note(
                  pitch: const Pitch(step: 'C', octave: 5),
                  duration: const Duration(DurationType.quarter),
                ),
                Note(
                  pitch: const Pitch(step: 'F', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.portamento)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 4),
                  duration: const Duration(DurationType.quarter),
                ),
              ],
            ),
            _buildSection(
              title: 'Fermatas - Acima e Abaixo',
              description: 'Fermatas posicionadas acima e abaixo das notas.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'F', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.fermata, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'G', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.fermata, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.fermataBelow, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'B', octave: 4),
                  duration: const Duration(DurationType.half),
                  ornaments: [Ornament(type: OrnamentType.fermataBelowInverted, above: false)],
                ),
              ],
            ),
            _buildSection(
              title: 'Linhas Ornamentais',
              description: 'Linhas decorativas e efeitos especiais.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'D', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.wavyLine)],
                ),
                Note(
                  pitch: const Pitch(step: 'E', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.zigzagLine)],
                ),
                Note(
                  pitch: const Pitch(step: 'F', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.zigZagLineNoRightEnd)],
                ),
                Note(
                  pitch: const Pitch(step: 'G', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.zigZagLineWithRightEnd)],
                ),
              ],
            ),
            _buildSection(
              title: 'Ornamentos Barrocos',
              description: 'Ornamentos especiais da música barroca e clássica.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'C', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.schleifer, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'D', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.haydn, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'E', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.trillLigature, above: false)],
                ),
                Rest(duration: const Duration(DurationType.quarter)),
              ],
            ),
            _buildSection(
              title: 'Efeitos Instrumentais',
              description: 'Efeitos especiais para instrumentos de sopro e cordas.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'F', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.shake, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'G', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.bend, above: false)],
                ),
                Note(
                  pitch: const Pitch(step: 'A', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.scoop, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'B', octave: 4),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.fall, above: false)],
                ),
              ],
            ),
            _buildSection(
              title: 'Mais Efeitos Especiais',
              description: 'Doit, plop e arpejos.',
              elements: [
                Clef(clefType: ClefType.treble),
                Note(
                  pitch: const Pitch(step: 'C', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.doit, above: true)],
                ),
                Note(
                  pitch: const Pitch(step: 'D', octave: 5),
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.plop, above: false)],
                ),
                Chord(
                  notes: [
                    Note(
                      pitch: const Pitch(step: 'E', octave: 4),
                      duration: const Duration(DurationType.quarter),
                    ),
                    Note(
                      pitch: const Pitch(step: 'G', octave: 4),
                      duration: const Duration(DurationType.quarter),
                    ),
                    Note(
                      pitch: const Pitch(step: 'B', octave: 4),
                      duration: const Duration(DurationType.quarter),
                    ),
                  ],
                  duration: const Duration(DurationType.quarter),
                  ornaments: [Ornament(type: OrnamentType.arpeggio, above: true)],
                ),
                Rest(duration: const Duration(DurationType.quarter)),
              ],
            ),
          ],
        ),
      ),
    );
  }

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