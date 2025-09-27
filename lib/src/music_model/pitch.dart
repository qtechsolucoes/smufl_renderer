// lib/src/music_model/pitch.dart

/// Representa a altura de uma nota musical.
class Pitch {
  /// O nome da nota (C, D, E, F, G, A, B).
  final String step;

  /// A alteração (-1 para bemol, 0 para natural, 1 para sustenido).
  final int alter;

  /// A oitava da nota (ex: 4 para a oitava central).
  final int octave;

  const Pitch({required this.step, this.alter = 0, required this.octave});
}
