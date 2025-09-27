// example/lib/examples/performance_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class PerformanceExample extends StatefulWidget {
  const PerformanceExample({super.key});

  @override
  State<PerformanceExample> createState() => _PerformanceExampleState();
}

class _PerformanceExampleState extends State<PerformanceExample> {
  Staff? _currentStaff;
  String _performanceInfo = 'Pronto para gerar';
  int _elementCount = 100;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateStaff();
  }

  void _generateStaff() {
    setState(() {
      _isGenerating = true;
      _performanceInfo = 'Gerando $_elementCount elementos...';
    });

    final stopwatch = Stopwatch()..start();

    final staff = Staff();
    int elementsAdded = 0;
    int measureCount = 1;
    Measure currentMeasure = Measure();

    // Adiciona clave, armadura e fórmula de compasso no primeiro compasso
    if (elementsAdded == 0) {
      currentMeasure.add(Clef(type: 'g'));
      currentMeasure.add(KeySignature(0));
      currentMeasure.add(TimeSignature(numerator: 4, denominator: 4));
      elementsAdded += 3;
    }

    // Gera elementos musicais
    while (elementsAdded < _elementCount) {
      final elementType = elementsAdded % 8;

      switch (elementType) {
        case 0:
        case 1:
        case 2:
        case 3:
          // Notas (50% dos elementos)
          final pitchSteps = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
          final durations = [
            DurationType.quarter,
            DurationType.eighth,
            DurationType.half,
            DurationType.sixteenth,
          ];
          final octaves = [3, 4, 5];

          final note = Note(
            pitch: Pitch(
              step: pitchSteps[elementsAdded % pitchSteps.length],
              octave: octaves[elementsAdded % octaves.length],
            ),
            duration: Duration(durations[elementsAdded % durations.length]),
            articulations: elementsAdded % 5 == 0
                ? [ArticulationType.staccato]
                : [],
          );
          currentMeasure.add(note);
          break;

        case 4:
          // Pausas (12.5% dos elementos)
          currentMeasure.add(Rest(
            duration: const Duration(DurationType.quarter),
          ));
          break;

        case 5:
          // Acordes (12.5% dos elementos)
          currentMeasure.add(Chord(
            notes: [
              Note(
                pitch: const Pitch(step: 'C', octave: 4),
                duration: const Duration(DurationType.quarter),
              ),
              Note(
                pitch: const Pitch(step: 'E', octave: 4),
                duration: const Duration(DurationType.quarter),
              ),
              Note(
                pitch: const Pitch(step: 'G', octave: 4),
                duration: const Duration(DurationType.quarter),
              ),
            ],
            duration: const Duration(DurationType.quarter),
          ));
          break;

        case 6:
          // Dinâmicas (12.5% dos elementos)
          final dynamics = [
            DynamicType.piano,
            DynamicType.forte,
            DynamicType.mezzoForte,
            DynamicType.pianissimo,
            DynamicType.fortissimo,
          ];
          currentMeasure.add(Dynamic(
            type: dynamics[elementsAdded % dynamics.length],
          ));
          break;

        case 7:
          // Ornamentos (12.5% dos elementos)
          final ornaments = [
            OrnamentType.trill,
            OrnamentType.turn,
            OrnamentType.mordent,
            OrnamentType.trill,
          ];
          currentMeasure.add(Ornament(
            type: ornaments[elementsAdded % ornaments.length],
            above: true,
          ));
          break;
      }

      elementsAdded++;

      // A cada 12 elementos, cria um novo compasso
      if (elementsAdded % 12 == 0) {
        staff.add(currentMeasure);
        currentMeasure = Measure();
        measureCount++;
      }
    }

    // Adiciona o último compasso se não estiver vazio
    if (currentMeasure.elements.isNotEmpty) {
      staff.add(currentMeasure);
    }

    stopwatch.stop();

    setState(() {
      _currentStaff = staff;
      _isGenerating = false;
      _performanceInfo =
          'Gerado: $_elementCount elementos em $measureCount compassos\n'
          'Tempo: ${stopwatch.elapsedMilliseconds}ms\n'
          'Velocidade: ${(_elementCount / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(0)} elementos/segundo';
    });
  }

  void _changeElementCount(int newCount) {
    setState(() {
      _elementCount = newCount;
    });
    _generateStaff();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Teste de Performance',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teste a performance da renderização com diferentes quantidades de elementos musicais.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Controles de quantidade
                  Text(
                    'Quantidade de elementos: $_elementCount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [50, 100, 200, 500, 1000].map((count) {
                      return ElevatedButton(
                        onPressed: _isGenerating
                            ? null
                            : () => _changeElementCount(count),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _elementCount == count
                              ? Colors.blue[800]
                              : Colors.grey[300],
                          foregroundColor: _elementCount == count
                              ? Colors.white
                              : Colors.black,
                        ),
                        child: Text('$count'),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Informações de performance
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _performanceInfo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_isGenerating)
                    const LinearProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _generateStaff,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerar'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Área de renderização
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _currentStaff == null
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        height: 1000, // Altura suficiente para múltiplos sistemas
                        child: MusicScore(
                          staff: _currentStaff!,
                          theme: MusicScoreTheme.standard(),
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