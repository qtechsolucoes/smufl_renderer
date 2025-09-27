// example/lib/examples/simple_debug_example.dart

import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Exemplo super simples para debug visual direto
class SimpleDebugExample extends StatelessWidget {
  const SimpleDebugExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Simples - Veja e Relate'),
        backgroundColor: Colors.green.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 INSTRUÇÃO PARA DEBUGGING',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Por favor, execute este exemplo e me conte EXATAMENTE o que você vê:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text('1. A clave de sol está alinhada com a 2ª linha?'),
                    Text('2. As hastes das notas estão na posição correta?'),
                    Text('3. Os sustenidos da armadura estão bem espaçados?'),
                    Text('4. As linhas suplementares aparecem corretamente?'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTest1(),
            const SizedBox(height: 20),
            _buildTest2(),
            const SizedBox(height: 20),
            _buildTest3(),
          ],
        ),
      ),
    );
  }

  Widget _buildTest1() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 4), // Deve estar na 2ª linha
      duration: const Duration(DurationType.whole),
    ));

    staff.add(measure);

    return _buildTestCard(
      'TESTE 1: Alinhamento da Clave de Sol',
      'A nota G4 deve estar EXATAMENTE na mesma linha que o centro da espiral da clave de sol',
      staff,
    );
  }

  Widget _buildTest2() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 5), // Acima da pauta - haste para baixo
      duration: const Duration(DurationType.quarter),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // Abaixo da pauta - haste para cima
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return _buildTestCard(
      'TESTE 2: Direção das Hastes',
      'C5 (nota alta) = haste para BAIXO, C4 (nota baixa) = haste para CIMA',
      staff,
    );
  }

  Widget _buildTest3() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(2)); // F# e C#
    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return _buildTestCard(
      'TESTE 3: Armadura de Clave',
      'Deve haver 2 sustenidos (F# e C#) bem espaçados, sem sobreposição',
      staff,
    );
  }

  Widget _buildTestCard(String title, String description, Staff staff) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: MusicScore(
                staff: staff,
                theme: MusicScoreTheme(
                  staffLineColor: Colors.black,
                  clefColor: Colors.red, // Vermelho para destacar
                  noteheadColor: Colors.blue, // Azul para destacar
                  stemColor: Colors.green, // Verde para destacar
                  keySignatureColor: Colors.purple,
                  timeSignatureColor: Colors.orange,
                  showLedgerLines: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}