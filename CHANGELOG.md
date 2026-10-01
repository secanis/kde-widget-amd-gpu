# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow semver.

## [0.1.1] - 2026-10-01

### Fixed
- plasmashell crashed at startup with the widget in a panel (segfault in Kirigami's Plasma
  style while the shell reparents the applet item). Colour properties bound to `Kirigami.Theme`
  on the applet and panel-view root items triggered it; colours are now resolved in a function,
  as in the first working version. 0.1.0 is affected and should not be used.

### Added
- Own icon (graphics card with usage and VRAM bars) in the full view header and tooltip.
- `store/` with the KDE Store description, logo and screenshots.

## [0.1.0] - 2026-10-01

First release.

### Added
- Panel view with GPU usage, VRAM and temperature rows in four styles (labels + bars + values,
  bars only, labels + values, labels + bars), configurable vertical margin, vertical-panel layout.
- Tooltip with usage, VRAM, temperature and power; click opens the full view as a popup.
- Full view with bars, numbers and a history graph of usage and VRAM percent (configurable
  length, can be switched off).
- Settings: GPU picker listing the GPUs reported by ksystemstats, "All GPUs combined" on
  multi-GPU systems, update interval, rows to show, VRAM as GiB or percent, custom colours.
- Optional power reading from sysfs (hwmon `power1_average`) for cards where ksystemstats
  reports no power.
- Clear "GPU n/a" state when no sensors are found.
- Developer tooling: `make preview`, `make config-preview`, `make widget-preview`,
  `make popup-test`; GitHub Actions workflow that lints, packages and releases on tags;
  CMake install target for system-wide installation.
