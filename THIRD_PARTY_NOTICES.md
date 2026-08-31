# ShaguTweaks third-party notices

Audit date: 2026-08-31

This file records known upstream sources, compatibility references, and asset
provenance for the Dusk-92 ShaguTweaks fork.

Existing source comments, Git history, upstream license notices, and historical
credits remain part of the provenance trail.

## ShaguTweaks

This repository is a fork of:

- https://github.com/shagu/ShaguTweaks

Upstream license:

- MIT
- Copyright (c) 2021 Eric Mauser (Shagu)

The original MIT license remains at the repository root in `LICENSE` and an
additional documentary copy is preserved in
`LICENSES/ShaguTweaks-MIT.txt`.

The MIT grant applies to material for which the applicable copyright holder had
the right to grant those permissions. It does not by itself establish ownership
or relicensing authority over unrelated third-party or game-derived visual
assets.

## pfUI and zUI

The README historically credits pfUI and zUI as sources of ideas/reference.

During this documentation pass, no broad claim is made that the full projects
or unspecified portions of their source code are bundled here.

If a specific component is later identified as copied or substantially adapted
from pfUI, zUI, or another project, its exact source, affected files, and
applicable license should be recorded explicitly rather than inferred from a
general credit line.

## Turtle WoW / OctoWoW compatibility

This fork contains compatibility logic and tweaks intended for Turtle WoW-like
and OctoWoW-like environments.

Compatibility, testing, naming, or behavioral reference does not create an
affiliation, endorsement, partnership, or ownership relationship with those
projects or their maintainers.

## SuperWoW

`mods/superwow.lua` contains compatibility logic for the external SuperWoW
client modification:

- https://github.com/balakethelock/SuperWoW

SuperWoW itself is not bundled in this repository. The presence of compatibility
code does not imply redistribution, affiliation, or endorsement.

## Artwork and screenshots

Artwork under `img/` and screenshots under `screenshots/` are tracked in
`Docs/ASSET_PROVENANCE.md`.

At the time of the 2026-08-31 audit, both directories were byte-identical at
Git object level to the corresponding directories in the canonical
`shagu/ShaguTweaks` upstream repository.

Recording an exact upstream match establishes immediate provenance, but does
not itself prove the ownership or licensing status of every underlying visual
element.

## Project identity and trademarks

Canonical maintained fork:

- https://github.com/Dusk-92/ShaguTweaks

World of Warcraft, Warcraft, Blizzard Entertainment, and associated names,
marks, artwork, and game assets remain the property of their respective rights
holders.

See `PROJECT_IDENTITY.md`.

## Preservation rule

Do not remove historical attribution, source comments, license notices, or
provenance records merely because code is later modified.

When replacing or substantially rewriting inherited material, update the
provenance record rather than erasing the historical chain.
