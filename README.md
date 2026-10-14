# SAKAWA: Astral Max

A 2D action-platformer in the spirit of Hollow Knight, built from the *SAKAWA: Astral Max Story & Game Bible*.

**Chapter One — Class Famine** (playable vertical slice)

- Four painted parallax rooms: Room 101, East Hall, the Cafeteria, and Dr. Ciencia's Sub-Basement Lab.
- Detailed character portraits with expressions for Max, Lana, Jason, Dr. Ciencia and the Choir.
- Astral projection on a 60-second timer: your body stays behind while your astral self passes through doors and reaches hidden platforms.
- Resonance (heal by focusing), Full Potential (a burst with a permanent cost), and a Levitation upgrade.
- Two bosses — the Hallway Echo and Dr. Ciencia — each resolved with READ / REACH / BIND / STRIKE choices that feed hidden Connection / Control / Rupture and Witness values.

## Play

Open `index.html` in a browser, or deploy the folder as a static site (Netlify config included). No build step.

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | A / D or arrows | ◀ ▶ |
| Jump (again midair to levitate) | Space | JUMP |
| Psychic strike (hold W/S to aim) | X | STRIKE |
| Dash | C | DASH |
| Heal with Resonance (hold) | Q | FOCUS |
| Leave / return to your body | E | PROJECT |
| Full Potential | R | FULL |
| Talk · rest at benches (saves) | W | ▲ |
| Drop through desks | S + Space | ▼ + JUMP |
| Pause | Esc | II |

## Art and sound

- Dialogue portraits for Max, Lana, Jason, Dr. Ciencia and the Choir are taken from the *Complete Illustrated Bible* model sheets and embedded in `index.html`. In-game sprites and backgrounds are drawn in code to match those designs.
- All audio is synthesized live with the Web Audio API: footsteps that change with the floor, character voice blips in dialogue, per-room ambience (classroom clock, hallway fluorescent buzz, cafeteria hum, lab bubbling), boss music (clinical percussion for Dr. Ciencia, a late heartbeat for the Hallway Echo), and effects for every attack, power and pickup. Sound and music can be toggled separately in the pause menu.

The whole game is the single `index.html` file.
