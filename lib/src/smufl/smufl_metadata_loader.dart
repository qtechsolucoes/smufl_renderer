// lib/src/smufl/smufl_metadata_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'smufl_coordinates.dart';

class SmuflMetadata {
  // Usaremos um Singleton para garantir que os dados sejam carregados apenas uma vez.
  static final SmuflMetadata _instance = SmuflMetadata._internal();
  factory SmuflMetadata() => _instance;

  SmuflMetadata._internal();

  Map<String, dynamic>? _metadata;
  Map<String, dynamic>? _glyphnames;
  final Map<String, SmuflGlyphInfo> _glyphInfoCache = {};
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
    final codepointStr = _glyphnames![glyphName]?['codepoint'] as String?;
    if (codepointStr == null || codepointStr.isEmpty) return '';

    // Converte "U+E050" para o caractere Unicode real
    if (codepointStr.startsWith('U+')) {
      final hexValue = codepointStr.substring(2);
      try {
        final codeUnit = int.parse(hexValue, radix: 16);
        return String.fromCharCode(codeUnit);
      } catch (e) {
        return '';
      }
    }
    return codepointStr;
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

  /// Obtém informações completas de um glifo, incluindo bounding box e anchors
  SmuflGlyphInfo? getGlyphInfo(String glyphName) {
    // Verifica cache primeiro
    if (_glyphInfoCache.containsKey(glyphName)) {
      return _glyphInfoCache[glyphName];
    }

    if (!_isLoaded || _glyphnames == null) return null;

    final glyphData = _glyphnames![glyphName] as Map<String, dynamic>?;
    if (glyphData == null) return null;

    // Cria informações básicas do glifo
    final codepoint = glyphData['codepoint'] as String? ?? '';
    final description = glyphData['description'] as String? ?? '';

    // Obtém bounding box se disponível
    GlyphBoundingBox? boundingBox;
    if (_metadata != null && _metadata!['glyphBBoxes'] != null) {
      final bboxData = _metadata!['glyphBBoxes'][glyphName] as Map<String, dynamic>?;
      if (bboxData != null) {
        boundingBox = GlyphBoundingBox.fromMetadata(bboxData);
      }
    }

    // Obtém anchors se disponível
    GlyphAnchors? anchors;
    if (_metadata != null && _metadata!['glyphsWithAnchors'] != null) {
      final anchorsData = _metadata!['glyphsWithAnchors'][glyphName] as Map<String, dynamic>?;
      if (anchorsData != null) {
        anchors = GlyphAnchors.fromMetadata(anchorsData);
      }
    }

    final glyphInfo = SmuflGlyphInfo(
      name: glyphName,
      codepoint: codepoint,
      description: description,
      boundingBox: boundingBox,
      anchors: anchors,
    );

    // Cache para uso futuro
    _glyphInfoCache[glyphName] = glyphInfo;
    return glyphInfo;
  }

  /// Obtém bounding box de um glifo como objeto
  GlyphBoundingBox? getGlyphBoundingBox(String glyphName) {
    return getGlyphInfo(glyphName)?.boundingBox;
  }

  /// Obtém anchors de um glifo
  GlyphAnchors? getGlyphAnchors(String glyphName) {
    return getGlyphInfo(glyphName)?.anchors;
  }

  /// Obtém largura de um glifo em unidades SMuFL
  double getGlyphWidth(String glyphName) {
    return getGlyphBoundingBox(glyphName)?.width ?? 0.0;
  }

  /// Obtém altura de um glifo em unidades SMuFL
  double getGlyphHeight(String glyphName) {
    return getGlyphBoundingBox(glyphName)?.height ?? 0.0;
  }

  /// Obtém largura de um glifo em pixels
  double getGlyphWidthInPixels(String glyphName, double staffSpace) {
    return getGlyphBoundingBox(glyphName)?.widthInPixels(staffSpace) ?? 0.0;
  }

  /// Obtém altura de um glifo em pixels
  double getGlyphHeightInPixels(String glyphName, double staffSpace) {
    return getGlyphBoundingBox(glyphName)?.heightInPixels(staffSpace) ?? 0.0;
  }

  /// Verifica se um glifo existe na fonte
  bool hasGlyph(String glyphName) {
    return _glyphnames?.containsKey(glyphName) ?? false;
  }

  /// Obtém todos os nomes de glifos disponíveis
  List<String> getAllGlyphNames() {
    return _glyphnames?.keys.toList() ?? [];
  }

  /// Obtém glifos por categoria
  List<String> getGlyphsByCategory(String category) {
    final allGlyphs = getAllGlyphNames();
    return allGlyphs.where((glyph) => glyph.startsWith(category)).toList();
  }

  /// Busca glifos por padrão
  List<String> searchGlyphs(String pattern) {
    final allGlyphs = getAllGlyphNames();
    final regex = RegExp(pattern, caseSensitive: false);
    return allGlyphs.where((glyph) => regex.hasMatch(glyph)).toList();
  }

  /// Obtém informações de classes de glifos (se disponível nos metadados)
  Map<String, List<String>>? getGlyphClasses() {
    if (!_isLoaded || _metadata == null) return null;
    return _metadata!['glyphClasses'] as Map<String, List<String>>?;
  }

  /// Obtém conjuntos estilísticos (se disponível nos metadados)
  Map<String, dynamic>? getStylisticSets() {
    if (!_isLoaded || _metadata == null) return null;
    return _metadata!['stylisticSets'] as Map<String, dynamic>?;
  }

  /// Limpa o cache de glifos
  void clearCache() {
    _glyphInfoCache.clear();
  }
}
