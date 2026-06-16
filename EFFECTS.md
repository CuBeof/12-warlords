# 12 Warlords — Board & Tile Effects (Juice / Game Feel)

> Companion to [SPEC.md](SPEC.md) (mechanics) and [DESIGN.md](DESIGN.md) (content).
> This document defines the **feel** — what makes every match "satisfying and eye-catching."
> All numbers (ms, scale, trauma) are **starting balance knobs**, tuned during playtest. Engine: **Godot 4.6**, target **Android**.

---

## 0. Philosophy: why match-3 is addictive

The dopamine loop of match-3 lives in the **cascade crescendo** — each tier of feedback must be *bigger than the last*. 7 backbone principles:

1. **Anticipation:** a gem *swells + brightens for ~80–120ms* BEFORE it vanishes. The eye must register "this group is about to pop" → so the pop feels earned.
2. **Squash & Stretch:** a falling gem stretches; on landing it squashes then bounces. Objects with "weight" = satisfying.
3. **Hitstop (freeze frame):** a 40–120ms freeze at the moment of impact (crit, match-5) → creates "weight."
4. **Follow-through:** flying particles, debris, jumping numbers, sliding bars — the *consequences* of an action extend the feeling.
5. **Escalation:** the higher the combo → the higher the audio pitch, the stronger the shake, the hotter the colors, the closer the zoom.
6. **Readability first:** VFX **must not obscure gem faces for long**. Particles fly *above* tiles, live briefly; the gem face is always legible. Pretty but cluttered = *slop*.
7. **Restraint:** normal match-3s get *light* juice; save the "fireworks" for match-5/high-combo/crit → the contrast creates the climax. If everything shakes, nothing is memorable.

---

## 1. The Effect Grammar

Every effect shares one "vocabulary" so the game feels coherent. This is a *constants library* (place it in an `FXConstants.gd` / Resource).

### 1.1. Timing tiers
| Tier | Duration | Used for |
|---|---|---|
| `INSTANT` | 0–80 ms | flash, snap, impact |
| `QUICK` | 100–180 ms | tile select, number pop, gem pop |
| `NORMAL` | 200–300 ms | swap, fall, refill |
| `HEAVY` | 350–600 ms | match-5 lightning, area sweep, skill |
| `FINISHER` | 700 ms+ | takedown, boss phase shift, victory |

> The **effect-speed slider** (SPEC §56) multiplies *all* tween durations (0.5×–1.5×). Hitstop & shake multiply *less* (e.g. 0.75×–1.0×) so "weight" isn't lost at fast speed.

### 1.2. Easing (Godot `Tween`)
| Situation | Trans / Ease | Why |
|---|---|---|
| Pop/scale in | `TRANS_BACK` / `EASE_OUT` | overshoots then settles → "snap" |
| Pop/scale out (elastic) | `TRANS_ELASTIC` / `EASE_OUT` | over-oscillates → lively |
| Gem swap | `TRANS_BACK` / `EASE_IN_OUT` | slight overshoot on swap |
| Fall (gravity) | `TRANS_QUAD`/`TRANS_CUBIC` / `EASE_IN` | accelerates like gravity |
| Land (bounce) | `TRANS_BOUNCE` / `EASE_OUT` | physical bounce |
| Number rise | `TRANS_QUAD` / `EASE_OUT` | slows as it rises |
| Health/mana bar | `TRANS_CUBIC` / `EASE_OUT` | smooth drift |
| Fade | `TRANS_SINE` / `EASE_IN_OUT` | natural |

### 1.3. Screen-shake scale (trauma 0..1)
Use the **trauma + Perlin noise** model (smooth, not mechanically jerky). `shake = trauma²`.
| Event | Trauma added |
|---|---|
| Select/valid swap | 0.0 |
| Normal match-3 | 0.0 (optional 0.05) |
| Match-4 (+turn) | 0.15 |
| L/T match (area shock) | 0.25 |
| Match-5 (lightning) | 0.35 |
| Normal hit lands | 0.15 |
| **Crit** | 0.45 |
| Per combo tier (≥3) | +0.05 (cumulative, cap ~0.6) |
| Boss heavy attack | 0.5 |
| Takedown / victory | 0.6 |

> **Mobile:** *roll* (rotational) shake easily causes nausea → keep it tiny or off; prefer *translational* shake. Provide a **"Reduce shake"** toggle (accessibility).

### 1.4. Hitstop (freeze frame, `Engine.time_scale`)
| Event | Real time |
|---|---|
| Normal match | 0 ms |
| Match-4/5 impact | 40–60 ms |
| **Crit** | 80–120 ms |
| Combo milestone (every 3 tiers) | 50 ms |
| Takedown | 150–250 ms (+ slow-mo) |

### 1.5. Sensory profile of the 5 tiles (color / particles / sound / flash)
> Tile names follow [DESIGN.md](DESIGN.md) §4 (generic, international). Inline mentions below may abbreviate — meaning unchanged.

| Tile (DESIGN §4) | Core color (suggested) | Burst particles | SFX | Flash |
|---|---|---|---|---|
| **Blade** ⚔️ (attack) | `#E0413A` steel red | sharp shards + sparks | metallic "ring" | white→red |
| **Heart** ❤️ (health) | `#4FC76A` jade green | petals / soft orbs | soft chime | green |
| **Coin** 🪙 (money) | `#F2C14E` gold | coins + sparkle | coin jingle | gold |
| **Spark** ⚡ (energy) | `#3FA7E0` blue | energy motes + ripple | rising electric hum | cyan |
| **Rune** 🔮 (exp) | `#8E6FD8` purple | glowing glyph shards | mystic chime | purple |
| **Prism** ✨ (enhanced) | gold rim + white core | rainbow sparkle | clear "shimmer" | bright gold |

---

## 2. Gem & board lifecycle

### 2.1. Idle (board at rest)
- **Breathing:** each gem sways/glows ever so slightly via `TIME` in a shader, **phase-offset by `(x+y)`** so they don't pulse in unison. Extremely cheap (GPU, no CPU). Scale amplitude ±2%, opacity ±5%.
- **Hint:** after `HINT_DELAY` (default 5s, toggleable — SPEC §56) of no input → one valid move *bobs gently + glows* on a loop. Use an `AnimationPlayer` loop, stop immediately when the player touches.

### 2.2. Select & swap
| State | Effect |
|---|---|
| Touch/select | gem scales →1.12, rim glow, slight drop shadow (lifted). `QUICK`, `TRANS_BACK`. |
| Drag | gem follows the finger, a valid target cell *highlights its frame*. |
| **Valid swap** | the 2 gems swap *along an arc*, slight overshoot. `NORMAL`, `TRANS_BACK/EASE_IN_OUT`. Then enters the match chain. |
| **Failed swap** (SPEC §23) | swap then *snap back*, with a **"head-shake" jitter** (horizontal shake 2–3 times, small amplitude) + a red **✕** flash. Then trigger the *penalty* (see §4.6). |

### 2.3. Fall & refill (the feeling of weight)
- **Fall:** `TRANS_CUBIC/EASE_IN` (accelerating). Longer fall distance → longer time (consistent velocity), **stagger** by column so it's not a "uniform block."
- **Landing:** **squash** scale `(1.15, 0.85)` then elastic back to `(1,1)` — `TRANS_ELASTIC/EASE_OUT`, `QUICK`. This is the "secret sauce" of match-3; don't skip it.
- **Spawning new gems:** fall in from above the board edge, fade in over the first 60ms. An **enhanced (Prism)** gem spawns with a sparkle telegraph.
- **Impact dust:** each landing emits 2–4 small dust particles at the gem's foot (pooled, ~150ms life).

### 2.4. Board reshape & out-of-bounds dissipation (morph)
> The VFX side of [DESIGN.md](DESIGN.md) §5.6 (gimmicks **A6 Reshape** / **B6 Gravity Field**). The deterministic pipeline lives there; here is how it *feels*.

- **Telegraph first (non-negotiable).** One turn before the morph, overlay the **new-shape ghost outline** (a dim mask) over the board + a small countdown pip; **cells about to become VOID pulse red**; the boss portrait casts. The player must never be surprised by a board that ate their tiles.
- **The morph.** The board frame/mask edges tween to the new shape (`NORMAL`→`HEAVY`, `TRANS_CUBIC`); soon-to-be-VOID cells darken as the edge sweeps over them.
- **Dissipation VFX — must read as *lost, not matched*.** Out-of-bounds tiles **dissolve/disintegrate** (a noise-threshold dissolve shader, or crumble into ash/embers that drift off-board and fade), pulled slightly *outward* past the board edge. Keep it **clearly different from the match-pop burst**, and pair it with a soft **"whoosh/disintegrate" SFX — not** the satisfying match chime, so the brain codes it as a loss. Pooled; cap the particle count when a whole row goes at once. **Prism** tiles get a brighter "shatter." No damage number, no value popup.
- **Re-settle under non-standard gravity.** Tiles flow toward the **new** gravity direction — **orient squash/stretch to the flow axis** (stretch along travel; squash against the wall they land on, e.g. up-gravity tiles squash on their *top* edge). Stagger per lane.
- **Refill from the correct edge.** New tiles stream in from the **new intake edges** (animate the spawn from that edge — not always the top).
- **Settle.** Landing dust on the new resting walls + a small board "settle" shudder (trauma ~0.1) when the morph completes.
- **Settings.** Effect-speed scales the morph duration; *reduce-motion* keeps the morph (it is gameplay-critical) but may drop the extra ash particles and the settle shudder.

---

## 3. Feedback per match type

The common frame for **every** match: **(a) Anticipation** → **(b) Apply mechanics** (damage first, per SPEC §33) → **(c) Vanish + Burst** → **(d) Follow-through** (numbers/bars/particles).

### 3.1. Match-3 (normal — "no extra effect" *mechanically*, but still light juice)
1. The 3 gems **swell →1.2 + flash the tile color** for 90ms (anticipation).
2. **Vanish:** scale→0 with `TRANS_BACK/EASE_IN` (suck toward center) over 80ms.
3. **Burst:** 6–10 tile-colored particles scatter (pooled), 250–350ms life.
4. A small value number pops at the group's center (see §5). No shake (or 0.05).
> Match-3 must be *snappy and satisfying*, since it happens most often. Don't make it heavy.

### 3.2. Match-4 straight → **+1 turn** (SPEC §14)
- Like match-3 but with a **bigger burst** and a **light streak running along** the line of 4 gems (additive) before they pop.
- Trauma 0.15, hitstop 40ms.
- Trigger the **"+1 TURN" banner** (see §4.5) — this is the main reward, it must stand out.

### 3.3. Match-5 straight → **+1 turn + lightning destroys 3 tiles** (SPEC §15)
- Longer anticipation (120ms), the 5 gems glow white.
- **LIGHTNING:** 3 *zig-zag* bolts fire from the match center to 3 targets (each drawn with `Line2D` + glow, or a bolt shader). Targets *flash white* then explode.
- A **white-cyan screen flash** for 60ms (opacity ≤0.3 — respects the "reduce flashes" toggle), trauma 0.35, hitstop 50ms, **thunder** (SFX).
- "+1 TURN" banner.

### 3.4. L/T match → **shock 3 tiles around the spot, radius 2** (SPEC §16)
- A **shockwave** ring expands from the L/T junction (an expanding ring shader), trauma 0.25.
- The 3 tiles in radius get *small lightning* + explode. Differs from match-5 in that it's a **local center** (radiating out) rather than 3 bolts firing far.

### 3.5. **Prism** tiles (enhanced, ×2 — SPEC §17)
- While on the board: a **gold rim-light** + slow rotating sparkle (additive overlay sprite).
- When cleared: a burst **twice as big**, bright gold, a **"×2" popup** pops out, brighter flash, trauma +0.05 over the normal version.

### 3.6. **Upgrade on match** ("gold flash" — SPEC §20)
- At the exact moment *before clearing*, one gem in the group **flashes gold + scale-jitters** (80ms) so the player clearly sees "this one just became ×2," then it pops with the group at doubled value.

---

## 4. ⭐ Combo / Cascade — the heart of "satisfaction"

Combo (SPEC §21) = a cascade that still matches after refill. **Value × combo.** This is where the most juice is poured, along an **escalation** curve.

### 4.1. The Combo Counter
- The HUD top-center shows **"COMBO ×N"**; each tier **pops scale + shifts to a hotter color**, with slight *text jitter* when high.
- Resets smoothly (fade + shrink) when the cascade ends.

### 4.2. Escalation ramp
| Combo | Counter color/text | Trauma | SFX pitch | Extra |
|---|---|---|---|---|
| 1 | white, normal | 0 | 1.00× | — (the match from a swap) |
| 2 | white | +0.05 | 1.06× | zoom-in 1.01× |
| 3 | **gold**, stronger pop | +0.05 | 1.12× | hitstop 40ms, vignette pulse |
| 4 | gold | +0.05 | 1.19× | — |
| 5 | **orange**, bigger | +0.05 | 1.26× | light bg flash, banner *"NICE!"* |
| 6–7 | orange→red | +0.05 | rising | darken bg + "spotlight" onto the board |
| 8–9 | **red**, jittering text | +0.05 | rising | chromatic-aberration flicker |
| 10+ | **rainbow/gold**, *"INCREDIBLE!"* | cap ~0.6 | cap | **slow-mo 0.85× ~300ms**, rainbow particle rain |

### 4.3. Audio pitch (the secret sauce)
Each cascade tier plays **a note a semitone higher**: `pitch = base * pow(1.0595, min(combo-1, 12))`. This is what creates the classic "rising" feeling (Bejeweled/Candy Crush). **Reset the pitch** each new turn.

### 4.4. Rhythm & readability
- Each cascade tier should have a **very short beat of pause** (e.g. 70–120ms between bursts) so the eye keeps up and the ear catches each note — don't let the cascade blur into chaos.
- The `HEAVY` tier is reserved for high combos; low combos stay `QUICK` so it doesn't drag.

### 4.5. The **+1 TURN** banner (Extra Turn — SPEC §14/22)
- A **banner** slides in from the edge: *"+1 TURN"* (i18n key `ui.battle.extra_turn`), gold text with a bright outline, and **the player's turn frame *pulses bright*** + a gold glow.
- A high "ding" SFX; can **freeze briefly 60ms** for emphasis.
- **Cap +2 (SPEC §22):** when the cap is reached, the next instance shows **"MAX"** (dim, small) instead of "+1" → so the player understands why it stops adding, avoiding a "the game cheated me" feeling.

### 4.6. Failed swap — the penalty (SPEC §23)
It must *feel like a punishment*, not be ambiguous:
1. Gem snaps back + red ✕ + "head-shake" (§2.2).
2. **The opponent portrait lunges forward**, swinging a weapon.
3. A sword flies at **the player** (= damage of 2 Blade tiles); on hit → red screen-edge flash + trauma 0.2 + a red damage number.
4. A low "stumble/whiff" SFX.

---

## 5. Floating numbers & stat bars

### 5.1. Value/damage numbers
- **Pop + rise + fade.** Spawn at the event center, scale punch (`TRANS_BACK`), rise ~64px, fade over the last 60%.
- **Size/color tiers:** normal = small white; large = gold; **crit = big red + outline + jitter** (SPEC §33), size ×1.6.
- **Merge numbers (one big number is far more satisfying than many small ones):** within one clear of the same type, **sum into a single large number** instead of spamming one per tile — clearer, more satisfying, and lighter on the machine.

### 5.2. Health / mana / special bars
- **Health drop:** the bar drifts with `TRANS_CUBIC/EASE_OUT`; leave a **"white/red trail"** lagging ~200ms (ghost bar) to show *how much was just lost* — a fighting-game trick.
- **Health/mana gain:** drifts up + a **flare** at the bar's head.
- **Mana full enough for a skill:** the skill button **lights up + pulses** + a "ready" SFX (SPEC: skills are grayed when insufficient — invert that when ready).
- **The number on the bar** counts up/down (tween the number) rather than changing instantly.

---

## 6. Combat juice

### 6.1. Normal attack (flying sword — SPEC §33)
1. Matching a Blade → **a weapon (sword/spear) flies along an arc** from the player's side to the opponent portrait, with a **trail** (`Line2D`/trail sprite).
2. **Impact:** the opponent *recoils (small knockback) + flashes white* (flash shader), emits sparks, trauma 0.15.
3. The damage number pops (§5.1). **Damage is applied BEFORE** that wave's explosions/transforms (SPEC §33) — the VFX must respect this ordering.

### 6.2. **Crit** — the climax moment
- **Hitstop 80–120ms** at the instant of impact (a freeze that creates force).
- **Big red number + jitter**, trauma 0.45, a **zoom-punch** (camera kicks in ~3% then back), optionally a **chromatic-aberration** flicker.
- A heavy SFX (drum boom + "crack"), the weapon impact throws a big spark. (SPEC §33: "large red damage number + screen shake.")

### 6.3. Armor & armor penetration (SPEC §24)
- **Blocked by armor:** the sword hits a **shield flaring "cling"**, the damage number shrinks + a *"-ARMOR"* label; block enough → the shield *cracks* progressively.
- **Armor penetration:** the shield **shatters into fragments** (shield-shard particles), the opponent's armor number drops visibly before health is deducted → the player *sees* the mechanic.
- **Minimum 1 damage:** however high the armor, there's always a *tiny bright dot* of a hit → never a silent "0."

### 6.3b. The *player's* defense when hit
- The screen edge **flashes red (vignette)**, the player portrait *jolts*, trauma by hit size. Low health (<25%) → **a constantly pulsing red vignette** + heartbeat (SFX) → tension.

### 6.4. Health & healing (SPEC §34)
- Matching a Heart → **a green light stream** flies from the gem to the portrait, the health bar rises, **+green number**.
- **Overheal (→ buff, SPEC §34):** the excess becomes a **glowing aura/shield** around the portrait + a buff icon on the HUD (each hero a distinct form — DESIGN §4).

### 6.5. Energy & skills (SPEC §36)
- Matching a Spark → **energy motes** fly to the **mana** display; when full → a **"boom"** + the skill button lights.
- **Cast skill:** each skill has its own sequence (data-driven). The common frame: the portrait *flares → skill animation → consequence on the board/opponent*. Effect kinds (SPEC §36):
  - *Direct damage:* like a magnified crit.
  - *Destroy board area:* highlight an area → simultaneous explosion → cascade.
  - *Turn-limited status:* see §7.
  - *Stat change (modifier):* a buff/debuff icon slides into the status bar.
- By default casting **ends the turn** (SPEC §36) → there's a "turn change" transition (see §8); a "keep-turn" skill doesn't.

### 6.6. Losing a life / defeat (SPEC §32)
- Health to 0: **slow-mo 0.5× + darken screen + portrait falls**, "-1 life," a cracked life icon. Sad but quick (don't over-punish emotionally).
- Retreat (SPEC §80): screen fades, banner lowers — emphasize the consequence (-1 life) but don't storyboard it.

---

## 7. Status effects (SPEC §36)

Each status = **a HUD icon + an overlay on the portrait/board + a re-tick each turn**. The player must *always see what they're afflicted with*.

| Status | Overlay | Re-tick each turn |
|---|---|---|
| **Freeze** (lose a turn) | an ice layer over the portrait/gems, cold mist | ice cracks when it expires |
| **Poison** (lose health per swap — SPEC §36) | green toxic haze around the portrait | each swap: a drip of poison + a green damage number |
| **Immunity** (by source) | a translucent energy shield | flares when it blocks the right source |
| **Increased % damage taken** | a cracked red rim + a broken-armor icon | hits land *bigger & redder* |
| **Stat buff** (modifier) | up/down arrows + a color per stat | slides in when gained, fades when it expires |

Boss-specific (DESIGN §5) reuses this set: **walls** (#5) = gray stone-veined tiles, "heavy" jitter when you try to swap; **tide** (#6) = rows covered in undulating water; **volley** (#9) = arrows stuck in the HUD.

---

## 8. Camera, post-processing & transitions

| Effect | When | Notes |
|---|---|---|
| **Screen shake** (trauma) | §1.3 | Camera2D offset + `FastNoiseLite` |
| **Zoom-punch** | crit, high combo | zoom 1.0→1.03→1.0, `TRANS_BACK` |
| **Hitstop / slow-mo** | §1.4 | `Engine.time_scale` |
| **Screen flash** | match-5, big skill | ColorRect overlay, opacity ≤0.3, **respects the reduce-flashes toggle** |
| **Vignette** | on hit / low health / high combo | fullscreen shader, cheap |
| **Chromatic aberration** | crit, combo 8+ | brief flicker, *don't overuse* (eye strain) |
| **Spotlight/darken bg** | high combo | focus attention on the board |
| **Turn change** (player↔AI) | end of turn | a "YOUR TURN / ENEMY" banner sweeps across, short (`NORMAL`), tints the edge color by side |

---

## 9. Audio (layered)

Juice is 50% sound. Principle: **layer + variation** so it never gets stale.
- **Each tile type** has a set of 3–4 SFX samples (random + pitch ±5%) → sounds "alive."
- **Combo:** the chain of rising notes (§4.3) — the single most important thing.
- **Impact** (hit/crit): a low-end "thump" + a transient "crack" + a tail.
- **UI:** select/swap/fail/skill-ready each have a clearly distinct sound.
- **Background music** avoids the frequency range of combat SFX (light ducking on crit/skill).
- Respect separate music/SFX/UI volumes (SPEC §50-53) and the toggles.

---

## 10. Godot 4.6 technical architecture (signal-driven + pooled)

> Following the `vfx-systems`/`vfx-shaders` rubrics: **don't poll `_process` to animate; use uniforms + Tween + signals; pool every one-shot through an FX Manager; shaders react to events.**

### 10.1. Organization
- **`FXManager` (autoload):** the central API — `play_clear(tile_type, pos)`, `play_attack(from,to,crit)`, `flash(node,color)`, `damage_number(...)`, `banner(key)`. Internally it **pools** sprites/particles/labels; **pre-caches** all VFX scenes on level load.
- **`ShakeManager` / Camera2D:** holds `trauma`; everywhere else only calls `add_trauma(x)`.
- **`Hitstop`:** a queue so hitstops don't chaotically overlap.
- **Presentation separate from logic:** `BoardModel` (pure, headless) emits **signals** (`match_cleared`, `tile_fell`, `combo_changed`, `attack_dealt`, `extra_turn`...) → `BoardView`/`FXManager` *listen* and perform. Logic knows nothing of VFX. (Matches the `BoardModel`/`BoardView` split in DESIGN §7.2.)
- **Complex choreography** (match-5 lightning, skill casts): use an **`AnimationPlayer` method-track** to sync SFX/VFX *frame-perfectly* (the 2d-animation rubric: "method-track triggers"), rather than scattering manual `await`s.

### 10.2. Code patterns (starting points)

**Screen shake (trauma + noise):**
```gdscript
extends Camera2D
@export var decay := 1.5
@export var max_offset := Vector2(22, 14)
var _noise := FastNoiseLite.new()
var _t := 0.0
var trauma := 0.0

func _ready() -> void:
    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    _noise.frequency = 0.6

func add_trauma(amount: float) -> void:
    trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
    if trauma <= 0.0:
        offset = Vector2.ZERO; return
    trauma = maxf(trauma - decay * delta, 0.0)
    var amt := trauma * trauma                 # squared -> punchy, decisive
    _t += delta * 30.0
    offset = Vector2(
        max_offset.x * amt * _noise.get_noise_2d(1.0, _t),
        max_offset.y * amt * _noise.get_noise_2d(99.0, _t))
```

**Hitstop (runs in real time even when time_scale=0):**
```gdscript
func hitstop(duration := 0.06, scale := 0.0) -> void:
    Engine.time_scale = scale
    # last arg ignore_time_scale = true -> the timer still runs
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
```

**Reusable pop scale (anticipation/bounce):**
```gdscript
func pop(node: Node2D, peak := 1.22, dur := 0.18) -> void:
    var t := node.create_tween()
    t.tween_property(node, "scale", Vector2.ONE * peak, dur * 0.4) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    t.tween_property(node, "scale", Vector2.ONE, dur * 0.6) \
        .set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
```

**White-flash shader (canvas_item) — driven by a uniform, no CPU cost:**
```glsl
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = tex;
    COLOR.rgb = mix(tex.rgb, flash_color.rgb, flash * tex.a);
}
```
```gdscript
func flash(ci: CanvasItem, color := Color.WHITE, dur := 0.12) -> void:
    var m: ShaderMaterial = ci.material
    m.set_shader_parameter("flash_color", color)
    var t := ci.create_tween()
    t.tween_method(func(v): m.set_shader_parameter("flash", v), 1.0, 0.0, dur) \
        .set_trans(Tween.TRANS_SINE)
```

**Damage number (pooled):**
```gdscript
func damage_number(value: int, world_pos: Vector2, crit := false) -> void:
    var lbl: Label = _num_pool.acquire()         # pool, don't instantiate each time
    lbl.text = str(value)
    lbl.global_position = world_pos
    lbl.scale = Vector2.ONE * (1.6 if crit else 1.0)
    lbl.modulate = Color(1, 0.2, 0.2) if crit else Color.WHITE
    var t := lbl.create_tween().set_parallel()
    t.tween_property(lbl, "global_position:y", world_pos.y - 70.0, 0.6) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.25)
    t.chain().tween_callback(func(): _num_pool.release(lbl))
```

### 10.3. Android performance (don't let juice kill FPS — the "Performance/Fill" & "LOD" rubrics)
- **Pool everything:** gems, burst particles, numbers, banners. A big cascade must *not* `instantiate()` in a loop → stutter.
- **`GPUParticles2D`** for bursts is fine on modern Android, but **`one_shot=true` + pool**; **cap the concurrent particle count**. Weak devices: drop to **pooled sprite-bursts** + shaders.
- **3 VFX quality tiers (LOD):** High / Medium / Low — fewer particles, disable advanced chromatic/vignette, reduce screen-shake. Auto-detect by FPS or let the player choose.
- **Shaders:** `step()` instead of `sin()` on hot paths; avoid stacking many fullscreen overlays; merge vignette/flash into one pass if possible.
- **A shared atlas** for tiles + gems + particles → fewer draw calls.
- **Measure on a real** mid-range device, not just the editor.

### 10.4. Respect player settings (SPEC §55-56 + accessibility)
| Option | Effect |
|---|---|
| **Effect speed** (already in SPEC §56) | multiplies all tween durations (0.5×–1.5×) |
| **Reduce screen shake** | scale trauma ×0 |
| **Reduce flashes** | disable screen-flash & chromatic (photosensitivity safety) |
| **Hide hints** (SPEC §56) | disable the hint §2.1 |
| Music/SFX/UI volume (SPEC §50-53) | the corresponding bus |

---

## 11. "Anatomy" of a satisfying match (sample timeline)

Example: the player swaps to make a **match-4 of Blades**, causing a cascade up to **combo 3**, with one crit.

```
t=0ms     Touch & swap: the 2 gems swap along an arc (TRANS_BACK), "swish" SFX.
t=180ms   Match-4 resolves: 4 gems swell 1.2 + white-red flash (anticipation), line-streak runs along.
t=240ms   APPLY DAMAGE FIRST (SPEC §33): the sword flies to the opponent.
t=300ms   The sword lands = CRIT -> hitstop 100ms, big red jittering number, trauma 0.45, zoom-punch, "crack".
t=400ms   The 4 gems vanish (suck to center) + red burst; "+1 TURN" banner slides in, turn frame pulses gold, "ding".
t=470ms   Gems fall (TRANS_CUBIC), staggered by column.
t=620ms   Landing: squash & bounce (TRANS_ELASTIC) + dust.
t=680ms   Cascade! combo=2: higher SFX note, counter pops gold, trauma +0.05, zoom 1.01.
t=820ms   Cascade! combo=3: an even higher note, hitstop 40ms, vignette pulse, "NICE!" banner.
t=950ms   Cascade ends: combo counter fades-shrinks; the total damage number (already ×combo) is added; the opponent's health bar drifts + ghost-bar.
t≈1.0s    Because of +1 turn -> NO turn change; the player's frame stays lit, inviting another move.
```

> The whole chain is ~1 second but has **3 distinct climaxes** (crit → +turn → combo) thanks to short pauses & a rising audio pitch. That is "satisfaction."

---

## 12. To-do (suggested order)
1. **`FXManager` + pool + `ShakeManager` + `hitstop`** (the reusable infrastructure).
2. **The gem lifecycle:** select → swap → vanish/burst → fall (squash) → refill. Make *bare match-3* feel satisfying first.
3. **The combo crescendo** (counter + SFX pitch + the §4.2 ramp) — invest the most here.
4. **Combat:** flying sword + crit + armor/shield + jumping numbers.
5. **The +turn banner / +2 cap / failed-swap penalty.**
6. **Status & boss-gimmick overlays** (hook into DESIGN §5).
7. **LODs + settings + measure FPS on a real device.**

> The golden rule: **make "one match" satisfying first, then multiply it across the whole game.** If bare match-3 doesn't feel good, no boss or story will save it.
