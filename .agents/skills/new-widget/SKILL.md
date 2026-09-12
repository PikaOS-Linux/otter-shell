---
name: new-widget
description: Scaffold a new otter-ui widget with vtable interface, config, and tests
disable-model-invocation: true
---

# New Widget Scaffold

Create a new widget for otter-bar following established patterns.

## Arguments

The user should provide:
- **Widget name** (snake_case, e.g. `disk_usage`)
- **Description** of what the widget displays/does
- **Config fields** needed (with defaults)

## Steps

### 1. Create widget file

Create `otter-ui/src/widgets/<name>.zig` implementing the Widget VTable:

```zig
const Widget = @import("../widget.zig").Widget;

pub const <Name>Widget = struct {
    widget: Widget,

    // Required VTable fields
    const vtable = Widget.VTable{
        .draw = draw,
        .deinit = deinit,
        .setArea = setArea,
        .getWidth = getWidth,
        // Optional handlers (set to null if unused):
        .motion = null,
        .click = null,
        .scroll = null,
    };

    pub fn init(...) <Name>Widget { ... }
    fn draw(ptr: *const Widget, surface: *Surface) void { ... }
    fn deinit(ptr: *const Widget) void { ... }
    fn setArea(ptr: *Widget, area: Rect) void { ... }
    fn getWidth(ptr: *const Widget) u31 { ... }
};
```

Reference existing widgets for patterns:
- Simple display: `otter-ui/src/widgets/clock.zig`
- With click handler: `otter-ui/src/widgets/power_profiles.zig`
- With animation: `otter-ui/src/widgets/system_tray.zig`
- With SysInfo: `otter-ui/src/widgets/cpu_load.zig`

### 2. Add config fields

Update three locations in `otter-bar/src/config.zig`:

1. **FileConfig** — flat fields with `<widget>_` prefix:
   ```zig
   <name>_enabled: bool = true,
   <name>_<field>: <type> = <default>,
   ```

2. **Runtime config struct** — grouped fields:
   ```zig
   pub const <Name>Config = struct {
       enabled: bool = true,
       <field>: <type> = <default>,
   };
   ```

3. **Config mapping** — in the `fromFileConfig` function, map flat fields to runtime struct.

Defaults must match across all three locations.

### 3. Register in root container

In `otter-bar/src/components/root_container.zig`:
- Import the new widget module
- Add widget creation in the layout builder
- Handle the widget name string in the layout parser

### 4. Add to default layout

In `otter-bar/src/config.zig`, add the widget name to the appropriate `layout_left`, `layout_center`, or `layout_right` default string if it should appear by default.

### 5. Write tests

Add unit tests in the widget file covering:
- Initialization with default config
- Width calculation
- Any state transitions

### 6. Update documentation

Update `AGENTS.md`:
- Add widget to the Widgets table
- Add any new config fields to the Configuration Format section
- Add new source files to Important Source Files table

## Design Rules

- Follow data-driven design: prefer lookup tables over branches
- Use integer-only math in draw paths (no floats)
- Set `full_redraw` flag to avoid redundant rendering
- Use `BoundedArray` for fixed-capacity collections
- Keep allocations out of the draw path
