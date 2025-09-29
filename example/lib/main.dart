// example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

import 'examples/clefs_example.dart';
import 'examples/key_signatures_example.dart';
import 'examples/rhythmic_figures_example.dart';
import 'examples/accidentals_example.dart';
import 'examples/articulations_example.dart';
import 'examples/dots_and_ledgers_example.dart';
import 'examples/chords_example.dart';
import 'examples/beams_example.dart';
import 'examples/ornaments_example.dart';
import 'examples/dynamics_example.dart';
import 'examples/tempo_agogics_example.dart';
import 'examples/repeats_example.dart';
import 'examples/grace_notes_example.dart';
import 'examples/slurs_ties_example.dart';
import 'examples/tuplets_example.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fontLoader = FontLoader('Bravura');
  fontLoader.addFont(
      rootBundle.load('packages/smufl_renderer/assets/smufl/Bravura.otf'));
  await fontLoader.load();

  await SmuflMetadata().load();

  runApp(const MusicNotationApp());
}

class MusicNotationApp extends StatelessWidget {
  const MusicNotationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMuFL Renderer Exemplos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Claves',
    'Armaduras de Clave',
    'Figuras Rítmicas',
    'Acidentes',
    'Articulações',
    'Pontos e Linhas Suplementares',
    'Acordes',
    'Barras de Ligação (Beams)',
    'Ornamentos',
    'Dinâmicas',
    'Tempo e Agógica',
    'Repetições',
    'Apojaturas e Notas de Graça',
    'Ligaduras',
    'Quiálteras (Tuplets)',
  ];

  final List<Widget> _pages = const [
    ClefsExample(),
    KeySignaturesExample(),
    RhythmicFiguresExample(),
    AccidentalsExample(),
    ArticulationsExample(),
    DotsAndLedgersExample(),
    ChordsExample(),
    BeamsExample(),
    OrnamentsExample(),
    DynamicsExample(),
    TempoAgogicsExample(),
    RepeatsExample(),
    GraceNotesExample(),
    SlursTiesExample(),
    TupletsExample(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MUDANÇA AQUI: Adicionada a AppBar
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // O título muda com a seleção
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SMuFL Renderer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Exemplos por Família de Símbolos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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
      case 0:
        return const Icon(Icons.vpn_key_outlined); // Claves
      case 1:
        return const Icon(Icons.tag); // Armaduras
      case 2:
        return const Icon(Icons.hourglass_empty); // Figuras Rítmicas
      case 3:
        return const Icon(Icons.superscript_outlined); // Acidentes
      case 4:
        return const Icon(Icons.arrow_drop_down_circle_outlined); // Articulações
      case 5:
        return const Icon(Icons.more_horiz); // Pontos e Linhas
      case 6:
        return const Icon(Icons.view_module_outlined); // Acordes
      case 7:
        return const Icon(Icons.link); // Beams
      case 8:
        return const Icon(Icons.auto_awesome); // Ornamentos
      case 9:
        return const Icon(Icons.volume_up); // Dinâmicas
      case 10:
        return const Icon(Icons.speed); // Tempo e Agógica
      case 11:
        return const Icon(Icons.repeat); // Repetições
      case 12:
        return const Icon(Icons.scatter_plot); // Apojaturas
      case 13:
        return const Icon(Icons.trending_up); // Ligaduras
      default:
        return const Icon(Icons.music_note);
    }
  }
}
