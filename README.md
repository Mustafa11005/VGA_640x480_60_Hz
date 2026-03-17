# VGA 640×480 @ 60 Hz Controller

A fully parameterizable VGA display controller implemented in Verilog, targeting FPGA platforms.  
Supports solid-color output and image-memory playback at **640×480 resolution, 60 Hz refresh rate** using a 25 MHz pixel clock.

---

## Features

- Parameterizable input clock frequency (25 MHz direct or divided from ≥50 MHz sources)
- Accurate HSYNC / VSYNC pulse generation per VESA 640×480 @ 60 Hz standard
- `video_on` active-area signal for downstream pixel logic
- Dual output modes selectable at elaboration time:
  - **Solid color** — configurable via `BPP`-wide color parameter
  - **Image memory** — 307,200-pixel framebuffer loaded from a `.mem` hex file
- One-cycle registered memory read with aligned blanking gate
- Self-checking SystemVerilog testbench with automatic PASS/FAIL verdict

---

## Repository Structure

```
VGA_640x480_60_Hz/
│
├── TOP/
│   ├── vga_640x480.v          # Top-level VGA controller
│   ├── freq25MHz_clk_divider.v # Clock divider (÷2N, input must be ≥50 MHz, multiple of 50)
│   ├── pixel_gen.v            # Synchronous framebuffer ROM (BRAM-inferred)
│   ├── img_hex.mem            # Pixel data file loaded by $readmemh
│   ├── src_files.list         # File list for vlog compilation
│   ├── run.do                 # ModelSim/Questa simulation script
│   └── vga_640x480_tb.sv      # Self-checking testbench
│
└── Frequency_Generator/       # Standalone clock divider development & testbench
```

---

## Module Hierarchy

```
vga_640x480  (top)
├── clk_gen              (freq25MHz_clk_divider.v)  — optional, only when INPUT_CLK_FREQ_MHZ ≥ 50
└── pixel_rgb_gen        (pixel_gen.v)               — optional, only when USE_IMAGE_MEM = 1
```

---

## Parameters

### `vga_640x480`

| Parameter | Default | Description |
|---|---|---|
| `INPUT_CLK_FREQ_MHZ` | `25` | Input clock frequency in MHz |
| `USE_IMAGE_MEM` | `0` | `0` = solid color, `1` = framebuffer from `img_hex.mem` |
| `BPP` | `8` | Bits per pixel (must match `.mem` file word width) |
| `H_ACTIVE` | `640` | Horizontal active pixels |
| `H_FRONT_PORCH` | `16` | Horizontal front porch |
| `H_SYNC_PORCH` | `96` | Horizontal sync pulse width |
| `H_BACK_PORCH` | `48` | Horizontal back porch |
| `V_ACTIVE` | `480` | Vertical active lines |
| `V_FRONT_PORCH` | `10` | Vertical front porch |
| `V_SYNC_PORCH` | `2` | Vertical sync pulse width |
| `V_BACK_PORCH` | `33` | Vertical back porch |

### `clk_gen`

| Parameter | Default | Description |
|---|---|---|
| `INPUT_CLK_FREQ_MHZ` | `25` | Input clock in MHz — must be ≥ 50 and a multiple of 50 to divide to 25 MHz |

---

## VGA Timing (640×480 @ 60 Hz)

| Parameter | Value |
|---|---|
| Pixel clock | 25.175 MHz (25 MHz used) |
| Horizontal total | 800 clocks |
| Vertical total | 525 lines |
| HSYNC polarity | Negative (active low) |
| VSYNC polarity | Negative (active low) |

---

## Image Memory Format

- File: `TOP/img_hex.mem`
- Format: one hex word per line, width = `BPP` bits (default 8-bit: `RRR_GGG_BB`)
- Depth: exactly **307,200 entries** (640 × 480)
- Address mapping: `addr = pixel_y × 640 + pixel_x`

To generate random test data using PowerShell:

```powershell
$rng = [System.Random]::new()
1..307200 | ForEach-Object { '{0:X2}' -f $rng.Next(0,256) } | Set-Content -Encoding ascii .\TOP\img_hex.mem
```

---

## Simulation

Requires **ModelSim** or **Questa**.

```tcl
cd TOP
vsim -do run.do
```

The testbench runs **2 full VGA frames**, then prints:

```
[PASS] VGA testing completed with no mismatches.
```

or on failure:

```
[ERROR][%0t] ...
...
[FAIL] VGA testing found # mismatches.
```

### Self-checks performed each clock cycle

- `h_sync` matches expected HSYNC window
- `v_sync` matches expected VSYNC window
- `video_on` matches active-area window
- `rgb` is zero during blanking (accounts for 1-cycle memory latency in image mode)

---

## Outputs

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | System clock |
| `rstn` | input | 1 | Active-low asynchronous reset |
| `h_sync` | output | 1 | Horizontal sync (active low) |
| `v_sync` | output | 1 | Vertical sync (active low) |
| `video_on` | output | 1 | High during active pixel area |
| `rgb` | output | `BPP` | Pixel color data |

---

## License

MIT License — free to use and modify for any purpose.
