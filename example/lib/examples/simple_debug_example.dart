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
            const SizedBox(height: 20),
            _buildTest4(),
            const SizedBox(height: 20),
            _buildTest5(),
            const SizedBox(height: 20),
            _buildTest6(),
            const SizedBox(height: 20),
            _buildTest7(),
            const SizedBox(height: 20),
            _buildTest8(),
          ],
        ),
      ),
    );
  }

  Widget _buildTest1() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));
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

    measure.add(Clef(clefType: ClefType.treble));
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

    measure.add(Clef(clefType: ClefType.treble));
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

  Widget _buildTest4() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));

    // Teste de todas as figuras com bandeirolas
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 4), // Colcheia
      duration: const Duration(DurationType.eighth),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'A', octave: 4), // Semicolcheia
      duration: const Duration(DurationType.sixteenth),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'B', octave: 4), // Fusa
      duration: const Duration(DurationType.thirtySecond),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 5), // Semifusa
      duration: const Duration(DurationType.sixtyFourth),
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 5), // 128th
      duration: const Duration(DurationType.oneHundredTwentyEighth),
    ));

    staff.add(measure);

    return _buildTestCard(
      'TESTE 4: Notas com Bandeirolas',
      'Sequência: colcheia, semicolcheia, fusa, semifusa, 1/128. Cada uma deve ter o número correto de bandeirolas',
      staff,
    );
  }

  Widget _buildTest5() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));

    // Teste de notas com beams (barras de ligadura)
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.start, // Inicia o beam
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.end, // Termina o beam
    ));

    // Segundo grupo de beams com semicolcheias
    measure.add(Note(
      pitch: const Pitch(step: 'B', octave: 4),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.start,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.inner,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'D', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.inner,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'E', octave: 5),
      duration: const Duration(DurationType.sixteenth),
      beam: BeamType.end,
    ));

    staff.add(measure);

    return _buildTestCard(
      'TESTE 5: Notas com Barras (Beams)',
      'Primeiro grupo: 2 colcheias ligadas. Segundo grupo: 4 semicolcheias ligadas com 2 barras',
      staff,
    );
  }

  Widget _buildTest6() {
    final staff = Staff();
    final measure = Measure();

    measure.add(Clef(clefType: ClefType.treble));

    // Teste de quiáltera (triplet) - 3 notas no tempo de 2
    final tripletNotes = [
      Note(
        pitch: const Pitch(step: 'G', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),
      Note(
        pitch: const Pitch(step: 'A', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),
      Note(
        pitch: const Pitch(step: 'B', octave: 4),
        duration: const Duration(DurationType.eighth),
      ),
    ];

    final triplet = Tuplet(
      actualNotes: 3,
      normalNotes: 2,
      elements: tripletNotes,
      showBracket: true,
      showNumber: true,
    );

    measure.add(triplet);

    // Quiáltera mais complexa: quintuplet (5 no tempo de 4)
    final quintupletNotes = [
      Note(
        pitch: const Pitch(step: 'C', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'D', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'E', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'F', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
      Note(
        pitch: const Pitch(step: 'G', octave: 5),
        duration: const Duration(DurationType.sixteenth),
      ),
    ];

    final quintuplet = Tuplet(
      actualNotes: 5,
      normalNotes: 4,
      elements: quintupletNotes,
      showBracket: true,
      showNumber: true,
    );

    measure.add(quintuplet);

    staff.add(measure);

    return _buildTestCard(
      'TESTE 6: Quiálteras (Tuplets)',
      'Primeira: triplet (3 colcheias no tempo de 2). Segunda: quintuplet (5 semicolcheias no tempo de 4)',
      staff,
    );
  }

  Widget _buildTest7() {
    final staff = Staff();
    final measure = Measure();

    // Teste combinado: armadura, fórmula de compasso, notas com acidentes e articulações
    measure.add(Clef(clefType: ClefType.treble));
    measure.add(KeySignature(2)); // F# e C#
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Nota com acidente e articulação
    measure.add(Note(
      pitch: const Pitch(step: 'F', octave: 4, alter: 1.0, accidentalType: AccidentalType.sharp),
      duration: const Duration(DurationType.quarter),
      articulations: [ArticulationType.staccato],
    ));

    // Grupo de colcheias com beam
    measure.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.start,
    ));
    measure.add(Note(
      pitch: const Pitch(step: 'A', octave: 4),
      duration: const Duration(DurationType.eighth),
      beam: BeamType.end,
      articulations: [ArticulationType.accent],
    ));

    // Pausa
    measure.add(Rest(duration: const Duration(DurationType.quarter)));

    staff.add(measure);

    return _buildTestCard(
      'TESTE 7: Exemplo Combinado',
      'Armadura (F#, C#), fórmula 4/4, nota com sustenido e staccato, colcheias ligadas com acento, pausa de semínima',
      staff,
    );
  }

  Widget _buildTest8() {
    final staff = Staff();

    // Teste de múltiplas claves em compassos diferentes
    final measure1 = Measure();
    measure1.add(Clef(clefType: ClefType.treble));
    measure1.add(Note(
      pitch: const Pitch(step: 'G', octave: 4),
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure1);

    final measure2 = Measure();
    measure2.add(Clef(clefType: ClefType.bass));
    measure2.add(Note(
      pitch: const Pitch(step: 'F', octave: 3), // Fá na 4ª linha da clave de fá
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure2);

    final measure3 = Measure();
    measure3.add(Clef(clefType: ClefType.alto));
    measure3.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // Dó na 3ª linha da clave de dó
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure3);

    final measure4 = Measure();
    measure4.add(Clef(clefType: ClefType.tenor));
    measure4.add(Note(
      pitch: const Pitch(step: 'C', octave: 4), // Dó na 4ª linha da clave de tenor
      duration: const Duration(DurationType.whole),
    ));
    staff.add(measure4);

    return _buildTestCard(
      'TESTE 8: Múltiplas Claves',
      'Sol (G4), Fá (F3), Alto/Dó (C4), Tenor/Dó (C4). Cada nota deve estar na linha de referência de sua clave',
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
                theme: const MusicScoreTheme(
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