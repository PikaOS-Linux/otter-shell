# App overrides and editing

App overrides and editing let a user set a per-app override and type into an active settings field without the control bounds jumping.

## Sub-features

- `app-override` shows a per-app override surface.
- `app-editing` shows the same surface with field index 3 actively editing the text `Search here`.

## How to get to it (user POV)

- Open otter-settings and choose an application config tab.
- Override a field for that app.
- Click into a text field and type.

## Driving it with verify-otter-settings

Preconditions:

- `scripts/doctor.sh` exits `0`.
- Baselines include `app-overrides@1x.png` and `app-editing@1x.png`.

- **CPU gate.** Run `scripts/run-visual-test.sh <run-id>`. Exit code `0`.
- **Override chrome.** Confirm `app-overrides@1x.png` matched.
- **Active edit.** Confirm `app-editing@1x.png` matched and shows the editing state (fixture sets `editing_field = 3`, `edit_text = "Search here"`).
- **Proof.** Keep both PNGs and `result.txt` under the run-id.

## Gotchas

- Editing proof is fixture-driven; there is no PTY typing into the live window for this feature yet.
- A pass that only checks `app-overrides` without `app-editing` is incomplete for this feature file.
- Live smoke does not enter edit mode automatically.
