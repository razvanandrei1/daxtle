# Daxtle — Music & Sound Design Requirements

**Version:** 1.0
**Date:** March 2026
**Contact:** Razvan Andrei

---

## 1. Game Overview

**Daxtle** is a minimalist mobile puzzle game (iOS & Android, portrait orientation). The player slides colored blocks across an irregular grid to land each on its matching-color target. There are no timers in the main campaign, no lives, no fail state — the experience is meditative and cerebral, like solving a chess problem.

The game's predecessor, **Inertix — Minimalist Puzzle**, was an App Store Editor's Choice ("Best new games", August 2023). Daxtle aims for the same level of polish and the same "mellow, meditative puzzler" identity.

**Visual style:** Clean, minimalist. Muted color palette, smooth tween-based animations. The feel is calm, focused, and elegant.

**Target audience:** Puzzle lovers who enjoy logic games (think Monument Valley, .projekt, Baba Is You). All ages.

---

## 2. Audio Direction & Mood

### Overall Tone
- **Calm, meditative, focused** — the player is thinking, not rushing
- **Minimal and elegant** — match the visual minimalism; less is more
- **Satisfying** — every interaction should feel tactile and rewarding
- **Non-intrusive** — audio should enhance concentration, never break it

### Reference Games (for mood, not direct imitation)
- Monument Valley (ambient, ethereal)
- Threes! (playful, warm, satisfying micro-sounds on every slide)
- .projekt (clean, minimal sound design)
- Mini Metro (generative, rhythmic, satisfying)

### Technical Requirements
- Engine: Godot 4.6
- Music format: OGG Vorbis (`.ogg`), loopable
- SFX format: WAV (`.wav`), short clips
- The game has independent music and SFX volume toggles — all assets must work well in isolation

---

## 3. Music

### 3.1 Background Music — Main Loop

**File:** `music_bg.ogg`
**Usage:** Plays continuously across all screens (menus and gameplay). Loops seamlessly.

**Requirements:**
- **Duration:** 1–2 minutes before seamless loop point
- **Tempo:** Slow to moderate (~60–80 BPM). The player needs to think — the music should support that, not compete with it
- **Mood:** Ambient, contemplative, slightly warm, and optimistic. Think "quiet focus with a gentle uplift" — like studying in a calm, sun-lit room. The music should carry a subtle sense of hope and positivity without becoming cheerful or upbeat
- **Instrumentation suggestions:** Soft piano, ambient pads, gentle plucked strings, muted bells/chimes, subtle electronic textures. Avoid percussion-heavy arrangements
- **Dynamics:** Even and understated. No sudden crescendos, drops, or dramatic shifts. The player may sit on a single puzzle for minutes — the music should never feel repetitive or pushy during that time
- **Key/harmony:** Open, unresolved harmonies work well (suspended chords, gentle dissonance). Avoid anything that feels conclusive or "finished" — the loop needs to breathe indefinitely
- **Loop:** Must loop seamlessly with no audible click, gap, or jarring transition. The end should flow naturally back into the beginning

**What to avoid:**
- Anything energetic, urgent, or rhythmically driving
- Melodies that are too catchy or "sticky" — the music should float in the background
- Dark, tense, or melancholic moods — this is a relaxing game, not a thriller
- Chiptune or retro aesthetics — the visual design is modern and clean

### 3.2 Future Consideration (Not Required for MVP)

For a future update, we may want:
- A second music track for Challenge Mode (slightly more rhythmic/tense, since there's a timer)
- A win celebration musical sting (short, 2–3 seconds)
- Adaptive music layers that respond to puzzle progress

These are **not needed now** but worth designing the main loop with potential layering in mind.

---

## 4. Sound Effects

All sound effects should feel **clean, satisfying, and minimal**. Think of the tactile "click" of a well-made physical puzzle toy. Each sound should be short, distinct, and never annoying on repetition — the player will hear these hundreds of times.

### 4.1 UI Sounds

#### `click.wav` — Button Press
**Trigger:** Every button tap in the game (menu buttons, settings toggles, level cells, back arrows, popup buttons). This is the single most frequent UI sound.
**Duration:** ~50–100ms
**Character:** Soft, tactile click or tap. Like pressing a well-designed physical button. Subtle but confirming.
**Notes:** Must not be fatiguing on rapid repetition (e.g., browsing level select). Should feel "premium" and minimal.

---

### 4.2 Gameplay Sounds

#### `sfx_slide.wav` — Block Movement
**Trigger:** When the player swipes and one or more blocks successfully slide to a new position on the grid.
**Duration:** ~100–150ms (the animation duration is synced to this sound's length, so this is critical)
**Character:** Smooth, satisfying slide or glide. Like a wooden block sliding across a polished surface. Should convey movement and weight without being heavy.
**Notes:** This is the core gameplay sound — heard on every valid move. Must feel great on the 500th repetition. Consider a very subtle pitch variation system (±5%) to avoid monotony (we can handle this in code if you provide a single base sound).

#### `sfx_invalid.wav` — Blocked Movement / Wall Hit
**Trigger:** When the player swipes but block(s) cannot move (hitting a wall, another block, or edge of the board). Accompanied by a visual "nudge and spring-back" shake animation (~0.4s).
**Duration:** ~150–250ms
**Character:** A soft, muted "thud" or "bump." Not punishing — the game has no fail state, so this should feel like gentle feedback ("nope, try another way"), not an error buzzer.
**Notes:** Should pair well with the spring-back animation. A slight bounciness to the tail would feel natural.

#### `sfx_reset.wav` — Level Reset
**Trigger:** When the player double-taps to reset a level. All blocks smoothly slide back to their starting positions simultaneously (~0.3s animation).
**Duration:** ~200–350ms
**Character:** A gentle "rewind" or "whoosh-back" sound. Like pieces being swept back into position. Should feel refreshing, not penalizing — resetting is a normal part of puzzle-solving.
**Notes:** Slightly longer than the slide sound to distinguish it. Should convey "fresh start."

#### `sfx_win.wav` — Level Complete / Victory
**Trigger:** When all blocks land on their matching targets. Accompanied by a celebration animation: blocks flash twice, arrows shrink, then the entire board cascades out in a diagonal wave (~2s total sequence).
**Duration:** ~800ms–1.5s
**Character:** A bright, warm, satisfying chime or ascending tone. The "aha!" moment. Should feel rewarding without being over-the-top — think quiet pride, not fireworks. A gentle ascending arpeggio or bell sequence would work well.
**Notes:** This is the emotional payoff of the entire gameplay loop. Should be the most "musical" of all the SFX — a small moment of beauty. Should blend well with the background music.

#### `sfx_destroy.wav` — Block Destruction
**Trigger:** When a moving block (B) lands on a destroy block (D), both are removed from the board. The visual shows a quick flash (fade out/in, ~0.2s) followed by the block scaling up slightly then shrinking to zero (~0.26s).
**Duration:** ~200–350ms
**Character:** A crisp, satisfying "crumble" or "dissolve" sound. Like a glass piece shattering softly or a crystalline break. Should feel impactful but not aggressive — destruction is a valid puzzle mechanic, not a punishment.
**Notes:** Should sync with the flash-then-shrink animation. A two-phase sound (bright flash hit + trailing dissolve) would match the visual well.

#### `sfx_teleport.wav` — Portal Activation
**Trigger:** When a block enters a teleport portal and reappears at the paired exit portal. The visual shows the block shrinking at the entrance (~0.14s), snapping to the exit, then popping back to full size (~0.18s). Both portals flash simultaneously.
**Duration:** ~250–400ms
**Character:** A short, sci-fi-tinged "warp" or "phase shift" sound. Something ethereal — a shimmer, a soft synthesized swoosh, or a quick crystalline tone. Should feel magical but grounded within the game's minimal aesthetic.
**Notes:** Should have two distinct phases if possible — an "in" (shrink) and "out" (pop) — or at least feel like a complete journey rather than a single event.

---

### 4.3 Sound Effects Summary Table

| File | Event | Duration | Feel | Frequency |
|---|---|---|---|---|
| `click.wav` | Button tap (all UI) | 50–100ms | Soft tactile click | Very high |
| `sfx_slide.wav` | Valid block move | 100–150ms | Smooth glide/slide | Very high |
| `sfx_invalid.wav` | Blocked move / wall hit | 150–250ms | Soft thud/bump | Medium |
| `sfx_reset.wav` | Level reset (double-tap) | 200–350ms | Gentle rewind/whoosh | Low-medium |
| `sfx_destroy.wav` | Block destruction | 200–350ms | Crisp crumble/dissolve | Low |
| `sfx_win.wav` | Level complete | 800ms–1.5s | Warm ascending chime | Low |
| `sfx_teleport.wav` | Portal teleport | 250–400ms | Ethereal shimmer/warp | Low |

---

## 5. Interaction Map — When Each Sound Plays

### Main Menu
| Action | Sound | Visual |
|---|---|---|
| Tap any button | `click.wav` | Button scales up then back (0.21s pulse) |
| Screen transition | — (silent) | Crossfade (0.18s + 0.18s) |

### Level Select
| Action | Sound | Visual |
|---|---|---|
| Tap level cell | `click.wav` | Cell scales up then back (0.21s pulse) |
| Swipe between pages | — (silent) | Horizontal snap scroll |

### Settings
| Action | Sound | Visual |
|---|---|---|
| Toggle any setting | `click.wav` | Toggle scales up then back (0.21s pulse) |
| Tap back arrow | `click.wav` | Arrow scales up then back |

### Gameplay — Level Intro (all silent, ~3–4s)
| Step | Sound | Visual |
|---|---|---|
| Board appears | — | Squares scale in via diagonal wave (0.72s) |
| Blocks appear | — | Blocks scale in with stagger (0.36s each) |
| Arrows appear | — | Arrows fade in on each block (0.10s) |
| Tutorial message | — | Message fades in (0.35s, delayed 0.5s) |

### Gameplay — Player Actions
| Action | Sound | Visual |
|---|---|---|
| Valid swipe | `sfx_slide.wav` | Blocks slide to new position (~0.13s) |
| Blocked swipe | `sfx_invalid.wav` | Blocks nudge toward wall then spring back (~0.4s) |
| Block lands on destroy block | `sfx_destroy.wav` | Flash → scale up → shrink to zero; both blocks removed |
| Block hits portal | `sfx_teleport.wav` | Block shrinks → teleports → pops out; portals flash |
| Double-tap reset | `sfx_reset.wav` | All blocks slide back to start simultaneously |
| All blocks on targets | `sfx_win.wav` | Flash × 2 → arrows shrink → board cascades out (~2s) |
| Stuck (no moves left) | — (haptic only) | Board shakes side to side (~0.42s), then auto-resets |

### Popups
| Action | Sound | Visual |
|---|---|---|
| Popup appears | — (silent) | Scale in from 0.9 → 1.0 (0.3s) |
| Tap popup button | `click.wav` | Button pulse |
| Popup dismisses | — (silent) | Scale out 1.0 → 0.9 + fade (0.2s) |

---

## 6. Technical Specifications

| Property | Requirement |
|---|---|
| Music format | OGG Vorbis (`.ogg`) |
| SFX format | WAV (`.wav`), 16-bit or 24-bit |
| Sample rate | 44.1 kHz |
| Channels | Stereo for music, mono for SFX |
| Loudness | Normalize to -14 LUFS (music), -12 LUFS (SFX) |
| Naming | Exact filenames as specified above — the game code already references them |
| Loop points | Music must loop seamlessly (Godot uses the file's native loop point or loops from start) |

---

## 7. Deliverables Checklist

- [ ] `music_bg.ogg` — Background music loop (1–2 min)
- [ ] `click.wav` — UI button press
- [ ] `sfx_slide.wav` — Block slide
- [ ] `sfx_invalid.wav` — Blocked movement
- [ ] `sfx_reset.wav` — Level reset
- [ ] `sfx_win.wav` — Level complete
- [ ] `sfx_destroy.wav` — Block destruction
- [ ] `sfx_teleport.wav` — Portal teleport
- [ ] Source/project files for all assets (for future revisions)

---

## 8. Revision Notes

- We'd like to hear **2–3 short mood demos** (15–30 second sketches) for the background music before full production, so we can align on direction early.
- For SFX, an initial batch of all 7 sounds in draft quality is preferred over one perfect sound at a time — we want to hear them together in-game.
- Feedback turnaround: We can provide in-game recordings showing the sounds in context within 24–48 hours of receiving assets.
