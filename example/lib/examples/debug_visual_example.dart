// example/lib/examples/debug_visual_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo para debug visual com guias e medidas para ajuste fino
class DebugVisualExample extends StatefulWidget {
  const DebugVisualExample({super.key});

  @override
  State<DebugVisualExample> createState() => _DebugVisualExampleState();
}

class _DebugVisualExampleState extends State<DebugVisualExample> {
  bool showGuides = true;
  bool showMeasurements = true;
  bool showBoundingBoxes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Visual - Ajuste de Precisão'),
        backgroundColor: Colors.red.shade100,
        actions: [
          IconButton(
            icon: Icon(showGuides ? Icons.grid_on : Icons.grid_off),
            onPressed: () => setState(() => showGuides = !showGuides),
            tooltip: 'Toggle Guias',
          ),
          IconButton(
            icon: Icon(showMeasurements ? Icons.straighten : Icons.straighten_outlined),
            onPressed: () => setState(() => showMeasurements = !showMeasurements),
            tooltip: 'Toggle Medidas',
          ),
          IconButton(
            icon: Icon(showBoundingBoxes ? Icons.crop_free : Icons.crop_free_outlined),
            onPressed: () => setState(() => showBoundingBoxes = !showBoundingBoxes),
            tooltip: 'Toggle Bounding Boxes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControlPanel(),
            const SizedBox(height: 20),
            _buildClefAlignmentTest(),
            const SizedBox(height: 30),
            _buildNotePositionTest(),
            const SizedBox(height: 30),
            _buildKeySignatureTest(),
            const SizedBox(height: 30),
            _buildCompleteTest(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controles de Debug',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use os botões no AppBar para alternar:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Guias: Linhas de referência e grid'),
            const Text('• Medidas: Distâncias e espaçamentos'),
            const Text('• Bounding Boxes: Contornos dos glifos'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '🎯 Objetivo: Verificar alinhamento preciso de claves, '
                'posicionamento de notas e espaçamento correto.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClefAlignmentTest() {
    final staff = Staff();

    // Teste de alinhamento das claves
    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4), // Deve estar exatamente na 2ª linha
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure1);

    final measure2 = Measure();
    measure2.add(Clef(type: 'f'));
    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 3), // Deve estar exatamente na 4ª linha
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure2);

    final measure3 = Measure();
    measure3.add(Clef(type: 'c'));
    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // Deve estar exatamente na 3ª linha
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure3);

    return _buildDebugSection(
      title: '1. Teste de Alinhamento de Claves',
      description: 'Claves devem estar alinhadas com suas linhas de referência:',
      details: [
        '• Clave de Sol: espiral na 2ª linha (G4)',
        '• Clave de Fá: pontos na 4ª linha (F3)',
        '• Clave de Dó: centro na 3ª linha (C4)',
      ],
      staff: staff,
    );
  }

  Widget _buildNotePositionTest() {
    final staff = Staff();

    final measure = Measure();
    measure.add(Clef(type: 'g'));

    // Notas em diferentes posições para testar hastes
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 6), // Muito aguda - haste para baixo
      duration: const Duration(DurationType.quarter),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'B', octave: 4), // Linha central - haste para cima
      duration: const Duration(DurationType.quarter),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // Linha suplementar - haste para cima
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure);

    return _buildDebugSection(
      title: '2. Teste de Posicionamento de Notas',
      description: 'Verificar direção das hastes e linhas suplementares:',
      details: [
        '• C6: haste para baixo (nota aguda)',
        '• B4: haste para cima (linha central)',
        '• C4: haste para cima + linha suplementar',
      ],
      staff: staff,
    );
  }

  Widget _buildKeySignatureTest() {
    final staff = Staff();

    final measure1 = Measure();
    measure1.add(Clef(type: 'g'));
    measure1.add(KeySignature(3)); // 3 sustenidos
    measure1.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure1);

    final measure2 = Measure();
    measure2.add(KeySignature(-2)); // 2 bemóis
    measure2.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));
    staff.add(measure2);

    return _buildDebugSection(
      title: '3. Teste de Armaduras de Clave',
      description: 'Verificar espaçamento e posicionamento de acidentes:',
      details: [
        '• 3 sustenidos: F#, C#, G# com espaçamento correto',
        '• 2 bemóis: B♭, E♭ nas posições corretas',
      ],
      staff: staff,
    );
  }

  Widget _buildCompleteTest() {
    final staff = Staff();

    final measure = Measure();
    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(1));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Teste completo com vários elementos
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.quarter),
      articulations: const [ArticulationType.staccato],
    ));

    final chord = Chord(
      notes: [
        Note(
          pitch: const Pitch(step: 'C', octave: 4),
          duration: const Duration(DurationType.half),
        ),
        Note(
          pitch: const Pitch(step: 'E', octave: 4),
          duration: const Duration(DurationType.half),
        ),
      ],
      duration: const Duration(DurationType.half),
    );
    measure.add(chord);

    measure.add(Note(
      pitch: Pitch.withAccidental(
        step: 'F',
        octave: 5,
        accidentalType: AccidentalType.sharp,
      ),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return _buildDebugSection(
      title: '4. Teste Completo Integrado',
      description: 'Combinação de todos os elementos:',
      details: [
        '• Claves, armaduras, compassos',
        '• Notas com hastes, acidentes, articulações',
        '• Acordes com espaçamento correto',
      ],
      staff: staff,
    );
  }

  Widget _buildDebugSection({
    required String title,
    required String description,
    required List<String> details,
    required Staff staff,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            )),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Partitura
                  MusicScore(
                    staff: staff,
                    theme: MusicScoreTheme(
                      staffLineColor: Colors.black,
                      clefColor: Colors.blue.shade800,
                      noteheadColor: Colors.black,
                      stemColor: Colors.black,
                      keySignatureColor: Colors.purple.shade700,
                      timeSignatureColor: Colors.green.shade700,
                      accidentalColor: Colors.red.shade700,
                      articulationColor: Colors.orange.shade700,
                      restColor: Colors.grey.shade600,
                      barlineColor: Colors.black,
                      showLedgerLines: true,
                    ),
                  ),

                  // Overlay de debug
                  if (showGuides || showMeasurements || showBoundingBoxes)
                    CustomPaint(
                      size: Size.infinite,
                      painter: DebugOverlayPainter(
                        showGuides: showGuides,
                        showMeasurements: showMeasurements,
                        showBoundingBoxes: showBoundingBoxes,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para overlay de debug visual
class DebugOverlayPainter extends CustomPainter {
  final bool showGuides;
  final bool showMeasurements;
  final bool showBoundingBoxes;

  DebugOverlayPainter({
    required this.showGuides,
    required this.showMeasurements,
    required this.showBoundingBoxes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuides) {
      _drawGuides(canvas, size);
    }

    if (showMeasurements) {
      _drawMeasurements(canvas, size);
    }

    if (showBoundingBoxes) {
      _drawBoundingBoxes(canvas, size);
    }
  }

  void _drawGuides(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Grid horizontal (linhas da pauta simuladas)
    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.3 + (i * size.height * 0.08);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Linhas verticais de referência
    paint.color = Colors.blue.withValues(alpha: 0.3);
    for (int i = 1; i < 8; i++) {
      final x = size.width * (i / 8);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawMeasurements(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Medidas de espaçamento entre elementos
    final staffSpace = size.height * 0.08;

    textPainter.text = TextSpan(
      text: '${staffSpace.toStringAsFixed(1)}px',
      style: const TextStyle(
        color: Colors.green,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 50, 10));
  }

  void _drawBoundingBoxes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Simular bounding boxes em posições típicas
    final boxes = [
      Rect.fromLTWH(size.width * 0.1, size.height * 0.25, 30, 60), // Clave
      Rect.fromLTWH(size.width * 0.3, size.height * 0.45, 20, 25), // Nota
      Rect.fromLTWH(size.width * 0.5, size.height * 0.35, 20, 25), // Nota
    ];

    for (final box in boxes) {
      canvas.drawRect(box, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}