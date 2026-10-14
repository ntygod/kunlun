# Logical arrow routing correction

A short, isolated diagnostic copy recorded only key events delivered to the game during the requested Down/S reproduction. The actual Down event was logical `keycode=4194322` (Down), physical `4194310`, pressed, non-echo, in `world_puzzle`, with no GUI focus owner. S reported logical/physical 83. The previous main handler preferred every nonzero physical code, so this valid logical Down was ignored.

The production change is restricted to main input routing: four logical arrow keycodes take priority; other keys retain existing physical-key behavior, including WASD. No world model, proof, actor position, campaign state or save format was changed. An explicitly open action picker still retains normal arrow navigation. This finding does not establish the cause of the earlier mistimed F5 file copies.

`test_world_arrow_input.gd` drives real input events through a main subclass that records dispatched commands without mutating a game model. It covers all four arrows with matching/mismatching/zero physical codes (including the observed 4194322/4194310 pair), physical WASD under a changed logical layout, world/menu/puzzle/battle modes, focus/no-focus, repeat suppression and open picker behavior. The same 196 checks give 14 failures against the old frozen main and zero against the correction.

The original 122-row complete clean-copy suite remains evidence for `2d618eb`, not a claim that this later shared-input correction underwent that identical full suite. Focused post-change regression and a same-location graphical Down/S retest are required separately. No generic F5 correction or consumable functionality is implied.

Focused post-change results: arrow routing 196/0, menu save hotkeys 69/0, chapter-eight boundaries 234/0, chapter-eight real puzzle main 39/0, chapter-seven main 131/0 and foundation 476/0. All six final logs and the editor import are free of `ERROR`. Counts total 1,145 checks. Actual graphical repeat remains a separate owner-reported gate.
