# SkillSpoke Brand Assets

Official brand imagery for SkillSpoke. This is the only public repository in the `satteritsik` organization.

## Permanent URLs

Reference any asset directly:

```
https://raw.githubusercontent.com/satteritsik/SkillSpoke-assets/main/v1/svg/combomark-ondark.svg
```

## Structure

```
v1/
├── svg/          Vector originals (preferred for web and UI)
├── png/          Rasterized at multiple scales
│   ├── 1x/
│   ├── 1.5x/
│   ├── 2x/
│   ├── 3x/
│   └── 4x/
├── jpg/          Opaque background rasters
├── ai/           Adobe Illustrator source files
├── eps/          Encapsulated PostScript (print vendors)
├── pdf/          Vector PDF exports
├── tiff/         High-resolution print rasters
├── social/       Platform-specific assets (LinkedIn banners, etc.)
├── google/       Google Workspace assets (email signature, etc.)
└── animated/     Motion assets (GIFs, Lottie, etc.)
```

## Filename Convention

Pattern: `{type}-{variant}-{theme}.{ext}`

| Segment   | Values                                                             |
|-----------|--------------------------------------------------------------------|
| type      | `combomark`, `lettermark`, `mark`, `squarelogo`, `tagline`         |
| variant   | Optional: `tagline1`, `tagline2`, `tagline-gold1`, `alt`           |
| theme     | `ondark`, `onlight`                                                |

Transparent background is the default. Solid background variants use a `solid-` prefix when they exist:

```
combomark-ondark.svg              # transparent background
combomark-solid-ondark.svg        # solid background
```

PNG filenames do not carry scale suffixes — the directory is the sole indicator of scale:

```
v1/png/2x/combomark-ondark.png    # the directory says 2x
```

## PNG Scale Reference

| Directory | iOS   | Android  |
|-----------|-------|----------|
| 1x/       | @1x   | mdpi     |
| 1.5x/     | @1.5x | hdpi     |
| 2x/       | @2x   | xhdpi    |
| 3x/       | @3x   | xxhdpi   |
| 4x/       | @4x   | xxxhdpi  |

## Versioning

Assets are organized by major version directory (`v1/`, `v2/`, etc.).

- Minor changes and additions: committed directly to the current version directory.
- Breaking visual refresh (rebrand, new design language): new version directory. Previous versions are never removed.

Git tags mark milestones:

```
v1.0.0  — Initial brand asset set
v1.1.0  — Added marketplace icons
v2.0.0  — Post-rebrand refresh
```

## Manifest

`assets.json` at the repo root lists every asset with metadata. Consumable by docs pipelines, tooling, or CI.

## Usage

These assets are provided for use in SkillSpoke products, documentation, and authorized partner materials.
