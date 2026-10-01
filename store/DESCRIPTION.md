# KDE Store listing

**Title:** AMD GPU Monitor

**Category:** Linux/Unix Desktops → Desktop Extensions → KDE Plasma Extensions →
Plasma 6 Extensions → Plasma 6 Applets

**License:** GPL-2.0-or-later

**Summary (one line):**
GPU utilisation and VRAM usage for AMD cards in the panel and on the desktop.

**Description:**

AMD GPU Monitor shows how busy your Radeon GPU is and how much video memory is in use,
right in the Plasma panel, with a detailed popup and a desktop widget.

Panel view
- GPU usage, VRAM and temperature as thin bars with labels and values
- Four styles: labels + bars + values, bars only, labels + values, labels + bars
- Fits thin panels; rows scale with the panel height, configurable top/bottom margin
- Works in horizontal and vertical panels

Full view (click the panel widget, or place it on the desktop)
- Bars with exact numbers, temperature and power
- History graph of usage and VRAM over the last 10 to 600 seconds

Settings
- Pick the GPU from the list the system reports, or "All GPUs combined"
- Update interval, which rows to show, VRAM as GiB or percent
- Custom colours per series, theme colours by default
- Optional power reading from sysfs for cards where Plasma reports no power

How it works
The widget reads the GPU sensors of the Plasma system statistics daemon (ksystemstats), the
same source as the built-in System Monitor widgets. No root access, no background shell
scripts, no compilation. It requires Plasma 6 and an AMD GPU using the amdgpu driver; other
vendors work where ksystemstats provides the same sensors.

Source code, issues and changelog: https://github.com/secanis/kde-widget-amd-gpu

**Tags:** gpu, amd, radeon, vram, monitor, plasma6, panel, widget

**Product logo:** `icon-256.png` (rendered from `icon.svg`)

**Screenshots:** see `screenshots/` and `README.md` in this folder for how they are produced.
