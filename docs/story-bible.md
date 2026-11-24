# Story bible (working title: The Sealed Manor)

Vocabulary lives in [GLOSSARY.md](../GLOSSARY.md). All proper names are placeholders. Decisions that were hard to reverse are in [docs/adr/](adr/).

## Pitch

A pixel-art dark fantasy story RPG with no combat. Maren, a priestess of the Lumen Order, arrives as the new priestess of Hollowmere Manor to renew the Seal that holds Caldris, a being she has loved since childhood. The player puzzles through the manor, grounds and cathedral, is chased by things the Seal has warped, and slowly learns what the Order's blessings cost. Roughly 2 hours for one run.

Inspirations: The Witch's House, Mad Father (puzzles, chases, a story that recontextualizes), Fear & Hunger and Dark Souls (dark fantasy, a large world implied but never explained), Undertale (a deliberate route to the hidden ending).

Tone: dark fantasy, not horror. Dread and melancholy come from setting, sound and implication. Jumpscares are very rare and intentional.

## Themes

Religious trauma and guilt. Love versus faith, where the faith side has real kindness in it. Inherited duty and the cycle that continues.

## World

- **Lumen Order**: invented church. Its scripture is built from inverted fragments of the **Old Faith** it overwrote.
- **Caldris**: a being sealed beneath the cathedral. The Order calls it a demon. The Old Faith may hold it to be a god. Its body and the **Seal** are one.
- **Blessings**: magic that the city of **Vareth** gains from Caldris's imprisonment, which the Order presents as divine gifts. Vareth is mentioned but never visited.
- **The Seal** runs on the **Lychkin** heir's devotion plus periodic **Rites of Renewal** (see ADR 0001). Maren's affection for Caldris and her skipped Rite are what weakened it.
- The cathedral stands beside Hollowmere Manor on the same grounds. The manor is where the Order's priests live.

## Cast

- **Maren**: fixed female protagonist. Raised from birth as the Lychkin heir, bearing the **Mark**. Met Caldris as a child, first frightened and then comforted by him. Knows the Fragments are Caldris. The narration never says so.
- **Caldris**: sealed, tender, tragic. Appears through **Fragments** (real animals made of shadow: a dog, a crow). His dialogue grows strangely more intimate as the game goes on, and early lines plant his fear that Maren will "close the door" behind her.
- **The parent**: current Lychkin holder, living, in the cathedral. Sincerely loving, conditional on obedience. The root of Maren's religious trauma. Not a villain.
- **Edrin**: a sincere young acolyte assigned to Maren. A human helper who handles puzzles that need hands. Represents what becomes of someone who never goes against their religious captors. Sides with the Order in every ending. Reappears throughout the game and forces hard choices between him and the crow.
- **Wardens**: human enforcers of the Order. Chase Maren in the cathedral section.
- **The Bound** (placeholder name): sentient Old Faith creatures imprisoned by the Order. Non-animal, fantastical creatures in the spirit of Stardew Valley's Junimos. Optional to free, and well hidden.
- **The Warped**: mindless chasers twisted by the Seal's leak. Strangeness grows with depth. Mostly gameplay.

## Mechanics

- **Puzzles**: environmental interaction and riddles. Fair: all clues exist in the world. Old Faith inscriptions can be read two ways, the Order's and the Old Faith's.
- **Chases**: every chase is triggered by the player's own action (for example breaking a barrier). Chasers are Warped things, plus Wardens in the cathedral. Chase count is small, with each one different.
- **Chase feel (from the owner's test of the slice)**: chasers are faster than Maren's walking speed and can only be outrun by sprinting, as in The Witch's House. Rooms need obstacles to maneuver around so chases are challenging and rewarding to finish. Every chase ends as soon as the player leaves to another area, unless a chase is explicitly marked otherwise. Sprint is hold-to-run, unlimited, and works everywhere (not only in chases).
- **Saving**: RPG-Maker-style save points, 20 slots. The save point is a talking crow Fragment that appears before big puzzles and sometimes vanishes after something is completed. One save point at the Seal never vanishes.
- **No hand-holding**: no quest log tracking secrets, no warnings about saving, no UI prompt for the final decisions. The marketing says there are multiple endings, and discovering them is the player's responsibility (see ADR 0002).
- **Choices**: a hidden devotion tally only colors flavor (dialogue, epilogue tone). The endings are decided by explicit forks, never by a meter.

## Structure (working, to be redone after puzzles)

| Part | Approx. time | Content |
|---|---|---|
| Prologue | 10 min | Arrival at the manor, Edrin, the first Fragment, a tutorial puzzle |
| Act 1: manor | 30 min | Exploration, first chase, first Old Faith item, the Rite cannot be done here |
| Act 2: grounds | 20 min | Gardens, ruined chapel, graveyard, second chase, a letter from the parent |
| Act 3: cathedral | 35 min | Wardens, the parent, the descent through increasingly strange crypt levels |
| Act 4: the Seal | 15 min | The decision at the Seal |
| Finale | 10 min | The Good Ending chase is short and in the crypt. The Bad Ending chase runs through the whole manor. |

## Endings

The ending list shows "Good Ending?" first, a blank slot for further endings, and reveals the others as they are found.

**Good Ending? (default).** Maren completes the Rite. Anyone following the story's prompts gets this. The final chase is short and set in the crypt. The Fragments, including the crow and the dog, and any freed Bound pursue her, because the Rite will tighten the Seal and hurt them. The crow dies as a direct result of the player's action. The player reads Caldris as the threat; a second playthrough reads it as their fight for freedom. In the epilogue Maren is older, teaching her own child the Rite, with the child already bearing the Mark. Edrin is the implied spouse. Subtle signs show the corruption continues, and one image points back at an early act of defiance, so players get an "aha!" moment.

**Bad Ending.** Needs all three pieces of the **Verse**, each held by a Bound creature, and a deliberate choice to speak it at the Seal. The Bound's remembered version has drifted and contains a line implying Maren will betray Caldris. Hearing it is the last straw for him, already low on sanity after his imprisonment. He returns corrupted, and the final chase runs through the whole manor with him as the pursuer. When the player escapes, Maren tries to show her devotion, and Caldris appears in a vulnerable physical form. Then her parent kills him. Vareth's Blessings fail (withered crops, loose entities) and the Order falls. It is bad for everyone. Edrin witnesses it and survives. The epilogue shows the cracked door of a secret area in the crypt, with a Bound creature peeking through and closing it.

**Secret Ending.** Needs the Bad Ending requirements plus four of five Old Faith items, read correctly, plus two secret areas that lie one after the other in the cathedral crypt and form one larger region. The secret door opens through a reading puzzle with no marker. The carved original wording of the Verse lies at the end. Speaking the correct line frees Caldris uncorrupted. The Order still refuses to let him live, so Maren and Caldris choose to be sealed away together. Her Mark powers a Seal built on love instead of obedience (a redirection of ADR 0001). This new Seal no longer leaks, so the Warped stop spawning and Vareth flourishes even more. Vareth never learns the truth, and the Order survives and keeps its lies, minus its Lychkin heir. Edrin witnesses the sealing and becomes the Order's new keeper at the sealed door, but a small easter egg shows him starting to question the Order. Whether he breaks the cycle is left to the imagination. It shows only that Maren's act set something in motion. It is tragic and tender.

## Discovery design

- The Good Ending is reachable with no knowledge of the others. The other endings are never prompted.
- Bound are hidden so that a first-time player will find none or one, which can confuse them and later adds to the "aha!".
- Hints for each ending appear in the epilogue of the previous one.
- Edrin versus the crow: a few moments where helping one hurts the other. They change flavor, never the ending, since Edrin sides with the Order regardless.

## Art

Mostly bought assets for tilesets and props, with custom art for story-critical items: Maren's childhood drawing of her and the shadow dog, Fragment and Bound designs, diary pages, and ending images.

## Open questions

- Final names: the bloodline, the Bound, the Old Faith, and the ending titles.
- The puzzle designs, including the secret door's reading puzzle.
- Caldris's voice, the parent's characterization, and the Order's history.
- Seeds for the shared universe (shorter games in the same world).
