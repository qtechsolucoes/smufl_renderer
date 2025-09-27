// example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smufl_renderer/smufl_renderer.dart';
import 'examples/basic_example.dart';
import 'examples/advanced_example.dart';
import 'examples/complex_example.dart';
import 'examples/performance_example.dart';
import 'examples/microtonal_example.dart';
import 'examples/percussion_example.dart';
import 'examples/contemporary_example.dart';
import 'examples/jazz_example.dart';
import 'examples/precision_test_example.dart';
import 'examples/debug_visual_example.dart';
import 'examples/simple_debug_example.dart';

// 2. A função main agora é assíncrona para esperar o carregamento da fonte
Future<void> main() async {
  // 3. Garantir que o Flutter está inicializado antes de carregar a fonte
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Carregar a fonte Bravura programaticamente
  final fontLoader = FontLoader('Bravura');
  // O caminho usa 'packages/smufl_renderer' porque a app de exemplo
  // está a aceder a um recurso da biblioteca.
  fontLoader.addFont(
      rootBundle.load('packages/smufl_renderer/assets/smufl/Bravura.otf'));
  await fontLoader.load();

  // 5. Carregar os metadados da fonte SMuFL
  await SmuflMetadata().load();

  // 6. Correr a aplicação APENAS DEPOIS de a fonte e metadados estarem carregados
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMuFL Renderer - Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _examples = [
    const BasicExample(),
    const AdvancedExample(),
    const ComplexExample(),
    const MicrotonalExample(),
    const PercussionExample(),
    const ContemporaryExample(),
    const JazzExample(),
    const PerformanceExample(),
    const PrecisionTestExample(),
    const DebugVisualExample(),
    const SimpleDebugExample(),
  ];

  final List<String> _titles = [
    'Exemplo Básico',
    'Exemplo Avançado',
    'Exemplo Complexo',
    'Microtonal',
    'Percussão',
    'Contemporâneo',
    'Jazz',
    'Performance',
    'Teste de Precisão',
    'Debug Visual',
    'Debug Simples',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue[800],
        elevation: 4,
      ),
      body: _examples[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[800],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMuFL Renderer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Exemplos e Testes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_titles.length, (index) {
              return ListTile(
                leading: _getIconForIndex(index),
                title: Text(_titles[index]),
                selected: _selectedIndex == index,
                selectedTileColor: Colors.blue[50],
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Icon _getIconForIndex(int index) {
    switch (index) {
      case 0: return const Icon(Icons.music_note);
      case 1: return const Icon(Icons.star);
      case 2: return const Icon(Icons.auto_awesome);
      case 3: return const Icon(Icons.tune);
      case 4: return const Icon(Icons.sports_baseball);
      case 5: return const Icon(Icons.art_track);
      case 6: return const Icon(Icons.piano);
      case 7: return const Icon(Icons.speed);
      case 8: return const Icon(Icons.precision_manufacturing);
      case 9: return const Icon(Icons.bug_report);
      case 10: return const Icon(Icons.visibility);
      default: return const Icon(Icons.circle);
    }
  }
}
