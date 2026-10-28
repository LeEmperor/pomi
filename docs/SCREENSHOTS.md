# Capturing pomi

Use real terminal captures so the README shows the app as it runs. Save the
finished images under `docs/images/` and add them to the README once available.

## Focus: the README hero

1. Set the terminal to about 70 columns by 24 rows, with a readable monospace
   font and true-color support. Hide unrelated panes or desktop content.
2. Run `dune exec pomi -- -no-bell -no-title` and press `Space`.
3. Let it run for a minute or two so the countdown and progress bar show activity.
4. Capture and crop to the terminal content; save as `docs/images/focus.png`.

After saving the image, replace the screenshot comment near the top of the
README with:

```markdown
![pomi running a focus session, with a large countdown and progress bar](docs/images/focus.png)
```

## Break: phase colors and cycle dots

Keep the same font, dimensions, and crop as the focus screenshot.

Run `dune exec pomi -- -completed 3 -no-bell -no-title`, then press `n` to
preview a long break. Press `Space` to start it and save the capture as
`docs/images/long-break.png`.

This preview uses a carried-over session count: skipping does not complete a
session. To capture a long break reached by completion instead, finish a work
session after starting with `-completed 3`.

## Compact: a smaller terminal

Run `dune exec pomi -- -no-bell -no-title` in a window around 60 columns by
15 rows. Check that both lines of keyboard hints are visible; increase the
height if needed. Save the capture as `docs/images/compact.png`.

## Optional short recording

Record start, pause, resume, and skip in roughly 10–15 seconds. Keep the text
readable at README width. One strong focus screenshot is enough for the initial
presentation.

## Before publishing

- Check each capture for readable text and clipped edges.
- Keep the terminal background and font consistent across captures.
- Check that no personal shell history, paths, or other windows are included.
- Preview the README after adding images, and use descriptive alt text.
