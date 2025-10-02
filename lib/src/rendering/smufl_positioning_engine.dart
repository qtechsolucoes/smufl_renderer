import 'dart:convert';
import 'package:flutter/services.dart';
import '../smufl/smufl_metadata_loader.dart';

/// Classe responsável por calcular posicionamentos precisos usando metadados SMuFL
/// e regras de tipografia musical profissional.
///
/// Baseado em:
/// - Especificação SMuFL (w3c.github.io/smufl)
/// - Metadados da fonte Bravura
/// - "Behind Bars" de Elaine Gould
/// - "The Art of Music Engraving" de Ted Ross
class SMuFLPositioningEngine {
  late Map<String, dynamic> _bravuraMetadata;
  late Map<String, dynamic> _glyphsWithAnchors;
  late Map<String, dynamic> _engravingDefaults;
  late Map<String, dynamic> _glyphAdvanceWidths;
  late Map<String, dynamic> _glyphBBoxes;

  // NOVO: Referência ao metadata loader para acesso direto
  SmuflMetadata? _metadataLoader;

  // Constantes baseadas em padrões de tipografia musical
  static const double standardStemLength = 3.5; // espaços de pauta
  static const double minimumStemLength = 2.5;
  static const double stemExtensionPerBeam =
      0.5; // espaços adicionais por feixe extra
  static const double stemThickness = 0.12; // da fonte Bravura

  // Espaçamento de acidentes (baseado em práticas profissionais)
  static const double accidentalToNoteheadDistance = 0.16; // ~0.15-0.20 spaces
  static const double accidentalMinimumClearance = 0.08;

  // Ângulos de feixes (beam angles)
  // CORREÇÃO: Baseado em OSMD e Behind Bars
  // OSMD: beamSlopeMaxAngle = 10° (≈ 0.18 slope para 10 spaces = 1.8 spaces)
  // Para manter conservador: máximo 1.0 space (≈ 5.7° em 10 spaces)
  static const double minimumBeamSlant = 0.25; // spaces
  static const double maximumBeamSlant = 1.0; // spaces (corrigido de 1.75)
  static const double twoNoteBeamMaxSlant = 0.5; // spaces

  // Ornamentos e articulações
  static const double articulationToNoteDistance = 0.5; // spaces
  static const double ornamentToNoteDistance = 0.75; // spaces

  // Ligaduras e dinâmica
  static const double slurEndpointThickness = 0.1;
  static const double slurMidpointThickness = 0.22;
  static const double slurHeightFactor =
      0.25; // altura da curva como fração da largura

  // Gracia notes (appoggiaturas)
  static const double graceNoteScale = 0.6; // 60% do tamanho normal
  static const double graceNoteStemLength = 2.5; // espaços

  // Quiálteras (tuplets)
  static const double tupletBracketHeight =
      1.0; // spaces acima/abaixo das notas
  static const double tupletNumberDistance = 0.5; // spaces do bracket

  // NOVO: Construtor com metadata loader opcional
  SMuFLPositioningEngine({SmuflMetadata? metadataLoader}) {
    _metadataLoader = metadataLoader;
  }

  Future<void> initialize() async {
    final String jsonString = await rootBundle.loadString(
      'assets/smufl/bravura_metadata.json',
    );
    _bravuraMetadata = json.decode(jsonString);

    _glyphsWithAnchors = _bravuraMetadata['glyphsWithAnchors'] ?? {};
    _engravingDefaults = _bravuraMetadata['engravingDefaults'] ?? {};
    _glyphAdvanceWidths = _bravuraMetadata['glyphAdvanceWidths'] ?? {};
    _glyphBBoxes = _bravuraMetadata['glyphBBoxes'] ?? {};
  }

  /// Inicializa com SmuflMetadata já carregado (método alternativo)
  void initializeWithMetadata(SmuflMetadata metadata) {
    _metadataLoader = metadata;
  }

  /// Retorna o ponto de ancoragem stemUpSE para uma cabeça de nota
  /// (canto inferior direito de onde a haste para cima deve se conectar)
  /// Retorna coordenadas em STAFF SPACES (unidades SMuFL)
  Offset getStemUpAnchor(String noteheadGlyphName) {
    // CORREÇÃO: Usar metadata loader se disponível (método preferido)
    if (_metadataLoader != null) {
      final anchor = _metadataLoader!.getGlyphAnchor(
        noteheadGlyphName,
        'stemUpSE',
      );
      if (anchor != null) {
        return anchor; // Já em staff spaces
      }
    }

    // Fallback: Usar dados carregados diretamente (método legado)
    final glyphData = _glyphsWithAnchors[noteheadGlyphName];
    if (glyphData != null && glyphData['stemUpSE'] != null) {
      final List<dynamic> anchor = glyphData['stemUpSE'];
      return Offset(anchor[0].toDouble(), anchor[1].toDouble());
    }

    // Fallback final: noteheadBlack padrão do metadata Bravura
    // stemUpSE para noteheadBlack: [1.18, 0.168] conforme bravura_metadata.json
    return const Offset(1.18, 0.168);
  }

  /// Retorna o ponto de ancoragem stemDownNW para uma cabeça de nota
  /// (canto superior esquerdo de onde a haste para baixo deve se conectar)
  /// Retorna coordenadas em STAFF SPACES (unidades SMuFL)
  Offset getStemDownAnchor(String noteheadGlyphName) {
    // CORREÇÃO: Usar metadata loader se disponível (método preferido)
    if (_metadataLoader != null) {
      final anchor = _metadataLoader!.getGlyphAnchor(
        noteheadGlyphName,
        'stemDownNW',
      );
      if (anchor != null) {
        return anchor; // Já em staff spaces
      }
    }

    // Fallback: Usar dados carregados diretamente (método legado)
    final glyphData = _glyphsWithAnchors[noteheadGlyphName];
    if (glyphData != null && glyphData['stemDownNW'] != null) {
      final List<dynamic> anchor = glyphData['stemDownNW'];
      return Offset(anchor[0].toDouble(), anchor[1].toDouble());
    }

    // Fallback final: noteheadBlack padrão do metadata Bravura
    // stemDownNW para noteheadBlack: [0.0, -0.168] conforme bravura_metadata.json
    return const Offset(0.0, -0.168);
  }

  /// Retorna o ponto de ancoragem para flags (colcheias, semicolcheias, etc.)
  /// Flags são registradas com y=0 no final de uma haste de comprimento normal (3.5 spaces)
  /// Retorna coordenadas em STAFF SPACES (unidades SMuFL)
  Offset getFlagAnchor(String flagGlyphName) {
    String anchorName;

    // Para flags para cima, usar stemUpNW
    if (flagGlyphName.contains('Up')) {
      anchorName = 'stemUpNW';
    }
    // Para flags para baixo, usar stemDownSW
    else if (flagGlyphName.contains('Down')) {
      anchorName = 'stemDownSW';
    } else {
      return Offset.zero;
    }

    // CORREÇÃO: Usar metadata loader se disponível (método preferido)
    if (_metadataLoader != null) {
      final anchor = _metadataLoader!.getGlyphAnchor(flagGlyphName, anchorName);
      if (anchor != null) {
        return anchor; // Já em staff spaces
      }
    }

    // Fallback: Usar dados carregados diretamente (método legado)
    final glyphData = _glyphsWithAnchors[flagGlyphName];
    if (glyphData != null && glyphData[anchorName] != null) {
      final List<dynamic> anchor = glyphData[anchorName];
      return Offset(anchor[0].toDouble(), anchor[1].toDouble());
    }

    return Offset.zero;
  }

  /// Calcula o comprimento da haste baseado na posição da nota no pentagrama
  /// e no número de feixes
  double calculateStemLength({
    required int staffPosition,
    required bool stemUp,
    required int beamCount,
    bool isBeamed = false,
  }) {
    double length = standardStemLength;

    // Extender hastes para notas em linhas suplementares
    // Regra: hastes devem atingir a linha central (posição 6)
    if (stemUp && staffPosition < 6) {
      // Nota abaixo da linha central, haste para cima
      final double extensionNeeded = (6 - staffPosition) * 0.5;
      length = (standardStemLength + extensionNeeded).clamp(
        standardStemLength,
        5.0,
      );
    } else if (!stemUp && staffPosition > 6) {
      // Nota acima da linha central, haste para baixo
      final double extensionNeeded = (staffPosition - 6) * 0.5;
      length = (standardStemLength + extensionNeeded).clamp(
        standardStemLength,
        5.0,
      );
    }

    // Adicionar comprimento extra para múltiplos feixes
    if (!isBeamed && beamCount > 0) {
      length += (beamCount - 1) * stemExtensionPerBeam;
    }

    return length;
  }

  /// Calcula a posição correta de um acidente relativo à cabeça de nota
  /// Baseado em práticas de tipografia musical profissional
  /// Behind Bars: 0.16-0.20 staff spaces da cabeça
  /// Retorna coordenadas em STAFF SPACES (unidades SMuFL)
  Offset calculateAccidentalPosition({
    required String accidentalGlyph,
    required String noteheadGlyph,
    required double staffPosition,
  }) {
    // CORREÇÃO: Obter largura do acidente usando metadata loader se disponível
    double accidentalWidth;
    if (_metadataLoader != null) {
      accidentalWidth = _metadataLoader!.getGlyphWidth(accidentalGlyph);
      if (accidentalWidth == 0.0) {
        // Fallback se não encontrado
        accidentalWidth = 1.0;
      }
    } else {
      accidentalWidth = _glyphAdvanceWidths[accidentalGlyph]?.toDouble() ?? 1.0;
    }

    // Posição base: acidente à esquerda da nota com espaçamento padrão
    double xOffset = -(accidentalWidth + accidentalToNoteheadDistance);

    // CORREÇÃO: Usar cutOutNW da cabeça de nota se disponível para espaçamento mais preciso
    // Cut-outs permitem posicionar o acidente mais próximo quando há espaço vazio na cabeça
    Offset? cutOutNW;

    if (_metadataLoader != null) {
      cutOutNW = _metadataLoader!.getGlyphAnchor(noteheadGlyph, 'cutOutNW');
    } else {
      final noteheadData = _glyphsWithAnchors[noteheadGlyph];
      if (noteheadData != null && noteheadData['cutOutNW'] != null) {
        final List<dynamic> cutOut = noteheadData['cutOutNW'];
        cutOutNW = Offset(cutOut[0].toDouble(), cutOut[1].toDouble());
      }
    }

    if (cutOutNW != null) {
      // CORREÇÃO: Usar cutOutX diretamente (já está em staff spaces)
      // O cutOut define onde há espaço vazio na cabeça, permitindo aproximar o acidente
      // Se cutOutX é negativo, há espaço à esquerda
      if (cutOutNW.dx < 0) {
        // Há espaço vazio à esquerda da cabeça, podemos aproximar o acidente
        xOffset =
            -(accidentalWidth + accidentalToNoteheadDistance + cutOutNW.dx);
      }
    }

    // Y alinhado com a posição da nota no pentagrama
    final double yOffset = 0.0;

    return Offset(xOffset, yOffset);
  }

  /// Calcula o ângulo de um feixe (beam) baseado nas posições das notas
  /// Segue as regras de Ted Ross e Elaine Gould
  double calculateBeamAngle({
    required List<int> noteStaffPositions,
    required bool stemUp,
  }) {
    if (noteStaffPositions.length < 2) return 0.0;

    final int firstPos = noteStaffPositions.first;
    final int lastPos = noteStaffPositions.last;
    final int positionDifference = (lastPos - firstPos).abs();

    // Para apenas duas notas, limite o ângulo
    if (noteStaffPositions.length == 2) {
      final double slant = (positionDifference * 0.5).clamp(
        0.0,
        twoNoteBeamMaxSlant,
      );
      return stemUp
          ? (lastPos > firstPos ? slant : -slant)
          : (lastPos > firstPos ? -slant : slant);
    }

    // Para múltiplas notas, calcular ângulo baseado na diferença de posição
    double slant;
    if (positionDifference <= 1) {
      slant = minimumBeamSlant;
    } else if (positionDifference >= 7) {
      slant = maximumBeamSlant;
    } else {
      // Interpolação linear entre min e max
      slant =
          minimumBeamSlant +
          (positionDifference - 1) * (maximumBeamSlant - minimumBeamSlant) / 6;
    }

    slant = slant.clamp(minimumBeamSlant, maximumBeamSlant);

    return stemUp
        ? (lastPos > firstPos ? slant : -slant)
        : (lastPos > firstPos ? -slant : slant);
  }

  /// Calcula a altura ideal de um feixe na posição da primeira nota
  double calculateBeamHeight({
    required int staffPosition,
    required bool stemUp,
    required List<int> allStaffPositions,
  }) {
    if (stemUp) {
      // Encontrar a nota mais alta
      final int highestPosition = allStaffPositions.reduce(
        (a, b) => a < b ? a : b,
      );
      double height = standardStemLength;

      // Se a nota mais alta está acima da linha central, extender o feixe
      if (highestPosition < 6) {
        height += (6 - highestPosition) * 0.5;
      }

      return height;
    } else {
      // Encontrar a nota mais baixa
      final int lowestPosition = allStaffPositions.reduce(
        (a, b) => a > b ? a : b,
      );
      double height = standardStemLength;

      // Se a nota mais baixa está abaixo da linha central, extender o feixe
      if (lowestPosition > 6) {
        height += (lowestPosition - 6) * 0.5;
      }

      return height;
    }
  }

  /// Calcula a posição de um ornamento relativo à nota
  Offset calculateOrnamentPosition({
    required String ornamentGlyph,
    required int staffPosition,
    required bool hasAccidentalAbove,
  }) {
    final double ornamentHeight = _getGlyphHeight(ornamentGlyph);

    // Ornamentos vão acima da nota
    double yOffset = -ornamentToNoteDistance - (ornamentHeight * 0.5);

    // Se há acidente acima (como em trills), adicionar espaço extra
    if (hasAccidentalAbove) {
      yOffset -= 1.0;
    }

    // Se a nota está muito alta no pentagrama, ajustar posição
    if (staffPosition <= 2) {
      yOffset -= 0.5;
    }

    return Offset(0.0, yOffset);
  }

  /// Calcula a posição de uma articulação (staccato, accent, etc.)
  Offset calculateArticulationPosition({
    required String articulationGlyph,
    required int staffPosition,
    required bool stemUp,
    required bool hasBeam,
  }) {
    final double articulationHeight = _getGlyphHeight(articulationGlyph);

    double yOffset;
    if (stemUp) {
      // Articulação abaixo da nota
      yOffset = articulationToNoteDistance + (articulationHeight * 0.5);

      // Se a nota está na parte inferior do pentagrama, adicionar mais espaço
      if (staffPosition >= 10) {
        yOffset += 0.5;
      }
    } else {
      // Articulação acima da nota
      yOffset = -(articulationToNoteDistance + (articulationHeight * 0.5));

      // Se a nota está na parte superior do pentagrama, adicionar mais espaço
      if (staffPosition <= 2) {
        yOffset -= 0.5;
      }

      // Se tem feixe, adicionar espaço extra
      if (hasBeam) {
        yOffset -= 1.0;
      }
    }

    return Offset(0.0, yOffset);
  }

  /// Calcula pontos de controle para uma ligadura (slur) suave
  /// Retorna [startPoint, controlPoint1, controlPoint2, endPoint] para uma curva cúbica de Bézier
  List<Offset> calculateSlurControlPoints({
    required Offset startPosition,
    required Offset endPosition,
    required bool curveUp,
    required double intensity, // 0.0 a 1.0, quão curvada é a ligadura
  }) {
    final double dx = endPosition.dx - startPosition.dx;
    final double dy = endPosition.dy - startPosition.dy;
    final double distance = (dx * dx + dy * dy);

    // Altura da curva baseada na distância e intensidade
    final double curveHeight = (distance * slurHeightFactor * intensity).clamp(
      0.5,
      3.0,
    );
    final int direction = curveUp ? -1 : 1;

    // Pontos de controle para curva de Bézier cúbica
    // Baseado em práticas de tipografia musical: curvas assimétricas são mais naturais
    final Offset cp1 = Offset(
      startPosition.dx + dx * 0.25,
      startPosition.dy + dy * 0.25 + direction * curveHeight * 0.7,
    );

    final Offset cp2 = Offset(
      startPosition.dx + dx * 0.75,
      startPosition.dy + dy * 0.75 + direction * curveHeight * 0.9,
    );

    return [startPosition, cp1, cp2, endPosition];
  }

  /// Calcula a posição e tamanho de uma gracia note (appoggiatura)
  Map<String, dynamic> calculateGraceNoteLayout({
    required int staffPosition,
    required bool mainNoteStemUp,
  }) {
    return {
      'scale': graceNoteScale,
      'stemLength': graceNoteStemLength,
      // Grace notes geralmente vão antes da nota principal
      'xOffset': -1.5, // spaces antes da nota principal
      'yOffset': 0.0,
      // Grace notes com slash através da haste
      'hasSlash': true,
      'slashAngle': 45.0, // graus
    };
  }

  /// Calcula a posição e layout de uma quiáltera (tuplet)
  Map<String, dynamic> calculateTupletLayout({
    required List<Offset> notePositions,
    required bool stemsUp,
    required int tupletNumber,
  }) {
    if (notePositions.isEmpty) {
      return {'show': false};
    }

    final double firstX = notePositions.first.dx;
    final double lastX = notePositions.last.dx;
    final double centerX = (firstX + lastX) / 2;

    // Encontrar a nota mais alta/baixa para posicionar o bracket
    double extremeY;
    if (stemsUp) {
      extremeY = notePositions.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      extremeY -= (standardStemLength + tupletBracketHeight);
    } else {
      extremeY = notePositions.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
      extremeY += (standardStemLength + tupletBracketHeight);
    }

    return {
      'show': true,
      'bracketStart': Offset(firstX, extremeY),
      'bracketEnd': Offset(lastX, extremeY),
      'numberPosition': Offset(
        centerX,
        extremeY + (stemsUp ? -tupletNumberDistance : tupletNumberDistance),
      ),
      'number': tupletNumber,
      'showBracket': true, // Mostrar bracket se não houver feixe
    };
  }

  /// Calcula a largura de um glifo
  double getGlyphWidth(String glyphName) {
    return _glyphAdvanceWidths[glyphName]?.toDouble() ?? 1.0;
  }

  /// Calcula a altura de um glifo baseado em seu bounding box
  double _getGlyphHeight(String glyphName) {
    final bBox = _glyphBBoxes[glyphName];
    if (bBox == null || bBox['bBoxNE'] == null || bBox['bBoxSW'] == null) {
      return 1.0;
    }

    final double top = bBox['bBoxNE'][1].toDouble();
    final double bottom = bBox['bBoxSW'][1].toDouble();
    return (top - bottom).abs();
  }

  /// Retorna os padrões de gravação (engraving defaults) da fonte Bravura
  Map<String, dynamic> get engravingDefaults => _engravingDefaults;

  /// Obtém o optical center de um glifo (para centralização precisa)
  Offset? getOpticalCenter(String glyphName) {
    // CORREÇÃO: Usar metadata loader se disponível (método preferido)
    if (_metadataLoader != null) {
      final anchor = _metadataLoader!.getGlyphAnchor(
        glyphName,
        'opticalCenter',
      );
      if (anchor != null) {
        return anchor; // Já em staff spaces
      }
    }

    // Fallback: Usar dados carregados diretamente (método legado)
    // Só tenta acessar _glyphsWithAnchors se foi inicializado
    try {
      final glyphData = _glyphsWithAnchors[glyphName];
      if (glyphData != null && glyphData['opticalCenter'] != null) {
        final List<dynamic> center = glyphData['opticalCenter'];
        return Offset(center[0].toDouble(), center[1].toDouble());
      }
    } catch (_) {
      // _glyphsWithAnchors não foi inicializado, retornar null
    }

    return null;
  }

  /// Calcula a posição de sinais de repetição (repeat signs)
  Map<String, dynamic> calculateRepeatSignPosition({
    required String repeatGlyph,
    required double barlineX,
    required bool isStart, // true para início, false para fim
  }) {
    final double glyphWidth = getGlyphWidth(repeatGlyph);

    // Sinais de repetição são centralizados na barra
    final double xOffset = isStart
        ? barlineX +
              0.3 // Ligeiramente à direita da barra de início
        : barlineX -
              glyphWidth -
              0.3; // Ligeiramente à esquerda da barra de fim

    return {
      'x': xOffset,
      'y': 3.0, // Centro do pentagrama (posição 6 = linha central)
      'scale': 1.0, // Escala normal
    };
  }

  /// Calcula layout de barras de repetição com voltas (endings)
  Map<String, dynamic> calculateEndingLayout({
    required double startX,
    required double endX,
    required int endingNumber,
  }) {
    return {
      'lineStart': Offset(startX, -2.0), // Acima do pentagrama
      'lineEnd': Offset(endX, -2.0),
      'hookHeight': 1.0, // Altura do gancho vertical
      'numberPosition': Offset(startX + 0.5, -2.5),
      'number': endingNumber.toString(),
      'thickness': _engravingDefaults['repeatEndingLineThickness'] ?? 0.16,
    };
  }

  /// Calcula posicionamento de fórmula de compasso (time signature)
  Map<String, dynamic> calculateTimeSignaturePosition({
    required int numerator,
    required int denominator,
    required double xPosition,
  }) {
    // Fórmulas de compasso são centralizadas no pentagrama
    // Numerador na linha 2 (espaço superior), denominador na linha 4 (espaço inferior)
    return {
      'numeratorPosition': Offset(xPosition, 2.0),
      'denominatorPosition': Offset(xPosition, 4.0),
      'numerator': numerator,
      'denominator': denominator,
      'spacing': 0.2, // Espaço horizontal após a fórmula de compasso
    };
  }

  /// Calcula escala apropriada para sinais de dinâmica (evitar sobreposições)
  double calculateDynamicsScale(String dynamicGlyph) {
    // Dinâmicas geralmente são desenhadas em escala normal
    // mas podem ser reduzidas se houver sobreposições
    return 1.0;
  }

  /// Obtém cut-outs de um glifo (para cálculos de espaçamento avançados)
  Map<String, Offset> getGlyphCutOuts(String glyphName) {
    final glyphData = _glyphsWithAnchors[glyphName];
    if (glyphData == null) return {};

    final Map<String, Offset> cutOuts = {};

    for (final corner in ['cutOutNE', 'cutOutSE', 'cutOutSW', 'cutOutNW']) {
      if (glyphData[corner] != null) {
        final List<dynamic> coords = glyphData[corner];
        cutOuts[corner] = Offset(coords[0].toDouble(), coords[1].toDouble());
      }
    }

    return cutOuts;
  }
}
