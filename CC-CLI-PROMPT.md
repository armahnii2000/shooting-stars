# Task: implement the chase in Shooting Stars

You are working in this repository: a Godot 4 game called **Shooting Stars**,
an inverted Suika merge game. Read `README.md` and `GDD.md` first — the GDD
is the design authority (the chase is section 6; the catch constant is in the
2026-11-03 update). The board game is complete and tuned. **Your task is to
implement the missing chase.**

## Where things live

- `Main.gd` — game flow, launcher, UI, game-over. Study its state machine
  and how it learns about merges before you design anything.
- `src/common/Common.gd` — autoload holding `score`, `hot_pts`, `cool_pts`
  (BALANCE = hot − cool). Merges report points here.
- `src/shot/Shot.gd` — the shot piece and the full merge table.
- `tools/bot.gd` — a headless placement bot that plays whole games; extend
  it for your measurements.

## The chase spec (implement exactly this model)

Render a chase scene in the same window as the board: your ship pursuing a
villain ship, both flying in the same direction over a scrolling starfield.
The camera rides with the villain, so closing in always reads as *your ship
moving forward faster* — never render the villain sliding backwards.

- Both ships move continuously at the **same base speed** (12 units/sec).
  The gap changes **only** through relative speed. There is no passive gap
  closing and no direct gap subtraction, ever.
- Each merge adds a speed boost to your ship: **+0.45 speed per point**,
  decaying by **×0.994 per frame**. The boost is scaled by a line factor
  from the current balance: |balance| ≤ 3 → ×1.0; |balance| ≥ 10 → ×0.15;
  linear between.
- Each merge also earns **exactly one shot** at the villain — one merge, one
  shot, never auto-fire. The shot leaves from your ship's *current* position,
  which drifts sideways as |balance| grows (the veer). A shot that starts on
  line hits; a shot fired while veered off line misses. A hit slows the
  villain from 12 to 9 units/sec for 1 second. (A shot earned by a HOT+COOL
  merge — a cancelling merge — is a sure shot: it leaves from the line and
  steers, so it cannot miss.)
- Show the balance as a **centre-out bar**: centre = balanced, colour grows
  toward the leading side (blue left for HOT, red right for COOL), full
  reach at |balance| 20, white needle at the tip. The existing text readout
  may stay as a supplement, not a replacement.
- The chase is **endless**: there is no finish line and the villain never
  "escapes". The run ends only when the board is overrun (existing game
  over) or when the gap reaches 0 — the catch. On a catch, end the run in a
  distinct win state (e.g. a "CAUGHT" caption), separate from OVERRUN.

## Tuning target (this is the acceptance bar)

With the bot playing full games (extend `tools/bot.gd`):

- A competent bot run **catches the villain at 450–550 total points**.
- A run that fires shots without merging (no points) **never** closes the
  gap.
- Lopsided play (balance held at |balance| ≥ 10) needs at least ~1.5× the
  points of balanced play to catch, or fails to catch before the overrun.

Set the starting gap and any scale constants to hit these numbers, and
report the measured points-at-catch from at least three bot runs in your
summary.

## Constraints

- GDScript, Godot 4.4+. No new external assets — draw the ships and shots
  with primitives, polygons, or particles.
- **Do not change the board**: merge rules and scoring, `RADII`,
  `SPAWN_IDS`, the danger line at y=470, and the settled-only game-over rule
  are tuned and final.
- The pieces are called **shots** (in code names, comments, and UI text) —
  never "stars" for the pieces, never "fruit".
- The game must still run headless with zero script errors, and the bot
  harness must still work.
- Keep the change additive where you can: the chase should read game state
  (score / merge events / balance) rather than rewriting board logic.
