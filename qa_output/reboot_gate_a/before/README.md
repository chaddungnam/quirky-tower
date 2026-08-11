# Pre-reboot gameplay baseline

Captured on 2026-08-11 from worktree HEAD `575c21a`. The gameplay source is still the
`21f17ea` baseline; the intervening commits change only reboot documents and the Gate A plan.

## Capture

- Godot: `4.7.stable.official.5b4e0cb0f`
- Renderer: macOS Metal, Forward Mobile, Apple M2
- Source scene: `res://scenes/app/main.tscn`
- Method: one temporary `/tmp` `SceneTree` script instantiated the source scene inside a
  `SubViewport(1080, 2400)`, finished splash, opened the run, waited for the start transition,
  awaited `RenderingServer.frame_post_draw`, captured the active first-floor state, submitted
  the current challenge's success input, then captured its visible result state.
- The temporary script was not added to the repository.

| File | Dimensions | SHA-256 |
| --- | --- | --- |
| `gameplay_start_1080x2400.png` | 1080×2400 | `5c9e3846c1348887bcb5348201d5e38c5d0542c017c2058150504a2441363568` |
| `gameplay_result_1080x2400.png` | 1080×2400 | `9fba4006a4b6dc49eac2b6bd6c3051051c39128644159659217f35174213da1d` |

## Visible baseline observations

- The start frame shows English HUD labels, a Korean instruction, and a single timing dial;
  no tower or character is visible in the captured gameplay state.
- Most of the portrait frame is empty dark background, with gameplay concentrated in the
  lower half.
- The result frame shows a large `CLEAR!` / `+154` card over the dial and a Korean mascot
  speech bubble at the lower right; the HUD and instruction are not visible in that frame.
- These are still-image observations only. They do not verify touch feel, animation quality,
  device behavior, performance, or fun, and they are not Android/iPhone captures.
