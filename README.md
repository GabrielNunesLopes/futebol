# Futebol Competitive

Projeto Roblox competitivo de futebol 2D/2.5D baseado em física previsível e habilidade.

## Stack

- Roblox Studio
- Luau
- Rojo 7.x
- Wally
- TestEZ

## Estrutura

- `src/shared` — configurações, matemática, física e rede compartilhadas.
- `src/server` — autoridade de partida, bola, gols, movimento e validações.
- `src/client` — input, previsão/reconciliação, câmera e HUD.
- `src/tests` — testes unitários das partes puras da simulação.

## Setup

1. Instale Rojo 7.x e Wally.
2. Execute `wally install`.
3. Execute `rojo serve` na raiz do projeto.
4. No Roblox Studio, conecte o plugin Rojo ao servidor local.
5. Para validar o mapeamento sem abrir o Studio, execute `rojo build -o futebol.rbxlx`.

## MVP 1v1

A primeira entrega prioriza movimento responsivo, física determinística da bola, chute, arena, gols, kickoff/reset, cronômetro e networking server-authoritative. Ranked, clãs, parties, persistência e cosméticos entram apenas após a validação do núcleo de gameplay.

## Controles planejados

- `WASD` — movimento
- `Mouse1` — chute
- `Tab` — placar

## Princípios

- física crítica em timestep fixo de 60 Hz;
- sem RNG em direção de chute/rebote;
- servidor é autoridade para bola, gol, placar, tempo e resultado;
- cliente pode prever movimento local, mas não definir estado competitivo;
- valores de gameplay ficam centralizados em módulos de configuração.
