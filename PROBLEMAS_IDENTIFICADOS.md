# Análise Detalhada dos Problemas de Posicionamento

## 1. HASTES E BANDEIROLAS (Stems & Flags)

### Problemas Encontrados:
- ❌ **note_renderer.dart:148-150**: Cálculo manual da posição da haste sem usar âncoras SMuFL
- ❌ **note_renderer.dart:186-196**: Posicionamento de flags não usa anchor points `stemUpNW` / `stemDownSW`
- ❌ **note_renderer.dart:115-139**: Lógica de comprimento de haste está simplificada demais

### Correções Necessárias:
- Usar `stemUpSE` e `stemDownNW` da cabeça de nota para posicionar haste
- Usar `stemUpNW` e `stemDownSW` dos flags para conexão precisa
- Implementar algoritmo correto: flags em y=0 representam final de haste de 3.5 spaces

## 2. ACIDENTES (Accidentals)

### Problemas Encontrados:
- ❌ **note_renderer.dart:214**: Distância fixa de 1.2 spaces é MUITO grande
- ❌ Não usa `cutOutNW` da cabeça de nota para espaçamento otimizado
- ❌ Não considera largura real do acidente (`glyphAdvanceWidths`)

### Correções Necessárias:
- Distância padrão: 0.16-0.20 spaces (Behind Bars, Ted Ross)
- Usar `cutOutNW` para ajuste fino
- Calcular baseado na largura real do glifo

## 3. FEIXES (Beams)

### Problemas Encontrados:
- ❌ Implementação atual não existe ou está incompleta
- ❌ Sem cálculo de ângulo baseado nas regras de Ted Ross
- ❌ Sem consideração de múltiplos feixes (beamSpacing = 0.25 spaces)

### Correções Necessárias:
- Ângulo mínimo: 0.25 spaces para 1 posição de diferença
- Ângulo máximo: 1.75 spaces para 7+ posições
- Duas notas: máximo 0.5 spaces
- Usar `beamSpacing` e `beamThickness` do metadata Bravura

## 4. ORNAMENTOS (Ornaments)

### Problemas Encontrados:
- ❌ **ornament_renderer.dart**: Posicionamento sem considerar altura do glifo
- ❌ Sem uso de `opticalCenter` para centralização
- ❌ Distância fixa sem considerar contexto musical

### Correções Necessárias:
- Usar altura real do bounding box
- Distância padrão: 0.75 spaces acima da nota
- Ajustar se nota está em linhas suplementares superiores

## 5. ARTICULAÇÕES (Articulations)

### Problemas Encontrados:
- ❌ **articulation_renderer.dart:32-34**: Distância fixa de 1.2 spaces
- ❌ Não considera se há feixe (precisa mais espaço)
- ❌ Não usa altura real do glifo

### Correções Necessárias:
- Distância padrão: 0.5 spaces
- Adicionar 1.0 space se há feixe
- Usar altura do bounding box para precisão

## 6. LIGADURAS (Slurs)

### Problemas Encontrados:
- ❌ Implementação não encontrada ou incompleta
- ❌ Curvas não seguem padrão tipográfico de Bézier cúbica

### Correções Necessárias:
- Curvas assimétricas (controle em 25% e 75% da largura)
- Altura: 0.25 da distância horizontal
- Usar `slurEndpointThickness` (0.1) e `slurMidpointThickness` (0.22)

## 7. CRESCENDOS/DECRESCENDOS

### Problemas Encontrados:
- ❌ Sobreposição mencionada pelo usuário
- ❌ Implementação precisa de revisão de espaçamento vertical

### Correções Necessárias:
- Usar `hairpinThickness` (0.16) do metadata
- Espaçamento vertical mínimo entre elementos
- Detecção de colisão

## 8. SINAIS DE REPETIÇÃO (Repeat Barlines)

### Problemas Encontrados:
- ❌ **Não implementado**: ritornello (barras com pontos)
- ❌ **Não implementado**: prima e seconda volta (endings)
- ❌ Sinais gigantes mencionados pelo usuário

### Correções Necessárias:
- Implementar `repeatLeft` e `repeatRight` com pontos
- Usar `repeatBarlineDotSeparation` (0.16)
- Implementar endings com brackets
- Escala 1.0 (não aumentar)

## 9. GRACE NOTES (Appoggiaturas)

### Problemas Encontrados:
- ❌ **Não implementado** corretamente
- ❌ Fora de posição segundo usuário

### Correções Necessárias:
- Escala: 0.6 (60% do tamanho normal)
- Haste: 2.5 spaces (mais curta)
- Slash diagonal através da haste
- Posição: -1.5 spaces antes da nota principal

## 10. QUIÁLTERAS (Tuplets)

### Problemas Encontradas:
- ❌ **tuplet_renderer.dart** existe mas está bagunçado
- ❌ Bracket não posicionado corretamente
- ❌ Número não centralizado

### Correções Necessárias:
- Bracket: 1.0 space acima/abaixo das hastes
- Número: 0.5 spaces do bracket
- Usar `tupletBracketThickness` (0.16)
- Ocultar bracket se houver feixe

## 11. FÓRMULAS DE COMPASSO (Time Signatures)

### Problemas Encontrados:
- ✅ **Já implementado** em bar_element_renderer.dart:133-181
- ⚠️ Posicionamento pode precisar ajuste fino

### Verificar:
- Numerador em staffLine 4 (linha superior)
- Denominador em staffLine 2 (linha inferior)
- Casos especiais: C (common time), ₵ (cut time)

## PRIORIDADES DE IMPLEMENTAÇÃO

### Alta Prioridade (Crítico):
1. ✅ Criar `SMuFLPositioningEngine` - **FEITO**
2. 🔄 Corrigir posicionamento de hastes e flags em `note_renderer.dart`
3. 🔄 Corrigir distância de acidentes
4. 🔄 Implementar beams corretamente

### Média Prioridade (Importante):
5. Corrigir posicionamento de ornamentos
6. Corrigir posicionamento de articulações
7. Implementar ligaduras (slurs)
8. Implementar repeat barlines e endings

### Baixa Prioridade (Melhorias):
9. Implementar grace notes
10. Corrigir tuplets
11. Ajustar crescendos/decrescendos

## METODOLOGIA DE CORREÇÃO

Para cada renderer:
1. Adicionar `SMuFLPositioningEngine` como dependência
2. Substituir cálculos manuais por chamadas ao engine
3. Usar metadados reais (anchors, bounding boxes, advance widths)
4. Testar com exemplos do usuário
5. Ajustar constantes se necessário

## REFERÊNCIAS USADAS

- SMuFL Specification: https://w3c.github.io/smufl/latest/
- Bravura Metadata: `assets/smufl/bravura_metadata.json`
- "Behind Bars" - Elaine Gould (regras de tipografia)
- "The Art of Music Engraving" - Ted Ross (regras técnicas)
- Stem length: 3.5 spaces padrão
- Beam angles: 0.25-1.75 spaces
- Accidental spacing: 0.16-0.20 spaces