# Competitive Roblox Football — Design Spec

## Goal
Rebuild `GabrielNunesLopes/futebol` from scratch as an original Roblox/Luau competitive 2D/2.5D football game inspired by the mechanical feel of Beatball/Haxball, with deterministic skill-based physics, responsive controls, server-authoritative match logic, scalable 1v1–5v5 formats, ranked/classic queues, profiles, parties, teams, custom rooms, training, stats and cosmetic-only monetization.

## Scope and sequencing
The repository will be migrated away from the existing Vite/web application. Existing application source will not be reused because the target runtime and architecture are different. The first playable milestone is a polished 1v1 core: player movement, ball physics, collisions, kick, goals, kickoff/reset, timer, score, match state and networking foundations. Team sizes 2v2–5v5, matchmaking, ranked progression and metagame systems are layered on only after the core simulation is stable.

## Repository architecture
Use Rojo-compatible source control so GitHub maps cleanly to Roblox Studio services.

- `default.project.json`: Rojo mapping.
- `src/shared/Config`: central immutable tuning for physics, matches, fields, ranks and networking.
- `src/shared/Physics`: deterministic/vector helpers shared by simulation code.
- `src/shared/Network`: remote names and shared network contracts.
- `src/server/Services`: authoritative services for matches, ball state, goals, data, queues, ranking, parties, teams and anti-cheat.
- `src/client/Controllers`: input, movement prediction, camera, UI and interpolation.
- `src/client/UI`: menu/HUD view modules.
- `tests`: pure Luau tests for deterministic helpers and state machines where practical.
- `docs`: design, implementation notes and Studio/Rojo setup.

Keep files focused by responsibility. Do not create a monolithic gameplay script.

## Simulation model
Gameplay takes place primarily on an X/Z plane with circular player and ball footprints. Critical simulation uses a fixed-step accumulator targeting 60 Hz and is independent of render FPS. Tunable values live in config modules.

Player motion uses normalized input, configurable acceleration/deceleration, max speed and bounded momentum. Diagonal input never exceeds cardinal speed.

Ball response is deterministic and uses the contact normal, player velocity, ball velocity, contact point/offset, restitution, damping and kick impulse. No RNG participates in ball direction. Fast motion receives swept/continuous collision checks or equivalent substepping so the ball does not tunnel through players or arena boundaries.

## Networking
The server is authoritative for ball state, valid kicks, goals, score, clock, match result, MMR, rewards and persisted stats. Clients send intents/input rather than authoritative positions or results.

Clients may predict their own movement and render interpolated remote actors. The server periodically supplies authoritative snapshots and clients reconcile meaningful divergence. Ball presentation should be smoothed while preserving the authoritative trajectory. Validation includes movement envelopes, kick cadence/range, remote rate limiting and impossible-input checks. Network anomalies accumulate suspicion signals rather than causing an automatic ban from one discrepancy.

## Match lifecycle
A match is a state machine: `Waiting -> Countdown -> Playing -> GoalPause -> Countdown -> Playing -> Finished`; ties at regulation can transition into `Overtime`, where the next valid goal ends the match. The server owns transitions.

A goal is awarded only when the ball center fully crosses the configured goal line within the goal aperture. On a goal, temporarily freeze play, attribute goal/assist when valid, update score, reset the ball and players, then run a 3-2-1-GO kickoff.

## Formats and field scaling
The same physics remain active for every team size. Only field dimensions, spawn layouts, player counts and matchmaking change.

Initial configurable scaling relative to the base field:

- 1v1: width 1.00, length 1.00
- 2v2: width 1.00, length 1.00
- 3v3: width 1.05, length 1.05
- 4v4: width 1.20, length 1.15
- 5v5: width 1.35, length 1.25

The 4v4/5v5 increase exists to preserve space and reduce ball clustering.

## Input and camera
Desktop defaults: WASD movement and Mouse1 as kick, with configurable bindings. Gamepad and mobile receive equivalent movement/kick controls. The camera is top-down or lightly angled, smooth, competition-first and keeps relevant play readable. Camera shake is optional and off-compatible.

## Ranked and queues
Classic and Ranked expose 1v1 through 5v5. Ranked uses separate rating per format and placement matches. Matchmaking begins within a narrow MMR window and expands gradually over queue time, while team formats attempt to balance team average rating and account for premade parties.

Initial visible rank ladder: Bronze, Silver, Gold, Platinum, Diamond, Champion, Grand Champion, Elite, with I/II/III subdivisions where applicable and leaderboard rating beyond the configured top tier.

## Player data
Persistent profile includes matches, wins, losses, goals, assists, saves, shots, passes, win rate derivation, current/best streak, playtime, XP, level, per-format MMR/rank and seasonal placement state. Data writes are server-only and must tolerate retries/failures without silently corrupting profiles.

## Parties and teams
Parties are temporary groups used for queueing, with a leader controlling queue entry and size constrained by the selected format. Teams/clans are persistent and contain name, tag, icon/color metadata, wins/losses, rating, membership and roles (`OWNER`, `CAPTAIN`, `MEMBER`). A short shareable team code allows joining/invitation flow with server-side validation.

## Custom matches and training
Custom matches support team size, duration, goal limit, overtime, stadium, team assignment and optional password, exposed through a generated room code. Free Play allows solo ball practice and instant reset, with development diagnostics/tuning controls available only in Studio/development contexts.

## UI/UX
The main menu presents Roblox avatar/display identity, level/XP, rank/MMR and key stats. `Play` leads to Ranked or Classic, then 1v1–5v5. Queue state remains visible while navigating permitted menus. Match HUD contains score and time; TAB opens a team-separated scoreboard with goals, assists, saves, shots and ping. Post-match UI shows result, rating delta/progress and match stats.

Visual direction: original, minimal, dark, premium esports styling with clear hierarchy, restrained gradients and smooth transitions. Do not copy protected interface assets or branding from reference games.

## Cosmetics
Monetization is cosmetic only: skins, trails, goal explosions, banners, badges, titles, ball visuals and emotes/quick-chat presentation. Cosmetics must never alter hitbox, movement speed, kick strength/range/cooldown or simulation behavior.

## Testing and observability
Build pure tests around vector math, fixed-step behavior, field scaling, rank/MMR helpers and match state transitions. Add development diagnostics for player speed, ball speed, simulation tick, prediction error, server/client positions and ping. Multiplayer testing targets 1, 2, 4, 6, 8 and 10 players and simulated latency bands of 20, 50, 100, 150 and 200 ms.

## Acceptance criteria for the first milestone
The first milestone is accepted when a two-player Studio test can complete repeated 1v1 matches with predictable movement and ball trajectories, valid kicks only within range/cooldown, reliable wall/player collisions, correct goal-line detection, score/timer/overtime flow, deterministic kickoff resets and no gameplay outcome sourced directly from an untrusted client.

## Source requirement
The implementation must remain faithful to the user's supplied master prompt, especially its emphasis that physics is the primary differentiator, gameplay should be skill-based and predictable, and the first polished deliverable is the 1v1 core before expanding to 2v2–5v5.