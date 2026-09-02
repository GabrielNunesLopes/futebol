# Competitive Roblox Football MVP 1v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable, server-authoritative 1v1 Roblox football MVP with deterministic-feeling movement, ball physics, kicking, goals, kickoff/reset, match timer, HUD, and a clean Rojo project foundation that can later expand to 2v2–5v5.

**Architecture:** Use Rojo to map a modular Luau codebase into Roblox services. Shared configuration and pure simulation helpers live under `src/shared`; authoritative match, ball, goal, anti-abuse, and player services live under `src/server`; input, local prediction/interpolation, camera, and HUD live under `src/client`. The first milestone intentionally excludes ranked, parties, clans, persistence, cosmetics, and matchmaking so the physics/gameplay core can be validated first.

**Tech Stack:** Roblox Studio, Luau, Rojo 7.x, Wally, TestEZ, GitHub.

**Spec:** `docs/superpowers/specs/2026-09-02-competitive-roblox-football-design.md`

## Global Constraints

- Physics/gameplay must remain skill-based, predictable, and free of random directional variance.
- Server is authoritative for ball state, kick validity, goals, score, timer, and match result.
- Client may predict local movement and render/interpolate remote state, but cannot authoritatively set match state.
- Critical simulation uses a fixed-step loop at 60 Hz.
- 1v1 is the only playable mode in this plan; architecture must allow later 2v2–5v5 expansion without changing core ball behavior.
- Gameplay-critical values must be centralized in configuration modules.
- No pay-to-win or cosmetic systems in the MVP.
- Do not rely on player FPS for physics outcomes.

---

## File Map

- `default.project.json` — Rojo mapping for ReplicatedStorage, ServerScriptService, StarterPlayerScripts, and StarterGui.
- `wally.toml` — dependency manifest for TestEZ.
- `src/shared/Config/PhysicsConfig.luau` — player, ball, collision, kick, and fixed-step tuning.
- `src/shared/Config/FieldConfig.luau` — standard 1v1 field geometry and future per-mode scale table.
- `src/shared/Config/MatchConfig.luau` — match duration, kickoff, overtime, reset timing.
- `src/shared/Math/VectorMath.luau` — clamp/normalize/reflect and safe 2D XZ helpers.
- `src/shared/Physics/BallMath.luau` — pure kick and bounce calculations.
- `src/shared/Physics/MovementMath.luau` — pure acceleration/deceleration movement calculations.
- `src/shared/Network/Remotes.luau` — remote names and creation/access helpers.
- `src/server/Bootstrap.server.luau` — server composition root.
- `src/server/Services/FieldService.luau` — creates/validates arena, walls, goals, ball spawn, player spawns.
- `src/server/Services/BallService.luau` — owns the ball and advances authoritative ball state.
- `src/server/Services/PlayerMotorService.luau` — validates movement inputs and applies authoritative planar movement constraints.
- `src/server/Services/KickService.luau` — validates kick range/cooldown and applies deterministic impulse.
- `src/server/Services/GoalService.luau` — goal-line crossing detection and scorer attribution hook.
- `src/server/Services/MatchService.luau` — 1v1 state machine, countdown, score, timer, overtime, reset.
- `src/server/Services/RateLimitService.luau` — reusable token-bucket limiter for remotes.
- `src/client/Bootstrap.client.luau` — client composition root.
- `src/client/Controllers/InputController.luau` — keyboard/gamepad input capture and kick request.
- `src/client/Controllers/MovementController.luau` — local responsive movement/prediction and reconciliation hook.
- `src/client/Controllers/CameraController.luau` — stable top-down/angled camera.
- `src/client/Controllers/HudController.luau` — scoreboard, timer, countdown, overtime, result.
- `src/tests/MovementMath.spec.luau` — movement unit tests.
- `src/tests/BallMath.spec.luau` — kick/bounce unit tests.
- `src/tests/MatchState.spec.luau` — match-state transition tests.
- `README.md` — setup, Rojo workflow, Studio test checklist, controls.

---

### Task 1: Rojo Project Skeleton and Test Harness

**Files:**
- Create: `default.project.json`
- Create: `wally.toml`
- Create: `.gitignore`
- Create: `README.md`
- Create: `src/server/Bootstrap.server.luau`
- Create: `src/client/Bootstrap.client.luau`
- Create: `src/shared/Network/Remotes.luau`

**Interfaces:**
- Produces: `Remotes.get(name: string): RemoteEvent`, `Remotes.getOrCreate(name: string): RemoteEvent`.
- Produces Roblox folders `ReplicatedStorage.Shared`, `ReplicatedStorage.Remotes`, `ServerScriptService.Server`, `StarterPlayerScripts.Client` through Rojo mappings.

- [ ] **Step 1: Write the project mapping and dependency manifest**

Create `default.project.json` with explicit mappings from `src/shared`, `src/server`, and `src/client` into Roblox services. Create `wally.toml` with TestEZ as a development dependency.

- [ ] **Step 2: Add a minimal remote registry**

Implement `Remotes.get` to error on a missing remote and `Remotes.getOrCreate` to create a `RemoteEvent` only on the server.

- [ ] **Step 3: Add server/client bootstrap smoke checks**

Each bootstrap should require one shared module and print one concise startup line so a Studio test confirms Rojo mapping is correct.

- [ ] **Step 4: Verify project structure**

Run: `rojo build -o futebol.rbxlx`
Expected: build succeeds without missing-path errors.

- [ ] **Step 5: Commit**

```bash
git add default.project.json wally.toml .gitignore README.md src
git commit -m "chore: scaffold Roblox Rojo project"
```

---

### Task 2: Pure Movement Physics

**Files:**
- Create: `src/shared/Config/PhysicsConfig.luau`
- Create: `src/shared/Math/VectorMath.luau`
- Create: `src/shared/Physics/MovementMath.luau`
- Create: `src/tests/MovementMath.spec.luau`

**Interfaces:**
- Produces: `MovementMath.stepVelocity(current: Vector3, input: Vector3, dt: number): Vector3`.
- Produces: `VectorMath.flattenXZ(v: Vector3): Vector3` and `VectorMath.safeUnitXZ(v: Vector3): Vector3`.

- [ ] **Step 1: Write failing tests**

Cover normalized diagonal input, acceleration toward max speed, deceleration toward zero, and reversal preserving a short momentum transition.

- [ ] **Step 2: Run tests and confirm failure**

Run the TestEZ suite in Studio or via the configured test runner.
Expected: movement tests fail because the modules do not yet exist.

- [ ] **Step 3: Implement minimal movement math**

Use XZ-plane vectors, magnitude-clamped input, configurable acceleration/deceleration, and a hard `MaxSpeed` ceiling. Keep Y velocity out of the competitive planar model.

- [ ] **Step 4: Re-run tests**

Expected: all movement tests pass deterministically for fixed inputs and `dt`.

- [ ] **Step 5: Commit**

```bash
git add src/shared src/tests/MovementMath.spec.luau
git commit -m "feat: add deterministic player movement math"
```

---

### Task 3: Pure Ball/Kick and Wall Reflection Math

**Files:**
- Create: `src/shared/Physics/BallMath.luau`
- Create: `src/tests/BallMath.spec.luau`

**Interfaces:**
- Produces: `BallMath.computeKick(ballPosition: Vector3, playerPosition: Vector3, playerVelocity: Vector3, aimDirection: Vector3, power: number): Vector3`.
- Produces: `BallMath.reflectVelocity(velocity: Vector3, normal: Vector3, restitution: number): Vector3`.
- Consumes: `PhysicsConfig`, `VectorMath`.

- [ ] **Step 1: Write failing tests**

Test center contact, side contact, player momentum contribution, max ball speed clamp, and wall reflection with restitution.

- [ ] **Step 2: Confirm tests fail**

Expected: failures because `BallMath` is missing.

- [ ] **Step 3: Implement deterministic formulas**

Compute kick direction from player→ball contact normal blended with normalized aim direction and bounded player momentum contribution. Do not use randomness.

- [ ] **Step 4: Re-run tests**

Expected: identical inputs produce identical vectors and all assertions pass.

- [ ] **Step 5: Commit**

```bash
git add src/shared/Physics/BallMath.luau src/tests/BallMath.spec.luau
git commit -m "feat: add deterministic ball and kick math"
```

---

### Task 4: Arena, Ball Ownership, and Fixed-Step Server Simulation

**Files:**
- Create: `src/shared/Config/FieldConfig.luau`
- Create: `src/server/Services/FieldService.luau`
- Create: `src/server/Services/BallService.luau`
- Modify: `src/server/Bootstrap.server.luau`

**Interfaces:**
- Produces: `FieldService.createArena(mode: string): ArenaRefs`.
- Produces: `BallService.start(ball: BasePart, arena: ArenaRefs)` and `BallService.reset(position: Vector3)`.
- Ball is server network-owned where Roblox permits and is corrected from authoritative state.

- [ ] **Step 1: Build the 1v1 arena procedurally**

Create floor, perimeter walls, left/right goal-line trigger geometry, center mark, ball spawn, and two player spawn points. Keep dimensions in `FieldConfig`.

- [ ] **Step 2: Implement a 60 Hz accumulator loop**

Use `RunService.Heartbeat`, accumulate real delta, and advance fixed simulation steps of `1/60` seconds with a bounded catch-up count.

- [ ] **Step 3: Own and clamp ball state**

Apply planar friction, max speed, and wall response. Prevent ball tunneling through arena boundaries using swept checks/raycast where native contacts are insufficient.

- [ ] **Step 4: Studio verification**

Expected: ball remains inside field, rebounds consistently, and repeated identical launches follow materially identical trajectories.

- [ ] **Step 5: Commit**

```bash
git add src/shared/Config/FieldConfig.luau src/server/Services src/server/Bootstrap.server.luau
git commit -m "feat: add arena and authoritative ball simulation"
```

---

### Task 5: Player Motor, Kick Validation, and Rate Limiting

**Files:**
- Create: `src/server/Services/PlayerMotorService.luau`
- Create: `src/server/Services/KickService.luau`
- Create: `src/server/Services/RateLimitService.luau`
- Create: `src/client/Controllers/InputController.luau`
- Create: `src/client/Controllers/MovementController.luau`
- Modify: `src/shared/Network/Remotes.luau`
- Modify: `src/server/Bootstrap.server.luau`
- Modify: `src/client/Bootstrap.client.luau`

**Interfaces:**
- Remote `InputFrame` carries normalized movement intent and monotonically increasing input sequence.
- Remote `KickRequest` carries aim direction and client input sequence, never arbitrary force or ball velocity.
- Server validates `KickRange`, `KickCooldown`, player alive/match-active state, and rate limits before applying `BallMath.computeKick`.

- [ ] **Step 1: Add movement input transport**

Send compact movement intent at a bounded cadence; server rejects NaN/oversized vectors and impossible sequence regression.

- [ ] **Step 2: Apply authoritative player movement constraints**

Use the shared movement math for server-side expected planar velocity and clamp outliers instead of trusting arbitrary client position changes.

- [ ] **Step 3: Add local responsiveness and reconciliation hook**

Client immediately applies local movement intent, stores recent input sequence IDs, and accepts server snapshots to correct visible drift smoothly.

- [ ] **Step 4: Implement kick request validation**

Only server computes final kick impulse. Reject requests outside range, during cooldown, outside active play, or above remote rate limits.

- [ ] **Step 5: Multiplayer Studio test**

Expected: two clients can move responsively; spamming kick requests cannot exceed configured cooldown; editing remote payloads cannot assign arbitrary force.

- [ ] **Step 6: Commit**

```bash
git add src/server/Services src/client src/shared/Network
git commit -m "feat: add authoritative movement and validated kicking"
```

---

### Task 6: Goal Detection and Match State Machine

**Files:**
- Create: `src/shared/Config/MatchConfig.luau`
- Create: `src/server/Services/GoalService.luau`
- Create: `src/server/Services/MatchService.luau`
- Create: `src/tests/MatchState.spec.luau`
- Modify: `src/server/Bootstrap.server.luau`

**Interfaces:**
- Match states: `Waiting`, `Countdown`, `Playing`, `GoalPause`, `Overtime`, `Finished`.
- Produces: `MatchService.start(players: {Player})`, `MatchService.getSnapshot(): MatchSnapshot`.
- Goal is valid only when the ball center crosses the configured goal line inside the goal mouth.

- [ ] **Step 1: Write failing state-transition tests**

Test countdown→playing, goal→goal pause→countdown, regulation tie→overtime, overtime goal→finished, and non-tie regulation→finished.

- [ ] **Step 2: Implement the match state machine**

Keep score/timer/state server-only and expose read-only snapshots to clients.

- [ ] **Step 3: Implement goal-line crossing detection**

Use previous and current authoritative ball positions to detect a true crossing and avoid duplicate goals while the ball remains inside the net.

- [ ] **Step 4: Implement kickoff/reset**

Freeze competitive movement during countdown, reset ball/player positions, clear transient velocity, then release on `GO`.

- [ ] **Step 5: Re-run tests and Studio scenario**

Expected: exactly one goal per crossing, correct reset, correct timer, and golden-goal overtime.

- [ ] **Step 6: Commit**

```bash
git add src/shared/Config/MatchConfig.luau src/server/Services src/tests/MatchState.spec.luau
git commit -m "feat: add goals and 1v1 match state machine"
```

---

### Task 7: Camera and Competitive HUD

**Files:**
- Create: `src/client/Controllers/CameraController.luau`
- Create: `src/client/Controllers/HudController.luau`
- Modify: `src/client/Bootstrap.client.luau`

**Interfaces:**
- HUD consumes server `MatchSnapshot` events only.
- Camera follows local player/ball framing without controlling gameplay state.

- [ ] **Step 1: Implement stable top-down/angled camera**

Use a smoothed camera anchor that keeps the local player and relevant ball position visible without aggressive shake.

- [ ] **Step 2: Build HUD programmatically**

Show blue score, red score, timer, `3/2/1/GO`, overtime indicator, and victory/defeat result panel.

- [ ] **Step 3: Add TAB scoreboard shell**

For the MVP show player names, goals, and ping; leave assists/saves/shots for a later stats subsystem.

- [ ] **Step 4: Verify at common aspect ratios**

Test desktop 16:9, narrower window, and a mobile emulator. Critical elements must remain visible and non-overlapping.

- [ ] **Step 5: Commit**

```bash
git add src/client
git commit -m "feat: add competitive camera and match HUD"
```

---

### Task 8: Verification, Hardening, and MVP Documentation

**Files:**
- Modify: `README.md`
- Modify as needed: files from Tasks 1–7 only when verification exposes defects.

**Interfaces:**
- No new gameplay interfaces unless required to fix a verified defect.

- [ ] **Step 1: Run all unit tests**

Expected: movement, ball, and match-state suites pass.

- [ ] **Step 2: Build with Rojo**

Run: `rojo build -o futebol.rbxlx`
Expected: success.

- [ ] **Step 3: Run Roblox Studio multiplayer matrix**

Test 1-player free startup and 2-player 1v1. Validate 20/50/100/150/200 ms network emulation where Studio tooling permits.

- [ ] **Step 4: Validate abuse cases**

Attempt kick spam, malformed direction vectors, excessive movement intent, repeated input sequence IDs, and kicks while not in `Playing`. Expected: requests are rejected or clamped without crashing the server.

- [ ] **Step 5: Validate gameplay acceptance criteria**

Confirm diagonal movement is not faster, ball never uses RNG, kick angle responds to contact/aim, goal is counted once, kickoff blocks premature play, overtime is golden goal, and 60 FPS vs high-FPS clients do not gain different simulation rules.

- [ ] **Step 6: Finish README**

Document required tools, `rojo serve`, Studio connection steps, controls, project layout, test procedure, and the deliberate MVP exclusions: ranked, matchmaking, persistence, teams, parties, cosmetics, and 2v2–5v5.

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "docs: verify and document playable 1v1 MVP"
```

---

## Post-MVP Expansion Order

After this plan is fully verified, create separate specs/plans in this order: 2v2–5v5 field/team scaling; persistent player stats; casual/ranked queues and MMR; party system; team/clan codes; custom rooms; training mode; cosmetics/quick chat. Core `BallMath` and gameplay physics must remain shared across every mode.
