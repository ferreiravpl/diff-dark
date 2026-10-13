# Diff Dark — IntelliJ

**English** · [Português](README.pt-BR.md)

A theme plugin (UI and editor) for JetBrains IDEs **2025.3 or newer** on Linux. Independent of
the GNOME part. Needs only `python3`.

## Install

```bash
./install.sh                              # with the IDE open: detects its install and profile
./install.sh /opt/idea-IU-253.29346.138   # or point to the install directory (IDE may be closed)
```

Restart the IDE and pick **Settings › Appearance › Theme → Diff Dark**. The editor color
scheme comes with it.

## Uninstall

```bash
./uninstall.sh                            # same arguments as install.sh
```

Restart the IDE and it goes back to its default theme.

## How it is made

`build.py` reads the IDE's own **Islands Dark** theme and color scheme and builds a plugin `.jar`:

- **UI:** Islands Dark with its colors shifted: greys lose their blue cast and take a faint
  green hue, the blue accent becomes sage at about a quarter of its saturation, and every other
  color is toned down by 30%. The island layout stays the same.
- **Editor:** the same shift, plus hand-picked syntax colors from a single family of tones
  (grey-green → sage → blue-sage).

| Element | Tone | Italic |
|---|---|---|
| Method call | light mint | yes |
| Static call | strong blue-sage | yes |
| Method declaration | near-white green | — |
| Class / interface | near-white neutral / blue-sage | — |
| Parameter / local variable | very light green / grey | — |
| Field / constant | sage grey / dark blue-sage | — |
| Keyword / string | mid sage / leaf green | — |
| Annotation / comment | muted dark green / dark grey | — |

To tweak a color, edit the `ROLES` table in `build.py` (hue, lightness and saturation per role)
and run `install.sh` again. It is safe to run with the IDE open.
