# Daxtle — Audio Design Document

## Overall Direction

All audio reinforces the calm, meditative feel of the game. SFX share a consistent material palette (wood/stone/ceramic on padded surfaces). Music sits well below SFX in the mix. Nothing should be jarring at high volume.

## Mix Guidelines

- All SFX normalized to similar perceived loudness
- Music at roughly -12dB relative to SFX
- Peak limit everything — no clipping at max phone volume
- Format: `.wav` 44.1kHz 16-bit for SFX, `.ogg` for music

---

## Background Music

**File:** `assets/audio/music_bg.ogg`

**Style:** Ambient lo-fi with a gentle pulse. Think Brian Eno's "Music for Airports" meets a cozy mobile game. No melody that demands attention — just a warm backdrop that makes silence feel intentional.

**Characteristics:**
- Soft sustained pads (warm synth or filtered piano chords)
- Very slow chord progression — 4-6 chords over a 60-90 second loop
- Key: C major or A minor (simple, calming)
- Tempo: ~70 BPM or no discernible beat at all
- Subtle texture layers: gentle vinyl crackle, soft atmospheric hiss, or distant wind
- Seamless loop point (no audible cut)
- Duration: 60-120 seconds

**Avoid:** Drums/percussion, staccato notes, anything rhythmically driving. The player should forget the music is there until they mute it.

**Prompt for AI generation:** "Ambient lo-fi calm puzzle game background music, no drums, warm pads, soft filtered piano, seamless loop, 70 BPM, meditative, minimalist"

---

## Sound Effects

### Slide — Block moves

**File:** `assets/audio/sfx_slide.wav`

**Description:** Short, soft wooden slide sound — like a smooth block gliding across felt.

**Characteristics:**
- Duration: 100-150ms
- Mid-frequency, no harsh highs
- Slight pitch variation each play would be ideal (or provide 2-3 variants and randomize)

**Reference feel:** A polished stone sliding on a wooden board.

**Prompt for AI generation:** "Short soft wooden block sliding on felt surface, subtle, game sound effect, 100ms"

---

### Invalid Move — Blocked move / shake

**File:** `assets/audio/sfx_invalid.wav`

**Description:** Muted thunk or dull tap — the block tried to move but couldn't.

**Characteristics:**
- Duration: 80-120ms
- Slightly lower pitch than the slide sound
- Soft, not punishing — the game has no fail state, so this should not feel like an error buzzer

**Reference feel:** Knocking gently on a thick wooden table.

**Prompt for AI generation:** "Soft dull wooden thunk, muted tap, gentle block hitting wall, game sound effect, 100ms"

---

### Reset — Blocks return to start

**File:** `assets/audio/sfx_reset.wav`

**Description:** Gentle whoosh with a soft landing — all blocks sliding back simultaneously.

**Characteristics:**
- Duration: 300-400ms
- Slightly longer than a single slide
- Reverse-reverb feel or a soft breathy sweep
- Ends with a subtle settling sound

**Reference feel:** A soft exhale followed by pieces settling into place.

**Prompt for AI generation:** "Soft whoosh sweep with gentle wooden settling sound, puzzle reset, calm, 350ms"

---

### Win — Level complete

**File:** `assets/audio/sfx_win.wav`

**Description:** Warm resolving chord — two or three ascending tones that land on a satisfying note. This is the reward moment.

**Characteristics:**
- Duration: 600-800ms
- Pitched higher and brighter than other SFX
- Simple marimba/xylophone arpeggio (3 notes ascending), or a soft chime chord

**Reference feel:** The sound a meditation app makes when your session ends.

**Prompt for AI generation:** "Warm ascending marimba arpeggio, 3 notes, satisfying resolution, puzzle complete chime, calm, 700ms"

---

### Teleport — Portal activation

**File:** `assets/audio/sfx_teleport.wav`

**Description:** Brief crystalline shimmer — distinct from the wooden palette of other sounds to suggest something magical/spatial.

**Characteristics:**
- Duration: 200-300ms
- Higher frequency, slightly ethereal
- A short pitch-shifted ping with reverb tail, or a soft glass chime

**Reference feel:** A tiny bell struck underwater.

**Prompt for AI generation:** "Short crystalline shimmer chime, ethereal ping with reverb, magical teleport, soft glass bell, 250ms"
