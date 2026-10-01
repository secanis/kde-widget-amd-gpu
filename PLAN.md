# AMD GPU Monitor – Plasma 6 widget: project plan

## Goal

A KDE Plasma 6 widget (plasmoid) that shows **GPU utilisation** and **VRAM usage** of an AMD GPU:

- **in the panel** (top bar): a compact, always-visible view (thin bars and/or short text) with a
  tooltip and a click-to-open popup with details,
- **on the desktop**: a full view with bars, numbers, temperature/power and a short history graph.

## Findings from this machine (2026-09-29)

| Item | Value |
|---|---|
| Plasma / Qt | plasmashell 6.7.5, Qt 6.11.2 |
| GPU | AMD Radeon RX 7800 XT (Navi 32), `/sys/class/drm/card1` |
| sysfs | `gpu_busy_percent`, `mem_info_vram_used`, `mem_info_vram_total`, hwmon temp/power/fan |
| ksystemstats | running, GPU plugin loaded, exposes `gpu/gpu0/*` sensors (see below) |
| QML modules | `org.kde.ksysguard.sensors`, `org.kde.quickcharts`, `org.kde.plasma.plasma5support` all installed |
| Tools | `kpackagetool6`, `cmake`, `git`, `qmllint` present; `plasmoidviewer` **missing** (package `plasma-sdk`) |

Sensor IDs available from ksystemstats for this card:

```
gpu/gpu0/name            gpu/gpu0/usage        (percent)
gpu/gpu0/usedVram        gpu/gpu0/totalVram    (bytes)
gpu/gpu0/temperature     gpu/gpu0/power
gpu/gpu0/coreFrequency   gpu/gpu0/memoryFrequency
gpu/all/usage            gpu/all/usedVram      gpu/all/totalVram
```

Note: the ksystemstats index (`gpu0`) does **not** match the DRM card number (`card1`). The widget
therefore takes the ksystemstats index as a config option.

## Architecture decision: data source

Three options were considered:

1. **ksystemstats sensors via `org.kde.ksysguard.sensors` (chosen).** Same daemon the stock
   System Monitor widgets use. Pure QML, no shell processes, no C++ build, rate limiting built in,
   values already formatted (`formattedValue`), works for any GPU vendor ksystemstats supports.
2. `plasma5support` "executable" DataSource polling `cat /sys/class/drm/...`. Works but spawns a
   process every tick and is the legacy Plasma 5 way. Keep as a fallback idea only.
3. C++ QML plugin reading sysfs directly. Most efficient, but needs a CMake build, packaging and
   per-distro installation. Not worth it for v1.

Consequence: the widget is a **pure QML package** installed with `kpackagetool6`. No compiler needed.

## Project layout

```
PLAN.md                         this file
README.md                       usage, install, development
Makefile                        install / upgrade / uninstall / lint / view / restart-shell
package/                        the plasmoid (what gets installed)
  metadata.json                 plugin id, name, version
  contents/config/main.xml      configuration schema (kcfg)
  contents/config/config.qml    config dialog categories
  contents/ui/main.qml          PlasmoidItem root: representations, tooltip
  contents/ui/GpuSensors.qml    wraps the ksystemstats sensors for one GPU
  contents/ui/UsageBar.qml      reusable horizontal bar
  contents/ui/CompactRepresentation.qml   panel view
  contents/ui/FullRepresentation.qml      desktop view / popup
  contents/ui/config/ConfigGeneral.qml    settings page
```

## Milestones

- [x] **M0 – Research & scaffold** (this step): environment check, data source decision,
      installable skeleton with working compact + full views, settings page.
- [x] **M1 – First install & polish** (2026-09-30): installed and running in the top panel; panel
      rows fill the panel height with a configurable margin; four panel styles. Popup verified with
      `make popup-test` plus screenshots: open, close by focus loss, reopen, close by re-activating,
      reopen all work. The 2026-09-29 "cannot reopen" report predates the removal of the explicit
      compact `preferredRepresentation` and the `Plasmoid.status` binding and did not reproduce.
      Vertical panel checked on 2026-09-30 via `make widget-preview` (bar stacked above value).
- [x] **M2 – History graph** (2026-09-30): line chart of usage % and VRAM % in the full view
      (`HistoryProxySource`, newest sample at the right edge, 25/50/75 % guides, legend with live
      values, "last N s" caption), `showHistory` toggle and history length in settings, buffer
      cleared when interval or length changes. Verified with `make preview`.
- [x] **M3 – Configuration** (2026-09-30): GPU picker listing the GPUs ksystemstats reports
      (`GpuProbe.qml` probes `gpu/gpu0..7/name`; an undetected configured index stays selectable),
      custom colours for usage/VRAM/temperature with theme colours as default, power line honours
      its checkbox. Rows, styles, margin and interval were already configurable. Verified with
      `make config-preview`. Lint now runs the Qt 6 qmllint (`/usr/bin/qmllint` is Qt 5 here).
- [x] **M4 – Robustness** (2026-09-30): explicit availability flags per sensor in `GpuSensors.qml`;
      panel shows "GPU n/a" and the full view an explanation when ksystemstats reports nothing for
      the chosen index; "All GPUs combined" (`gpu/all`, index -1) offered when more than one GPU is
      detected; opt-in sysfs power fallback (hwmon `power1_average`, first amdgpu or a configured
      file) for cards where ksystemstats has no power value; compact view takes all configuration
      as properties. Hot-add relies on the Sensor type re-attaching when the daemon adds the sensor
      (not testable here, no eGPU). Verified with `make widget-preview` including the no-GPU states.
- [x] **M5 – Packaging** (2026-09-30): `CHANGELOG.md`, `.plasmoid` archive built by `make archive`
      and by CI, plain-CMake install target (no ECM needed, validated locally and in CI), release
      job exercised with a test tag on the private development repository.
- [x] **Publication** (2026-10-01): published as **0.1.0** from a single clean commit to
      `github.com/secanis/kde-widget-amd-gpu` (public); the development history stays in the
      private repository. KDE Store remains a separate decision.

## Testing approach

- `make lint` runs `qmllint` over all QML files (catches syntax and most binding errors).
- `make install` / `make upgrade` then add the widget via "Add Widgets…". `make restart-shell`
  reloads plasmashell after QML changes (upgrade alone does not reload a running widget).
- `make preview` renders the installed widget's full view to `build/preview.png` (plasmawindowed as
  an XWayland client, grabbed with ImageMagick, no focus change). It catches runtime errors that
  qmllint misses, e.g. a type imported from the wrong module.
- `make popup-test` toggles the panel instance's popup a few times through a temporary global
  shortcut (kglobalaccel), which is the only way to drive it under Wayland without a mouse. Combine
  with `spectacle -b -n -f -o shot.png` to capture the result.
- `make config-preview` renders the settings page from the source tree in a plain `qml6` window
  (`tools/ConfigHarness.qml` provides i18n stand-ins and sample values) to `build/config-preview.png`.
- `make widget-preview` renders the panel view at 24/32/40 px in all styles, a vertical panel, the
  full view and both no-GPU states from the source tree (`tools/WidgetHarness.qml`) to
  `build/widget-preview.png`, with live ksystemstats data.
- `make window` runs the installed widget in a standalone window via `plasmawindowed` (already
  installed). Optional: `sudo pacman -S plasma-sdk` gives `plasmoidviewer`; then `make view` renders the
  widget in a standalone window with a form-factor switcher.
- Load generation for manual testing: `glmark2`, `vkmark`, or a game; watch VRAM with a browser.
- Debug output: `journalctl --user -f -t plasmashell` (QML warnings land there).

## Risks / open points

- **Index mapping**: `gpu0` in ksystemstats vs `card1` in DRM. Users with iGPU + dGPU may need to
  pick index 1. M3 addresses this with a name-based picker.
- **Sensor availability**: `usage` comes from `gpu_busy_percent`, which some older AMD cards or
  driver versions do not expose. Show "n/a" rather than 0.
- **Power not available via ksystemstats** (RX 7800 XT, Plasma 6.7.5): `gpu/gpu0/power` and
  `gpu/gpu0/power1` both deliver no data even though hwmon has `power1_average` (71 W). The card
  exposes no `power1_input`, which the GPU plugin appears to read. The widget hides the power line
  when the value is undefined. M4 added an opt-in fallback that polls hwmon via a
  `plasma5support` executable data source (one `sh` per interval, at most once per second).
- **Panel height**: at 24–30 px panels two stacked bars plus text may not fit; compact view must
  degrade to bars only / text only (config option + automatic).
- **Plasma API changes**: keep to documented `PlasmoidItem`, `Sensors.Sensor` and quickcharts APIs
  used by the stock System Monitor faces to stay compatible with future 6.x releases.
