// lib/src/theme/music_score_theme.dart
import 'package:flutter/material.dart';

class MusicScoreTheme {
  final Color staffLineColor;
  final Color noteheadColor;
  final Color stemColor;
  final Color clefColor;
  final Color barlineColor;
  final Color timeSignatureColor;
  final Color keySignatureColor;
  final Color restColor;
  final Color articulationColor; // NOVA PROPRIEDADE

  const MusicScoreTheme({
    this.staffLineColor = Colors.black,
    this.noteheadColor = Colors.black,
    this.stemColor = Colors.black,
    this.clefColor = Colors.black,
    this.barlineColor = Colors.black,
    this.timeSignatureColor = Colors.black,
    this.keySignatureColor = Colors.black,
    this.restColor = Colors.black,
    this.articulationColor = Colors.black, // VALOR PADRÃO
  });
}
