// example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'examples/basic_example.dart';
import 'examples/advanced_example.dart';
import 'examples/complex_example.dart';
import 'examples/performance_example.dart';
import 'examples/microtonal_example.dart';
import 'examples/percussion_example.dart';
import 'examples/contemporary_example.dart';
import 'examples/jazz_example.dart';

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

  // 5. Correr a aplicação APENAS DEPOIS de a fonte estar carregada
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Básico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Avançado',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Complexo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: 'Performance',
          ),
        ],
      ),
    );
  }
}
