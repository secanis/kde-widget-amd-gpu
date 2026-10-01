# AMD GPU Monitor (Plasma 6 widget)

A small KDE Plasma 6 plasmoid showing AMD GPU utilisation and VRAM usage. Works in the panel
(compact bars/text with tooltip and popup) and on the desktop (full view with history graph).

Data comes from the Plasma system statistics daemon (`ksystemstats`), the same source the stock
System Monitor widgets use, so no root access, no shell polling and no compilation is required.

## Features

- Panel view with GPU usage, VRAM and temperature rows; four styles (labels + bars + values,
  bars only, labels + values, labels + bars) and a configurable vertical margin.
- Tooltip with usage, VRAM, temperature and power; click opens the full view.
- Full view (desktop or popup) with bars, numbers and a history graph of usage and VRAM percent
  (configurable length, can be switched off).
- Settings: GPU picker (lists the GPUs ksystemstats reports, plus "All GPUs combined" on multi-GPU
  systems), update interval, which rows to show, VRAM as GiB or percent, custom colours per series,
  history graph on/off and length.
- Optional power reading from sysfs (hwmon `power1_average`) for cards where ksystemstats reports
  no power, e.g. the RX 7800 XT. Off by default; enable it under *Show → Power*.
- Clear "GPU n/a" state in the panel and an explanation in the full view when no sensors are found.

## Requirements

- KDE Plasma 6.x (developed against 6.7.5 / Qt 6.11)
- `ksystemstats` with its GPU plugin (part of Plasma; present on any standard Plasma install)
- An AMD GPU using the `amdgpu` kernel driver

## Install from the KDE Store

Right-click the panel or desktop → *Add Widgets…* → *Get New Widgets…* and search for
"AMD GPU Monitor", or browse the listing at
https://www.opendesktop.org/u/matthiasbaldi/products. Release archives are also attached to
the [GitHub releases](https://github.com/secanis/kde-widget-amd-gpu/releases).

## Install (user-local, from source)

```sh
make install      # first time
make upgrade      # after changes
make restart-shell
```

Then right-click the panel or desktop → *Add Widgets…* → search for "AMD GPU Monitor".

## Install system-wide (all users)

```sh
cmake -B build-cmake -DCMAKE_INSTALL_PREFIX=/usr
sudo cmake --install build-cmake
```

Needs only CMake; nothing is compiled.

## Uninstall

```sh
make uninstall
```

## Development

```sh
make lint         # qmllint over package/
make window       # run installed widget in a window (plasmawindowed)
make preview      # render the installed widget to build/preview.png (needs xdotool, imagemagick)
make popup-test   # open/close the panel popup a few times (ARGS="count delay")
make config-preview  # render the settings page to build/config-preview.png
make widget-preview  # render panel/full/no-GPU views to build/widget-preview.png
make view         # needs plasma-sdk (plasmoidviewer)
journalctl --user -f -t plasmashell   # QML warnings
```

### Continuous integration

`.github/workflows/build.yml` runs on every push and pull request in an Arch Linux container
(current Plasma 6 QML modules): `make check` (metadata and config schema), `make lint`
(qmllint), `make verify-install` (kpackagetool6 into a temporary prefix) and `make archive`.
The resulting `.plasmoid` is uploaded as a workflow artifact. Pushing a tag `vX.Y.Z` that matches
the version in `package/metadata.json` additionally creates a GitHub release with the archive
attached. Install a downloaded archive with:

```sh
kpackagetool6 -t Plasma/Applet -i ch.secanis.amdgpumonitor-X.Y.Z.plasmoid
```

### Releasing

1. Update `CHANGELOG.md` and bump `KPlugin.Version` in `package/metadata.json`.
2. Commit to `main`, then tag `vX.Y.Z` (must match the version) and push the tag. CI builds the
   archive and creates the GitHub release with it attached.

Configuration options live in `package/contents/config/main.xml`; the settings UI is
`package/contents/ui/config/ConfigGeneral.qml`. See `PLAN.md` for the roadmap.

## License

GPL-2.0-or-later (see `LICENSE`).
