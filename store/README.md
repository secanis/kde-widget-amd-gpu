# KDE Store assets

- `DESCRIPTION.md`: listing text, category, tags.
- `icon.svg` / `icon-256.png`: product logo (same artwork as `package/contents/icons/`).
- `screenshots/`:
  - `01-panel-views.png`: panel view at 24/32/40 px in all styles, no-GPU state, vertical panel
    (left column of `make widget-preview`, cropped to 360x412).
  - `02-full-view.png`: full view after a minute of history (`PREVIEW_WAIT=66 make preview`).
  - `03-settings.png`: settings page (`make config-preview`).

All screenshots come from the preview targets in the Makefile, so they can be regenerated after
UI changes without arranging a desktop. Values show whatever the GPU is doing at the time.
