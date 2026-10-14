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

Keyboard, gamepad and touch are supported. **Every control can be remapped** in Settings → Controls (title screen or pause menu); bindings are saved to `user://sakawa_settings.json`. **PS5 DualSense, PS4 and Xbox controllers** work over USB or Bluetooth (desktop builds and the web build); prompts show PlayStation names (Cross, Circle, Square, Triangle, L1/R1/L2/R2) automatically when a PlayStation controller is detected, or pick the icon style in Settings. Controllers rumble on hits, damage, lasers and transformations (toggle in Settings).

Default bindings:

| Action | Keyboard | PlayStation | Xbox |
| --- | --- | --- | --- |
| Move | A / D, arrows | Left stick, D-pad | Left stick, D-pad |
| Jump · wall jump · air jump | Space, Z | Cross | A |
| Strike (up/down to aim; 3 in a row = finisher) | X, J | Square | X |
| Kick (midair: diving kick) | V, L | Circle | B |
| Special move (costs Resonance) | B, I | R2 | RT |
| Dash | C, K, Shift | R1 | RB |
| Focus to heal (hold) | Q, F | L1 | LB |
| Astral projection (Max) | E, P | Triangle | Y |
| Full Potential | R | L2 | LT |
| Alter ego (shinobi transformation) | T, G | L3 | LS |
| Swap hero | Tab, 1 / 2 / 3 | R3 | RS |
| Character menu | M, N | Create, Touchpad | View |
| Talk, rest at benches | W, Up | D-pad Up | D-pad Up |
| Pause | Esc | Options | Menu |

### Movement

Generous jump timing (coyote time and jump buffering), wall slides and wall jumps for every hero, automatic ledge climbing when you just miss a ledge, sliding around ceiling corners, and hold down on a desk or ledge to drop through.

Kandria-inspired additions: **wall climbing** (hold Up on a wall; a small stamina ring shows how long you can climb, refilled on the ground) and an **8-way air dash** (hold a direction while dashing in the air).

### Co-op

Title → **Co-op** (or Co-op in the pause menu):

- **Couch co-op**: plug in or pair a second controller (PS5, PS4, Xbox…). Player 2 plays whichever of Max / Lana / Jason player 1 isn't. With one controller, player 1 uses the keyboard and player 2 the controller. Works in the web build too.
- **Online co-op** (desktop builds): one player picks **Host online game** and starts or continues a game; the other enters the host's IP address and **Join**s. The host forwards UDP port 24680 on their router (or both play on the same network). The host runs the game; the guest's button presses are sent every frame and the host streams the world back 20 times a second (host-authoritative, modelled on TetraForce's networking, MIT). Browsers can't host or open UDP connections, so the web build offers couch co-op only.

Player 2 has their own health, gets knocked down instead of dying (back up in 6 seconds), shares experience and gear, and the boss allies fill in whoever isn't being played.

### Map

The character menu has a **Map** tab in the style of Knytt Stories / YKnytt: each room of the chapter is a box, lit once explored, with your position blinking, save benches and boss rooms marked.

### Alter egos

Each hero can transform into a shinobi alter ego (craftpix *Shinobi* sprites): Max becomes **Shadow** (shinobi), Lana **Ronin** (samurai), Jason **Brawler** (fighter). Transforming needs 30 Resonance and slowly burns it; while it lasts the hero runs 25% faster, jumps higher, gets an extra air jump, attacks faster and hits 1 harder.

### Menus and the LSMG arcade

The game boots with an 8-bit **Last Shot Media Group** splash (the LSMG wordmark pixelated, with a chiptune jingle). The title menu (Continue, New Game, Chapters, LSMG Arcade, Settings, Quit) and all panels use the craftpix *Cyberpunk GUI* pixel frames and buttons; the HUD sits on one of its plates. **LSMG ARCADE · LAST SHOT** is an 8-bit buzzer-beater basketball minigame: hold and release Jump to shoot, 45 seconds, 3-pointers from behind the line, the last five seconds count double, and three makes in a row put you on fire. The high score is saved.

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
scripts/hud.gd, ui.gd     HUD, dialogue with portraits, choices, title menu, settings, control remapping, pause, end, touch buttons
scripts/splash.gd         8-bit LSMG boot splash
scripts/arcade.gd         LSMG ARCADE · LAST SHOT minigame
scripts/net.gd            autoload: online co-op (ENet host/guest, snapshots)
scripts/vinput.gd         per-player input source (keyboard/pad, a specific controller, or the network)
scripts/pixelfont.gd      3x5 pixel font for the 8-bit screens
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

Fonts are Cinzel and Spectral (SIL Open Font License, see `assets/fonts/OFL-*.txt`). The shinobi alter-ego sprites (`assets/anim/*_sh`) and the GUI frames (`assets/gui`) are free craftpix.net assets (craftpix.net/file-licenses); extra sound effects (`assets/audio/u_*.wav`) come from the supplied sound pack. Third-party art and audio from open-source games are in `assets/third_party/` with per-file attribution in `assets/third_party/CREDITS.md` and the licences in `assets/third_party/licenses/` (item icons: Dan Allen, CC-BY 4.0, and Titan Tactics, CC-BY 4.0; music and sounds: Titan Tactics, CC-BY 4.0, and the Godot TPS Demo, CC-BY 3.0). The in-game Credits screen shows all of them.
