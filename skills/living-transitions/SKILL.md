---
category: engineering
name: living-transitions
description: |
  Add a new interaction to an existing UI as a continuous, animated extension of what is already there — the element on screen morphs into the new control (a blob becomes a search box, a card becomes a panel, a chart becomes a form), shows a "thinking" state in the same visual language, and resolves into the answer. Use when the user wants a feature added "in the same style", "as an extension of the current animation", wants something to "transform into" or "transition into" something else, or says they love the current look and the new part must feel native. Also use for any canvas/SVG/CSS animation work where continuity, polish and data-bound motion matter. Do NOT use for picking between several fresh design directions or for static layout tweaks.
---

# Living transitions

The goal: the new feature feels like the existing interface grew a new ability, not like
a widget was bolted on. One continuous object changes shape; nothing pops, nothing is
swapped out, nothing restarts.

## 1. Study the existing visual language before designing anything

Read the code of the element the user loves, not just a screenshot. Write down:

- **Render tech and loop.** Canvas + `requestAnimationFrame`, SVG, CSS, a library? Where
  state lives (refs vs props), what triggers re-initialisation.
- **Vocabulary.** The shapes (e.g. membranes, rings, dots, lines), their opacities, line widths,
  the one accent colour and what it already means.
- **Motion tokens.** The easing curve (e.g. a `--spring` cubic-bezier), entry animation
  (`fade-up`), durations, stagger.
- **What is bound to data.** Which properties encode real quantities and which are
  ambient texture. Keep that honesty in the new states.
- **Type and copy voice.** Lowercase captions? Mono numerals? Keep them.

Then name the user's favourite elements back to them in the plan, and say how each one
survives into the new states.

## 2. Design the feature as a phase machine on ONE object

Write the phases as a table before coding: e.g. `idle → ask → choose → thinking → result
| failed`, and for each: what the object's shape is, what overlays exist, what copy shows,
what input is accepted (Enter / Esc / arrows / click).

Principles:

- **Morph, don't swap.** The existing element becomes the new control. For a blob → pill:
  blend the radius per angle, `r = lerp(blobRadius(θ), stadiumRadius(θ), m)`, and damp the
  wobble by `(1 - m)`. The outline of the shape *is* the input's border.
- **Inner detail transforms too.** Internal nodes flatten into a band, rays retract,
  lines fade to a quieter alpha behind text. Every part has somewhere to go.
- **Thinking uses the same body.** Churn, pulse rings, faster flicker — the object
  breathes; no spinner appears elsewhere.
- **The answer is expressed by the object.** Bind it: a ring filled to the score,
  firmness from uncertainty, glow from probability, the existing accent colour only
  past a meaningful threshold. Put the number in HTML over it, counting up.
- **Copy sits where copy already sits** (the caption position), and fades between phases.
- **Always a way back.** Esc and a "Done" action morph it home.

Present the phase table, the alternatives where a real design choice exists (what morphs into
what, how the answer is expressed), and your recommendation. Wait for the operator's OK before
writing code.

## 3. Implementation rules that keep it continuous

- **Never restart the render loop for a phase change.** Pass phase props through a ref
  (`live.current = { shape, thinking, result }`) that the running loop reads. Effect
  dependencies that re-run setup re-seed random nodes and the object visibly jumps.
- **Ease inside the loop**: `m += (target - m) * k` per frame (k ≈ 0.08) gives a spring-like
  settle and interrupts cleanly mid-transition. Snap under reduced motion.
- **Share geometry constants** between canvas and the HTML overlay (centre %, width
  rule such as `min(560px, 100% - 32px)`, height), and comment in both places that they must agree.
  Fade the input in after the morph is mostly done (`transition-delay ≈ 0.2s`), focus
  it after ~300 ms.
- **Sample densely enough for the target shape.** Polar sampling that looked fine for a
  blob leaves a pill's end caps polygonal — raise the point count.
- **Effects must suit the current shape.** A ring pulse around a flat pill reads as a stray
  circle; gate it by the morph value.
- **Async hygiene.** A ticket counter drops late responses after the user moved on; a
  minimum "thinking" time (~900 ms) so fast answers don't flash; clear every busy flag
  on every path (including when one async handler hands off to another).
- **CSS trap:** an entry animation that animates `transform` (e.g. `to { transform: none }`
  with `fill-mode: both`) cancels a `translateX(-50%)` centring. Centre with
  `left: 0; right: 0; margin: 0 auto` instead.
- **Accessibility:** `prefers-reduced-motion` handled in JS as well as CSS; `role="search"`,
  `listbox`/`option` for choices, `aria-live` on the result, labelled icon buttons.
- Icons: inline SVG drawn from the same motif (e.g. a ring with a dot if the UI is built from rings),
  same stroke weight as the canvas lines, `currentColor`.

## 4. Verify frame by frame, not just "it builds"

1. Build and run the tests.
2. Serve the built UI with a tiny fixture server that fakes the APIs, including slow
   and error responses, so every phase is reachable without real data.
3. Drive it with headless Playwright (use an installed Chrome via `executablePath` if
   the browser extension is unavailable) and screenshot **every phase**, plus:
   - a frame *mid-transition* (~150 ms after the trigger),
   - phone width (390 px), checking for horizontal scroll,
   - `reducedMotion: "reduce"`,
   - each error and empty state.
4. Look at every frame. Check continuity (same node layout before and after), overlaps,
   text legibility over the animation, centring. Fix and re-shoot.
5. Replay the user flow twice in a row (ask → answer → ask again) — stuck state bugs
   only show on the second pass.
6. Run `/code-review`; race and stale-state bugs in phase machines are common.

## 5. Report

Describe the flow in the order the user will see it, say which quantities each visual
is bound to, and state plainly what was verified only with fixtures. Then teach the change per
the core contract: how the code works now (phase machine, the ref the render loop reads, where
each phase's target values come from) and the concepts it relies on by their technical names
(interpolation, easing, state machine, request ticketing).
