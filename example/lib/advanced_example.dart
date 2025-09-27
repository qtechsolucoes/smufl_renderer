// example/lib/advanced_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo avançado demonstrando todas as funcionalidades da biblioteca
class AdvancedMusicExample extends StatelessWidget {
  const AdvancedMusicExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMuFL Renderer - Exemplo Avançado'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Exemplo Básico', _buildBasicExample()),
            const SizedBox(height: 32),
            _buildSection('Exemplo com Acordes', _buildChordExample()),
            const SizedBox(height: 32),
            _buildSection('Exemplo com Ornamentos', _buildOrnamentExample()),
            const SizedBox(height: 32),
            _buildSection('Exemplo com Dinâmicas', _buildDynamicsExample()),
            const SizedBox(height: 32),
            _buildSection('Exemplo com Microtons', _buildMicrotoneExample()),
            const SizedBox(height: 32),
            _buildSection('Tema Colorido', _buildColorfulExample()),
            const SizedBox(height: 32),
            _buildSection('Tema Escuro', _buildDarkExample()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildBasicExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(0));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Escala simples
    final notes = [
      Note(
        pitch: const Pitch(step: 'C', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 4),
        duration: const Duration(DurationType.quarter),
      ),
    ];

    for (final note in notes) {
      measure.add(note);
    }

    staff.add(measure);

    return SizedBox(
      height: 200,
      child: MusicScore(staff: staff),
    );
  }

  Widget _buildChordExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(0));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Acordes simples (simulados com notas)
    final chordNotes = [
      [
        Note(pitch: const Pitch(step: 'C', octave: 4), duration: const Duration(DurationType.whole)),
        Note(pitch: const Pitch(step: 'E', octave: 4), duration: const Duration(DurationType.whole)),
        Note(pitch: const Pitch(step: 'G', octave: 4), duration: const Duration(DurationType.whole)),
      ],
    ];

    // Adiciona as notas do primeiro acorde
    for (final note in chordNotes[0]) {
      measure.add(note);
    }

    staff.add(measure);

    return SizedBox(
      height: 200,
      child: MusicScore(staff: staff),
    );
  }

  Widget _buildOrnamentExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(0));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com articulações diferentes
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.tenuto],
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return SizedBox(
      height: 200,
      child: MusicScore(staff: staff),
    );
  }

  Widget _buildDynamicsExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(0));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com diferentes dinâmicas (simuladas)
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return SizedBox(
      height: 200,
      child: MusicScore(staff: staff),
    );
  }

  Widget _buildMicrotoneExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(0));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas com acidentes microtonais
    measure.add(Note(
      pitch: Pitch.withAccidental(
        step: 'C',
        octave: 4,
        accidentalType: AccidentalType.quarterToneSharp,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    measure.add(Note(
      pitch: Pitch.withAccidental(
        step: 'D',
        octave: 4,
        accidentalType: AccidentalType.quarterToneFlat,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 4, alter: 1.5), // 3/4 de tom acima
      duration: const Duration(DurationType.quarter),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return SizedBox(
      height: 200,
      child: MusicScore(staff: staff),
    );
  }

  Widget _buildColorfulExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(2)); // Ré maior
    measure.add(TimeSignature(numerator: 3, denominator: 4));

    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.accent],
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 4, alter: 1.0),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.tenuto],
    ));

    staff.add(measure);

    return SizedBox(
      height: 200,
      child: MusicScore(
        staff: staff,
        theme: MusicScoreTheme.colorful(),
      ),
    );
  }

  Widget _buildDarkExample() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'f')); // Clave de fá
    measure.add(KeySignature(-3)); // Mi bemol maior
    measure.add(TimeSignature(numerator: 6, denominator: 8));

    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 3, alter: -1.0),
      duration: const Duration(DurationType.eighth),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 3),
      duration: const Duration(DurationType.eighth),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'B', octave: 3, alter: -1.0),
      duration: const Duration(DurationType.eighth),
    ));

    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 4, alter: -1.0),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: MusicScore(
          staff: staff,
          theme: MusicScoreTheme.dark(),
        ),
      ),
    );
  }
}