# Tilt-Chase Suika — GDD Draft v0.1

Created 2026-11-02. Draft only — refined with George until concrete.
Core prototype: plain blocks only, no polish, no artwork. (Changed 2026-11-02 at George's word: polygon shapes per level felt too random; blocks for now.)

## 1. The core idea in one line

Play Suika. Your merges push a chase forward. If your merges lean too far
Left or Right, you tilt, drift off line, and the chase stops working —
even though you are still scoring.

## 2. The Suika board

- Pieces are numbered 1 to 11. Bigger number = bigger piece.
- Two pieces of the same number that touch merge into one piece of the
  next number.
- 11 is the top. Two 11s that merge clear each other and pay a large
  total-points bonus (draft: 22 points, total only).
- Normal version: pieces fall down. Inverted version: pieces float up.
  The rest of the rules are the same.
- You lose the board in the normal Suika way: pieces pile past the top
  line and stay there (draft: 2 seconds).

## 3. The three types

Every piece is one of three types:

- **Left**
- **Right**
- **Neutral**

(In A.I.r bubbles these were Hot and Cold. Each new game names and draws
its own Left and Right — see sections 7 and 8.)

### Merge rules (set by George, 2026-11-02)

| Pieces that touch (same number) | Result | Points |
|---|---|---|
| Left + Left | Left, next number | Left points |
| Right + Right | Right, next number | Right points |
| Left + Right | **Neutral**, next number | Total points only — the two sides cancel |
| Neutral + Left | Next number (draft: Left — to test) | Total points only |
| Neutral + Right | Next number (draft: Right — to test) | Total points only |
| Neutral + Neutral | Neutral, next number | Total points only |

Why Left + Right is in the game: it gives the player a way to balance.
If you have too much Left, merging a Left with a Right burns off the
excess and makes a Neutral instead of adding more Left.

Points for a merge (draft): the new piece's number.
Example: two 3s merge into a 4, so the merge pays 4 points.

## 4. The two scores that run everything

- **Total points** = all merge points (Left + Right + total-only merges).
  Total points close the gap in the chase.
- **Imbalance** = Left points − Right points.
  Imbalance is shown on the balance bar and steers the chase.
  (The container used to tilt; George removed that 2026-11-03 — the
  frame never tilts now. See 'Balance bar' below.)

Example: Left points 18, Right points 7.
Total = 25, so the chase has moved 25 steps forward.
Imbalance = +11, so everything leans hard Left.

## 5. OPEN QUESTION 1 — what counts for imbalance?

George's call (2026-11-02): settle this by playing it, not on paper.

**Example.** You drop five Left 2s and one Right 2. Nothing has merged yet.

- **Way A — merges only:** Imbalance is still 0. Nothing tilts.
  The board stays flat until a Left pair actually merges. Then the tilt
  jumps all at once.
  *Feel: calm, then sudden lurches.*
- **Way B — pieces on the board:** Imbalance is already +8 (five Left 2s
  count 10, one Right 2 counts 2, 10 − 2 = 8). The container is already
  leaning Left, and the pieces start sliding Left before any merge.
  *Feel: you can see the tilt coming and fix it early, but one bad drop
  leans you right away.*

The prototype has a switch for this (Points / Board) so both can be felt
in real play. A third option — a mix of both — stays open.

## 6. The chase screen

Shown beside the board, at the same time.

**Both figures move, all the time** (corrected 2026-11-02, George's
catch — the first prototype wrongly let timed auto-shots close the gap
on their own, so dropping a single 2 block eventually won the chase).

- Both move at the same base speed (draft: 12 units/second).
- The gap is the distance between them. It changes **only** when their
  speeds differ. Nothing ever subtracts from the gap directly.
- A merge makes the pursuer faster: +1 speed per point (draft), and
  the boost fades over a few seconds. Stop merging and the target pulls
  back level — the gap stops closing, then holds.
- Imbalance steers the pursuer off line, and off-line speed is wasted
  sideways: on line (|imbalance| up to 4) you keep all of your boost;
  far off line (12+) you keep only a quarter of it.
- **Shots are earned, never free:** one merge earns one shot.
  - On line, a shot hits: the target is **slowed** (draft: 12 → 5 for
    1.5 seconds). That is the whole effect — a slower target means your
    speed closes the gap faster while it lasts.
  - Off line, the shot misses.
- Distance (tuned twice on 2026-11-02, George: it was obviously too
  short for the actual game): the target starts **700** ahead.
  How this number was picked — a bot played full games in the
  prototype (greedy placement, fast-forward):
  - At the old tuning (gap 120, big box) even a RANDOM bot caught the
    target in ~15 seconds and ~40 points. That was the 'too short' in
    numbers.
  - Final tuning: catches took **670–1,700 points and 190–460 drops**
    — a long, strong game that builds up to level 9–10 — and careless
    (random, unbalanced) play needed about twice the points of balanced
    play to close the same distance, because imbalance wastes boost
    and shots miss. Human players also fill the smaller box far
    sooner than the bot does, which is the real pressure.
  - The board was shrunk to match (draft: 340 wide, from 400) and the
    blocks made bigger, and a hit now slows the target less
    (12 → 9 for 1 second); boost is +0.45 speed per point.
- Retune 2026-11-03 (frame tilt removed): without tilt gravity the
  blocks stack straight down and the board fills sooner, so the
  board's own life got shorter — the same bot games now overflow at
  roughly 70–150 drops. The starting gap was reset to **320** so the
  chase length mirrors that actual game length: in bot runs the
  catch (or near-catch) lands right as the board fills — one win and
  three finishes with 9–57 of the gap left when the board topped
  out. Chase length = board life, neither shorter nor longer.
- Physics + veer fixes later on 2026-11-03 (George's catches in
  play): (1) blocks now collide as SQUARES, not circles — the old
  circle physics made square blocks roll off each other so they
  never stacked; now they sit flat (verified: a six-block column at
  rest, exact spacing). Board life under square physics, played by a
  placement bot: ~80–125 drops; gap softened 320 → **290**.
  (2) Veering strengthened: boost kept when off-line drops to 15%
  (was 25%) starting at |imbalance| 3 (was 4), and shots now leave
  from the chaser's actual drifted position — verified: at imbalance
  0 a shot hits and slows the target; at imbalance 8–12 the shot
  misses clean (target never slows).
- **The chase is endless.** There is no finish line and no escape
  (removed 2026-11-02 at George's word — an earlier draft's escape rule
  was an invention, and it meant the target 'escaped' even if the
  player simply did nothing). Doing nothing changes nothing: the gap
  holds, both figures keep moving. The only endings are catching the
  target, or the board filling up.
- Win: the gap reaches 0 — you actually catch the target.
- **Drawing rule:** the camera rides with the target. The target holds
  its place at the right while the world scrolls past at the target's
  own speed — slower scroll while it is slowed, but always forward.
  The chaser is drawn from the gap, so catching up always looks like
  the chaser moving forward, never the target sliding backwards
  (George's catches, 2026-11-02).
- With no merges, the gap stays where it is (base speeds are equal).
  There is no passive closing and no free firing, ever.

### Balance bar (replaces the tilt, 2026-11-03, George's word)

- The main frame NEVER tilts. Gravity is always straight down; pieces
  land where they are dropped and do not slide.
- In its place, a **balance bar** above the box shows red vs blue.
  First version (fill = share of total points, needle at |imbalance|
  40) was unclear in play — one early merge painted the whole bar one
  colour and the needle barely moved (George, 2026-11-03). Current
  version is a **centre-out meter**: the centre mark is balanced;
  colour grows out of the centre toward the leading side (red left,
  blue right) and how far it reaches IS the imbalance, full reach at
  |imbalance| 20; the white needle sits at the tip of the colour.
- Imbalance itself still steers the chase exactly as before (drift,
  wasted boost, missed shots) — only the board picture changed.

## 7. Game A — Shooting Stars

**First playable built 2026-11-03** (branch `shooting-stars`, files
`stars.html` / `stars-play.html`; George chose: focus Shooting Stars,
web first, shared core in `logic.js` — Rescue Pew comes later on the
same core):
- INVERTED as designed: a launcher at the bottom shoots stars UP;
  they are buoyant, pile against the top, and the round ends when the
  pile grows down past the danger line near the launcher.
- Pieces are round again (stars), circle physics — rolling, slipping
  into gaps and cascading chains are back; the square-blocks
  experiment stays only in the abstract core prototype.
- Star types keep the core colours for now: blue = Left, red = Right,
  white = Neutral. Named identities still to pick.
- Juice pass (no artwork): newborn stars pop in, big merges flash
  wider, a CHAIN counter pays bonus boost for merges within ~2.5s of
  each other, and the villain visibly slows with a scrolling
  starfield behind both ships.
- Two balance-pays experiments (to playtest): (a) RE-CENTRE SURGE —
  pulling a real imbalance (|x| >= 8) back on-line releases +6 boost;
  small wobbles do not farm it. (b) SURE SHOT — an L+R merge earns a
  shot that leaves from the line and steers; it cannot miss (verified
  headless: at imbalance +12 the sure shot still slows the villain).
- Villain starts 520 ahead (this game's own tuning; the inverted
  board merges faster than the core board). Bot games run ~65–175
  drops: the villain is sometimes caught, the board sometimes
  overruns first — a starting point, George's feel decides next.


- Inverted Suika: you shoot stars in, they float up.
- Stars are numbered 1–11, in Left and Right types (names/colours still
  to pick) plus Neutral.
- Chase: a space battle. Your ship chases the villain. Shots are earned
  by merges only (one merge = one shot) — see section 6.
  - On line: shots hit, each hit slows the villain and closes the gap
    faster.
  - Veering: shots miss. You are scoring, but not hitting.
- Win: close the gap and land enough hits to shoot the villain down.
- **Open:** how many hits? Does the gap reaching 0 alone end it, or is
  the shoot-down a separate health bar?

## 8. Game B — Rescue Pew

- Circus Suika: balloons or circus balls, numbered 1–11, Left / Right /
  Neutral.
- Chase: a man walks a tightrope, holding a balance beam, toward Pew
  the cat, waiting on the far side.
  - Total points = steps forward along the rope.
  - Imbalance = the beam tips. A small tip wobbles him. Past the limit
    (draft: |imbalance| 12 held for 2 seconds) he falls.
- Fail is soft and kind: if he falls, Pew jumps off herself and lands
  safely. The round ends, with no reward.
- Win: he reaches Pew. Big reward (draft, to design: a short rescue
  moment, then a harder rope / new round).
- **Open:** does a fall end the whole run, or just cost the reward for
  that rope?

## 9. What the player should understand without words

- Bigger merges = the chase visibly moves.
- One colour/type piling up = the box leans and the chaser drifts the
  same way.
- Bringing the other side in = things straighten out.
- No text is needed to teach this if the lean, the drift, and the gap
  all move together, at the same moment, from the same merge.

## 10. Not in this draft

- No art, no music, no menus, no levels. Core only.
- No levels/stages structure yet. One chase = one round, for now.
- Engine not picked. The prototype is plain web code with simple
  blocks so the rules can be tested fast.

## 11. Experiment list (in order)

1. Q1: imbalance from merge points vs pieces on the board (switch in
   the prototype).
2. Neutral + Left/Right: should the result keep the side (Left/Right),
   or come out Neutral?
3. Tilt strength: how many degrees before sliding helps merges vs
   wrecks plans?
4. Drift limits: where are "shots start missing" and "he falls"?
5. Left + Right merge: does players actually use it to balance, or is
   it an accident that happens to them?

## Update 2026-11-03 - Godot build of Shooting Stars (George's direction)

George called the canvas prototype boring and the hand-drawn stars insect-like, and directed: adopt an engine + existing base, free resources only. Fruit Merge King (web/JS) is the LOOK reference only - its repo has no LICENSE file and JS cannot run in Godot. The Godot base is gd_suikagame (MIT, (c) 2023 syun), adapted at ~/workspace/shooting-stars-godot.

STAR CATEGORIES: red = HOT stars, blue = COOL stars, white = WHITE stars (balanced, sun-like). (Originally set from real star physics — blue hot, red cool — and REVERSED by George 2026-11-04: audience intuition wins; for normal players hot reads red and cool reads blue.) The fiction fits the merge rules: HOT + COOL cancel into a balanced WHITE star; WHITE joins either side without tipping the balance.

Milestone 1 DONE and screenshot-verified (Godot 4.4.1, VM + Xvfb): inverted board (launcher at bottom, buoyant stars pile at the ceiling, red danger line near the launcher), one generic star scene driven by data (level + kind), full merge table live (same-kind scores its side; HOT+COOL and WHITE merges are total-only; 11+11 clears for 22), HOT/COOL/BALANCE readout, white-star evolution column, starfield backdrop, FMK-style radii growth. NOT yet in: the villain chase scene, FMK squash/shockwave juice, full-game game-over bot test.

### Inverted-board tuning (2026-11-03, bot-measured in the Godot build)

Baseline problem: the game could NOT end. A greedy bot survived the 400-drop cap (score 1387, ~0.9 merges/drop) because George's merge table makes EVERY same-level pair merge (same kind, HOT+COOL, WHITE+anything) - matches are far more common than classic Suika, so the pile consumed itself. Fixes (the tuning surface is geometry + spawn, not the rules): star radii x1.18 ([19,25,31,38,45,53,61,71,80,91,102]), spawn pool widened to levels 1-5, danger line raised from y=500 to y=470, and a fairness rule - only SETTLED stars (speed < 40) count toward game over, so a star still bouncing from its launch cannot kill the run. Measured after tuning (greedy bot, 3 full games): 88 / 116 / 205 drops, scores 217 / 336 / 697, biggest star 7 / 7 / 9, all ending in OVERRUN. Typical game ~100-200 drops and ~450 points - which fits the chase: a villain gap around 500 is a one-game chase.

### Terminology (2026-11-03, George's word)

The pieces are called SHOTS, not stars - they are star-shaped, but in the game's language they are shots: fired from the launcher, merged into bigger shots, and the same word as the shots merges earn against the villain. The Godot code and UI were renamed to match (Shot class/scene, SHOT n labels in the evolution column, assets/images/shots/).

### Expected time to catch (design constant, George 2026-11-03)

The chase has a fixed expected catch time whether or not the villain is rendered yet: a solid player should catch the target in about 6 minutes of play - roughly 160 shots / ~500 merge points, near the end of one typical run (measured board life 88-205 shots, ~450 pts typical). Strong/balanced play catches sooner (~4 min); lopsided play needs up to twice the points; doing nothing never catches (equal base speeds, endless chase). The gap + boost numbers get tuned to hit this constant, not the other way round.

## Update 2026-11-04 - where the game lives, engine assessment, CC-CLI

### Builds of record
- VM (Cosmo's machine): ~/workspace/shooting-stars-godot - the original Godot build, bot-verified.
- George's Mac: ~/shooting-stars - the same build ported into Summer Engine (v0.5.68), design recorded in that project's .summer/GameSoul.md. Summer's CLI drives a windowless background editor instance; the project only becomes visible in George's own Summer app when HE opens the folder there (his step, by his standing background-work rule).
- GitHub (2026-11-04): the Godot project is published as a public repo so it can be used in CC-CLI - public + README + MIT license are CC-CLI's requirements.

### Chase status: ON HOLD
George, 2026-11-03: "hold off on the chase." The chase is NOT built in any mainline build. The design constant stands as spec for when it is built: catch at ~500 merge points (~6 minutes of solid play, roughly 160 shots, near the end of one typical run; balanced play sooner, lopsided play up to 2x the points, doing nothing never).

### Engine assessment (2026-11-04, George's question)
- Godot / Summer stays the build home: the game is built, tuned and bot-verified there.
- Defold is the shipping-time port candidate IF the game goes to web portals / mobile: free, no royalties, Box2D, and by far the smallest HTML5 builds (~0.8 MB engine vs ~6.7 MB Godot). Its edge is distribution size and performance - NOT assets or look: the Defold Asset Portal holds only ~250 assets (mostly platform SDK extensions like AdMob), while Godot's Asset Library + community are far larger. If anything, Godot gives us MORE to borrow for look and feel, not less.
- Unity's edge would be George's learning (his code-study picks are largely C# games), not this title. Unreal: no edge for a 2D merge game.
- No engine switch now. The design numbers (rules, radii, spawn table, 500-point constant) are engine-independent and would carry into any port.

### CC-CLI model comparison (2026-11-04)
George will run a prompt through CC-CLI's A/B models against the public repo: implement the chase to the section-6 spec with bot-measured acceptance (catch at 450-550 points; idle play never closes the gap). The prompt lives in the repo as CC-CLI-PROMPT.md. This is an evaluation exercise - it does not lift the hold on the mainline build; if a model produces a good chase, it becomes a reference implementation for George to judge.
