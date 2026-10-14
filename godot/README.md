# SAKAWA: Astral Max — Godot 4 project

Season One, Chapters 1–4, in **Godot 4.3+**:

| Chapter | Rooms | Boss |
| --- | --- | --- |
| 1 · Class Famine | Room 101, East Hall, Cafeteria, Sub-Basement Lab | Hallway Echo, Dr. Ciencia (becomes the Viral Saint at half health) |
| 2 · The Carrier | Westbrook Avenue, Mercy General | The Carrier (Kai Brooks); Lana's taunts stun him for double damage |
| 3 · Red Water | Westbrook Waterworks (rescue 3 workers), The Pumphouse | Elite Static Rider; the Red Tide (Jason's water awakens at half health) |
| 4 · #ScienceMatters | Science Fair Night (East Hall), the Gymnasium (break 3 broadcasting exhibits), the Main Stage | Elite Static Rider; Collective Cognition (Dr. Ciencia wired into the fair, summoning imps and riders) |

Chapter 2 also has an elite Static Rider on Westbrook Avenue. Choir Imps and Static Riders roam Chapters 1–4 alongside the infected and Choir Motes.

## Party, progression and gear

- **Three playable heroes.** Max leads. Lana joins in Chapter 2 (fast, durable, specials *Get Real* shockwave-and-stun or *Flurry*), Jason in Chapter 3 (strongest hits, specials *Tidal Push* wave or *Geyser*). Max's specials are the *Psychic Laser* or the homing *Mind Orb*. Swap with Tab (or 1 / 2 / 3, R3 on a gamepad). Only Max can astral-project.
- **Fighting together.** In every boss and elite fight except the Hallway Echo, the two heroes you aren't playing fight beside you as AI allies, with their own strikes and specials.
- **Auras.** Each hero has a flame aura (Max violet, Lana crimson, Jason sky) that flares when charging a special, focusing, swapping in, or when Full Potential is ready.
- **Experience and levels.** Enemies drop experience shards, health, Resonance and sometimes gear. Each level gives every hero an attribute point: Vitality (+1 health), Power (+1 damage per 2 points), Focus (cheaper specials, more Resonance). Second specials unlock at levels 3–4.
- **Heart Embers** (one hidden in each chapter, plus the cafeteria) raise the whole party's maximum health by 1.
- **Equipment.** 12 items, 3 slots shared by the party: found in rooms, dropped by enemies and elite riders, and awarded by bosses.
- **Character menu** (I / M, Back on a gamepad, or CHARACTER in the pause menu): Party (stats, attribute points, play as), Equipment, Abilities (pick each hero's special).

Every boss ends in a READ / REACH / BIND / STRIKE choice, and choices carry across chapters. Finishing a chapter unlocks it on the title screen's chapter select.

## Open and play

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (standard build, not .NET).
2. In the Project Manager choose **Import** and pick `godot/project.godot`.
3. Press **F5**.

Difficulty (title screen or pause menu, saved between sessions): **Story** gives 10 base health with weaker, slower enemies and faster Resonance; **Normal** gives 7 health; **Hard** gives 5 health with tougher, faster enemies.

Keyboard, gamepad and touch are supported:

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | A / D, arrows | D-pad, left stick |
| Jump (again midair to levitate) | Space, Z | A |
| Strike (hold up/down to aim; three in a row = heavy finisher) | X, J | X |
| Kick (in midair: diving kick that bounces off enemies) | V, L | B |
| Special move (costs Resonance) | B, I | RT |
| Swap hero | Tab, 1 / 2 / 3 | R3 |
| Character menu (party, gear, abilities) | I, M | Back |
| Dash | C, K, Shift | RB |
| Focus to heal (hold) | Q, F | LB |
| Leave / return to body | E, P | Y |
| Full Potential | R | LT |
| Talk, rest at benches | W, Up | D-pad up |
| Pause | Esc | Start |

## How it's organized

```
scenes/main.tscn          entry scene (everything else is built from scripts)
scenes/rooms/*.tscn       one scene per room — edit these in the editor
scripts/game.gd           autoload: flags, abilities, saves, input map, fonts, all dialogue
scripts/sound.gd          autoload: sound effects, music loops, room ambience
scripts/main.gd           game loop, rooms, camera, events, combat, boss choices, ending
scripts/player.gd         the controlled hero (Max, Lana or Jason) and Max's astral form
scripts/ally.gd           party members fighting beside you in boss fights
scripts/aura.gd           hero flame auras
scripts/rig.gd            draws a design-sheet figure split at the hip (stride, bob, lean)
scripts/enemies/*.gd      infected, Choir Motes and Imps, Static Riders, exhibits, Hallway Echo, Dr. Ciencia, the Carrier, the Red Tide, Collective Cognition
scripts/anim_sprite.gd    plays the sprite-sheet frame animations
scripts/fx.gd             projectiles, beams, particles, slash arcs, glowing VFX sprites, pickups, astral platforms
scripts/hud.gd, ui.gd     HUD, dialogue with portraits, choices, title, pause, end, touch buttons
scripts/room.gd           room root: collects platforms and markers, draws animated pieces
scripts/marker.gd         exits, triggers, benches, NPCs, anchors, sigils, spawns, hazards
scripts/blocker.gd        doors and arena gates
assets/                   characters, portraits, baked room layers, art, fonts, audio
tools/generate_rooms.py   writes the starting room scenes from a table
tools/autotest.gd         scripted playthrough that saves screenshots
```

### Collision layers

| Layer | Used by |
| --- | --- |
| 1 | Solid ground and walls |
| 2 | One-way desks, tables and ledges (drop through with down + jump) |
| 3 | Astral-only platforms (only Max's astral form collides) |
| 4 | Doors (the astral form passes through) |
| 5 | Arena gates |

### Editing rooms

Open a room in `scenes/rooms/`. Move or resize the `StaticBody2D` platforms, and select nodes under **Markers** to change exits, triggers, spawns, NPC dialogue and anchors in the Inspector. Each room's painted art lives in `assets/rooms/` as background layers (`*_bg*.jpg/png`, with their parallax factors in `meta.json`), the playable layer (`*_world.png`, drawn at 1.5× and scaled down) and foreground silhouettes (`*_fg.png`). When you get final art, replace those images; the physics stays in the scenes.

### Character animation

Max, Lana, Jason, the infected student and teacher, Dr. Ciencia and the Viral Saint use frame animations sliced from their sprite sheets into `assets/anim/<character>/<anim>_<n>.png`. `assets/anim/anims.json` lists each animation's frames, speed, looping and the anchor point at the character's feet; `scripts/anim_sprite.gd` plays them. To replace an animation, swap the PNGs (any size) and update their `ax`/`ay` anchors, or add a new entry to the JSON. Dialogue portraits for Max, Lana and Jason are `assets/portraits/<who>_<expression>.png` (neutral, smile, smirk, worried, shocked, angry). Lana's and Jason's run, jump, dash and strike frames were synthesized from their standing frames (hip split, rotated legs and forearms); replace them when hand-drawn frames exist. Choir Imps and Static Riders come from pixel sprite sheets (`"pixel": true` in the JSON). Auras, shockwave rings and dust are in `assets/fx/aura`, `assets/fx/ring_*`, `assets/fx/dust_*`; glowing additive effects in `assets/fx/vfx`. The cafeteria workers still use the older single-pose rig in `scripts/rig.gd`.

## Automated playthrough

Plays all four chapters (every boss and elite fight and choice, the worker rescue, hero swaps, specials, loot, the character menu, and each chapter's end screen), saving a screenshot at each step:

```
godot --path godot -- --autotest /tmp/sakawa_shots
```

## Exporting

Install export templates from **Editor → Manage Export Templates**, then **Project → Export** and add presets for Windows, macOS, Linux, Android, iOS or Web. The project uses the Compatibility renderer so it runs on phones and in browsers.

Fonts are Cinzel and Spectral (SIL Open Font License, see `assets/fonts/OFL-*.txt`).
