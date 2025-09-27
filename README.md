# SMuFL Renderer - A Biblioteca de Notação Musical Mais Avançada para Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.32.8+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.8.1+-blue.svg)](https://dart.dev/)
[![SMuFL](https://img.shields.io/badge/SMuFL-1.40-green.svg)](https://w3c.github.io/smufl/latest/)

## 🎵 Sobre

O **SMuFL Renderer** é a biblioteca de notação musical mais completa e poderosa disponível para Flutter. Com suporte nativo ao padrão **SMuFL (Standard Music Font Layout)**, oferece renderização profissional de partituras com todos os **2932 símbolos** da fonte Bravura.

## ✨ Características Principais

### 🎼 **Notação Completa**
- **2932 símbolos SMuFL** da fonte Bravura
- **Microtons** e acidentes avançados (quartos de tom, sagittal, etc.)
- **Ornamentos completos** (trinados, mordentes, grupetos, apoggiaturas)
- **Dinâmicas profissionais** (pppppp a ffffff, crescendos, sforzandos)
- **Articulações** (staccato, accent, tenuto, marcato, etc.)

### 🎹 **Elementos Avançados**
- **Acordes complexos** com múltiplas vozes
- **Quiálteras** (3:2, 5:4, 7:4, etc.)
- **Ligaduras** (slurs) e **ligaduras de valor** (ties) avançadas
- **Respirações** e **cesuras**
- **Harmônicos** naturais e artificiais
- **Textos musicais** (letra, acordes, expressões)

### 🎸 **Tablatura**
- **Suporte completo** para instrumentos de corda
- **Técnicas especiais** (bend, slide, hammer-on, pull-off, tapping)
- **Dedilhado** e **fingering**
- **Acordes de tablatura**
- **Afinações personalizadas**

### 🎨 **Temas e Personalização**
- **3 temas prontos**: Padrão, Escuro, Colorido
- **Cores personalizáveis** para cada elemento
- **Estilos de texto** configuráveis
- **Suporte a temas customizados**

## 🚀 Instalação

Adicione ao seu `pubspec.yaml`:

```yaml
dependencies:
  smufl_renderer: ^0.0.1
```

Execute:

```bash
flutter pub get
```

## 📖 Uso Básico

```dart
import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

class MusicExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final staff = Staff();
    final measure = Measure();

    // Elementos básicos
    measure.add(Clef(type: 'g'));
    measure.add(KeySignature(0));
    measure.add(TimeSignature(numerator: 4, denominator: 4));

    // Notas
    measure.add(Note(
      pitch: const Pitch(step: 'C', octave: 4),
      duration: const Duration(DurationType.quarter),
    ));

    staff.add(measure);

    return MusicScore(staff: staff);
  }
}
```

## 🎵 Recursos Avançados

### Microtons

```dart
// Quarto de tom sustenido
Pitch.withAccidental(
  step: 'C',
  octave: 4,
  accidentalType: AccidentalType.quarterToneSharp,
)
```

### Ornamentos

```dart
// Trinado
Ornament(type: OrnamentType.trill, above: true)

// Grupeto
Ornament(type: OrnamentType.turn)
```

### Dinâmicas

```dart
// Forte
Dynamic(type: DynamicType.forte)

// Crescendo
Dynamic(
  type: DynamicType.crescendo,
  isHairpin: true,
  length: 100.0,
)
```

### Acordes

```dart
Chord(
  notes: [
    Note(pitch: Pitch(step: 'C', octave: 4), duration: Duration(DurationType.quarter)),
    Note(pitch: Pitch(step: 'E', octave: 4), duration: Duration(DurationType.quarter)),
    Note(pitch: Pitch(step: 'G', octave: 4), duration: Duration(DurationType.quarter)),
  ],
  duration: Duration(DurationType.quarter),
  ornaments: [Ornament(type: OrnamentType.trill)],
  dynamic: Dynamic(type: DynamicType.forte),
)
```

### Tablatura

```dart
TabNote(
  string: 1,  // Primeira corda
  fret: 5,    // Quinta casa
  duration: Duration(DurationType.quarter),
  techniques: [TabTechnique.bend, TabTechnique.vibrato],
)
```

## 🎨 Temas

```dart
// Tema escuro
MusicScore(staff: staff, theme: MusicScoreTheme.dark())

// Tema colorido
MusicScore(staff: staff, theme: MusicScoreTheme.colorful())

// Tema personalizado
MusicScore(
  staff: staff,
  theme: MusicScoreTheme(
    noteheadColor: Colors.blue,
    ornamentColor: Colors.orange,
    dynamicColor: Colors.red,
  ),
)
```

## 📄 Suporte a JSON

```dart
// Carregar de JSON
final jsonString = await rootBundle.loadString('assets/music.json');
final staff = JsonMusicParser.parseStaff(jsonString);

// Converter para JSON
final jsonOutput = JsonMusicParser.staffToJson(staff);
```

## 📊 Estatísticas

- **✅ 2932 símbolos SMuFL** disponíveis
- **✅ 12 categorias** principais de elementos
- **✅ 17 tipos** de acidentes (incluindo microtons)
- **✅ 15+ ornamentos** profissionais
- **✅ 20+ dinâmicas** e marcações
- **✅ 50+ técnicas** de tablatura
- **✅ Suporte completo** ao padrão SMuFL 1.40

## 🛠️ Desenvolvimento

```bash
# Executar o exemplo
cd example
flutter run -d chrome

# Compilar para web
flutter build web --release
```

## 🏆 Créditos

- **Fonte Bravura**: [Steinberg Media Technologies](https://www.smufl.org/fonts/)
- **Padrão SMuFL**: [W3C Music Notation Community Group](https://www.w3.org/community/music-notation/)

---

**SMuFL Renderer** - A biblioteca de notação musical mais poderosa para Flutter 🎵✨
