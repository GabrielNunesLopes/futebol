# Futebol Competitive

Projeto Roblox competitivo de futebol 2D/2.5D baseado em física previsível, timing e domínio de ângulos. O repositório usa Luau + Rojo e mantém o servidor como autoridade para os estados competitivos.

## Estado atual

O primeiro milestone é um MVP jogável 1v1. Ele inclui:

- movimento planar com aceleração, desaceleração e momentum;
- input normalizado para impedir diagonal mais rápida;
- bola simulada em timestep fixo de 60 Hz;
- contato corporal jogador × bola;
- chute determinístico por ângulo, mira e momentum;
- paredes/rebotes sem RNG;
- arena 1v1 procedural;
- gol por cruzamento real da linha;
- kickoff `3/2/1/GO`;
- partida de 3 minutos;
- overtime com golden goal;
- autoridade do servidor para bola, movimento validado, chute, placar, relógio e resultado;
- rate limiting de remotes;
- câmera competitiva;
- HUD de placar/tempo/estado;
- scoreboard no `Tab` com jogador, time, gols e ping;
- suporte de input através do PlayerModule para teclado, controle e touch, com botão de chute em touch.

## Toolchain

Versões fixadas em `rokit.toml`:

- Rojo `7.6.1`
- Wally `0.3.2`

Dependência de teste:

- TestEZ `0.4.1`

## Instalação

Instale o Rokit e, na raiz do projeto, execute:

```bash
rokit install
wally install
```

Depois inicie a sincronização:

```bash
rojo serve default.project.json
```

Abra o Roblox Studio, use o plugin do Rojo e conecte ao servidor local.

## Build

Build de produção:

```bash
rojo build default.project.json -o futebol.rbxlx
```

Build da experiência usada para executar TestEZ no Studio:

```bash
wally install
rojo build test.project.json -o futebol-tests.rbxlx
```

Abra `futebol-tests.rbxlx` no Studio e pressione Play. `TestRunner.server.luau` executa as suítes de movimento, bola/chute e estados da partida e gera erro caso algum teste falhe.

## Estrutura

```text
src/
├── client/
│   ├── Bootstrap.client.luau
│   └── Controllers/
├── server/
│   ├── Bootstrap.server.luau
│   └── Services/
├── shared/
│   ├── Config/
│   ├── Match/
│   ├── Math/
│   ├── Network/
│   └── Physics/
└── tests/
```

`src/shared` concentra configurações e funções determinísticas compartilhadas. `src/server` possui a autoridade da simulação competitiva. `src/client` cuida de input, previsão/reconciliação, câmera e apresentação.

## Controles

### PC

- `WASD` — movimento
- `Mouse1` — chute
- `Tab` — scoreboard

### Controle

- analógico esquerdo — movimento
- `R2` — chute

### Mobile

- thumbstick padrão — movimento
- botão `CHUTE` — chute

## Multiplayer no Studio

Para validar o 1v1:

1. Use `Test > Start` com dois jogadores.
2. Confirme que ambos ficam parados durante `3/2/1`.
3. Confirme que o movimento é liberado em `GO`.
4. Teste contato corporal com a bola e chute de diferentes ângulos.
5. Tente chutar fora do alcance e fazer spam de chute.
6. Marque gols nos dois lados e confirme que cada cruzamento soma apenas uma vez.
7. Force empate até o fim do tempo e confirme `OVERTIME • GOLDEN GOAL`.
8. No Network Emulation, repita com aproximadamente 20, 50, 100, 150 e 200 ms quando o Studio permitir.

## Critérios de física

- a mesma entrada deve gerar o mesmo resultado de simulação;
- nenhuma direção de chute ou rebote usa aleatoriedade;
- FPS alto não aumenta velocidade nem força;
- o cliente envia intenção, nunca força ou velocidade autoritativa da bola;
- o servidor limita velocidade, cadência de input, range de chute e cooldown;
- valores de gameplay ficam em `PhysicsConfig`, `FieldConfig` e `MatchConfig`.

## CI

`.github/workflows/roblox-ci.yml` instala o toolchain, resolve os pacotes Wally e valida os builds de produção e testes em pushes/PRs configurados.

## Fora deste milestone

Este MVP deliberadamente ainda não implementa:

- menu principal completo;
- perfil persistente e stats globais;
- casual/ranked e matchmaking;
- MMR/ELO e divisões;
- 2v2, 3v3, 4v4 e 5v5 jogáveis;
- parties;
- equipes/clãs e código de equipe;
- salas privadas/custom matches;
- treinamento/free play;
- cosméticos/loja/quick chat;
- saves, assists e shots persistentes.

Esses sistemas entram em milestones separados depois que a física 1v1 estiver validada. A física central da bola deve permanecer compartilhada entre todos os modos futuros.
