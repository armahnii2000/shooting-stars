# Shooting Stars

An inverted Suika (merge game) in space, built in Godot 4.

A launcher at the bottom of a box fires **shots** upward. Shots are buoyant —
they float up and pile against the ceiling. When two shots of the same level
touch, they merge into a shot of the next level, 1 through 11. Two 11s clear
each other. If the pile grows down past the red danger line and settles there,
the run ends — **OVERRUN**.

## The shots

Every shot is one of three kinds, coloured the way players expect:

- **HOT** (red) — the colour everyone reads as hot
- **COOL** (blue) — the colour everyone reads as cool
- **WHITE** (white) — balanced, sun-like

Merge rules:

- Same kind + same level → next level of that kind; points go to that side
  (HOT points or COOL points)
- HOT + COOL of the same level → a WHITE of the next level; total points only
  (they cancel)
- WHITE + either side, same level → next level of that side; total points only
- Any merge pays points equal to the new shot's level; two 11s pay 22

**BALANCE** = HOT points − COOL points, shown on screen. It exists for the
chase (below).

## How to play

- Mouse moves the launcher, click fires the next shot
- `R` retries after an overrun
- A typical run lasts ~100–200 shots and scores ~450 points

## The chase (designed, not yet implemented)

A parallel space chase runs alongside the board: your ship pursues a villain.
Both ships move continuously at the same base speed, so the gap only changes
through play: merges add a fading speed boost and earn shots at the villain
(one merge = one shot), balance veers your ship off line so shots miss, and
hits slow the villain. The design constant: a solid player catches the
villain at **~500 merge points**, near the end of one typical run. Doing
nothing never catches him — the chase is endless, there is no escape line.

Full design: [GDD.md](GDD.md). A ready-made implementation task for the
chase, with measurable acceptance criteria: [CC-CLI-PROMPT.md](CC-CLI-PROMPT.md).

## Running it

Open `project.godot` in Godot 4.4+ (or in Summer Engine, which is
Godot-4-compatible) and run the project. `tools/bot.gd` is a headless
placement bot used to measure game length and scoring balance.

## Credits and license

Original game code in this repo is MIT-licensed (see `LICENSE`). The project
was built on [gd_suikagame](https://github.com/syun77/gd_suikagame) by
syun77, also MIT (see `LICENSE-MIT-base.txt`); some art, fonts, and music
assets originate from that base.
