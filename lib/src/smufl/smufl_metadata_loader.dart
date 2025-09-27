// lib/src/smufl/smufl_metadata_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SmuflMetadata {
  // Usaremos um Singleton para garantir que os dados sejam carregados apenas uma vez.
  static final SmuflMetadata _instance = SmuflMetadata._internal();
  factory SmuflMetadata() => _instance;

  SmuflMetadata._internal();

  Map<String, dynamic>? _metadata;
  Map<String, dynamic>? _glyphnames;
  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) return;

    final metadataString = await rootBundle.loadString(
      'packages/smufl_renderer/assets/smufl/bravura_metadata.json',
    );
    _metadata = json.decode(metadataString);

    final glyphnamesString = await rootBundle.loadString(
      'packages/smufl_renderer/assets/smufl/glyphnames.json',
    );
    _glyphnames = json.decode(glyphnamesString);

    _isLoaded = true;
  }

  // Função para obter o caractere Unicode a partir do nome do glifo
  String getCodepoint(String glyphName) {
    if (!_isLoaded || _glyphnames == null) return '';
    return _glyphnames![glyphName]?['codepoint'] ?? '';
  }

  // Funções para obter dados de desenho
  double getEngravingDefault(String key) {
    if (!_isLoaded || _metadata == null) return 0.0;
    return (_metadata!['engravingDefaults'][key] as num).toDouble();
  }

  // CORREÇÃO 1: Getter que estava faltando
  bool get isNotLoaded => !_isLoaded;

  // CORREÇÃO 2: Método que estava faltando
  Map<String, List<double>>? getGlyphBBox(String glyphName) {
    if (isNotLoaded || _metadata == null) return null;
    if (!_metadata!['glyphBBoxes'].containsKey(glyphName)) return null;

    return (_metadata!['glyphBBoxes'][glyphName] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(
        key,
        (value as List).map((e) => (e as num).toDouble()).toList(),
      ),
    );
  }
}
