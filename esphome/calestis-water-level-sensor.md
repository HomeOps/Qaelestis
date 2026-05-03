# Calestis Water Level Sensor

Ultrasonic water-level sensor for the Calestis property in Costa Rica, where
water is a precious resource. Built around a **MaxBotix MB7851-B36
(HRXL-MaxSonar-WRMT)** ranging head and an **M5 Atom Lite (ESP32-PICO-D4)**
controller running ESPHome and reporting to Home Assistant.

The sensor mounts at the top of a water tank, transducer pointing straight
down at the water surface, and reports the distance from the sensor face to
the water. Tank height minus that distance gives the water level.

---

## 1. Hardware

| Item                          | Notes                                                                            |
| ----------------------------- | -------------------------------------------------------------------------------- |
| MaxBotix MB7851-B36           | HRXL-MaxSonar-WRMT, IP67, 36 in (≈914 mm) factory cable into a 7-screw terminal  |
| M5 Atom Lite                  | ESP32-PICO-D4 module with **two female headers on the bottom**: a 5-pin row (3V3, G22, G19, G23, G33) and a 4-pin row (G21, G25, 5V, GND) |
| 3 × Male-to-male Dupont jumper, ~15–20 cm | One male end plugs into the M5 bottom female header; the other end has its male pin snipped off and is stripped 6 mm to land in the MB7851 screw terminal |
| Power                         | 3.3 VDC supplied directly from the M5 Atom Lite `3V3` pin                        |

**No solder, no WAGOs, no breadboard, no extra components.** Total active
build = three jumper wires.

The M5 Atom Lite's bottom female headers are the intended permanent
connection method for these pins, and the MB7851 cable already terminates
in screw terminals at its end — together those give a secure two-ended
mechanical connection without any soldering.

### Sensor specifications (MB7851)

- Acoustic range: **300 mm – 5000 mm** (sub-300 mm reads as 300 mm)
- Resolution: **1 mm**
- Operating voltage: **3.0 – 5.5 VDC** (we use 3.3 V — see §5 for why)
- Analog output scaling: **(Vcc / 5120) volts per mm**
- Outputs available: Analog (AN), Pulse-Width (PW), Serial (TX), Trigger (RX)

For this build we only use the **Analog (AN)** output. The other outputs
remain in their screw terminals, unconnected.

---

## 2. MB7851-B36 pinout — labelling all 7 pins

The factory cable terminates in a 7-position screw-terminal block. The
block follows MaxBotix HRXL-MaxSonar-WRMT pin numbering, but the "1" and
"7" markings on the unit are easy to miss. This section is the
authoritative reference.

### How to identify Pin 1 vs Pin 7

The pin numbering follows the MaxBotix HRXL-MaxSonar-WRMT datasheet. To
orient the sensor head:

1. Hold the sensor with the **transducer (the round white acoustic element)
   pointing away from you** and the cable exiting the back toward you.
2. The PCB component side is **up**.
3. With the head in this orientation, **Pin 1 is on the LEFT side of the
   PCB connector and Pin 7 is on the RIGHT** — the cable inside follows
   the same order out to the screw terminal.

If still in doubt, verify with a multimeter on the screw terminal *before*
landing anything on the M5:

- The screw terminal that reads ~3.3 V (or whatever Vcc you intend)
  relative to ground when the unit is powered = **Pin 6 (V+)**.
- The screw terminal at ground potential (continuity to the supply 0 V) =
  **Pin 7 (GND)**.

Pin 7 (GND) is always the last terminal at one end of the block; Pin 1 is
the terminal at the opposite end. Once Pin 7 is identified, Pin 1 is the
terminal furthest from it on the same row.

### Pin table

| Pin | Label | Name (datasheet)         | Direction | Function in this build                                                                              |
| --- | ----- | ------------------------ | --------- | --------------------------------------------------------------------------------------------------- |
| 1   | TEMP  | Temperature sensor input | Input     | Optional external temperature compensation input. **Leave unconnected**.                            |
| 2   | PW    | Pulse-Width Output       | Output    | Distance encoded as a pulse width (1 µs = 1 mm). **Not used; leave unconnected**.                   |
| 3   | AN    | Analog Voltage Output    | Output    | **USED.** Distance encoded as an analog voltage scaled at (Vcc / 5120) V/mm.                        |
| 4   | RX    | Ranging Start / Hold     | Input     | If high or open, the sensor ranges continuously (default). **Leave unconnected** for free-running.  |
| 5   | TX    | Serial Output            | Output    | RS232-format ASCII range data. **Not used; leave unconnected**.                                     |
| 6   | V+    | Supply voltage           | Power     | **USED.** 3.3 VDC from the M5 Atom Lite `3V3` pin.                                                  |
| 7   | GND   | Ground                   | Power     | **USED.** Common ground with the M5 Atom Lite `GND` pin.                                            |

**Wires used in this build: Pin 3 (AN), Pin 6 (V+), Pin 7 (GND).**
The other four screw terminals (1, 2, 4, 5) stay empty — they are
mechanically captive in their own terminals, so there is no shorting risk
and no insulation step needed.

---

## 3. Cable colors for the 3-wire run

Use the following standard DC-power-and-signal convention for the three
jumper wires from the MB7851 screw terminal to the M5 Atom Lite:

| Function       | MB7851 pin / screw  | M5 Atom Lite header position           | Wire color    |
| -------------- | ------------------- | -------------------------------------- | ------------- |
| +3.3 VDC       | Pin 6 (V+)          | 5-pin row, position 1 — `3V3`         | **Red**       |
| Ground         | Pin 7 (GND)         | 4-pin row, position 4 — `GND`         | **Black**     |
| Analog signal  | Pin 3 (AN)          | 5-pin row, position 5 — `G33`         | **Yellow**    |

Why these colors:

- **Red = +V** and **Black = GND** is the universal DC convention; using it
  consistently means anyone (including future-you) opening the enclosure
  can reason about polarity without thinking.
- **Yellow** is the conventional color for an analog signal line and is
  visually distinct from both red and black, which makes accidental
  shorting of signal-to-rail unlikely. White is an acceptable substitute
  if yellow is unavailable; do not use red or black for the signal.

If your jumper kit only has one color of jumper, mark each wire at *both*
ends with a small piece of colored tape or a marker stripe matching the
table above before landing it.

---

## 4. M5 Atom Lite wiring

### Bottom-header pin map (your unit)

```
  5-pin row (rear/left of bottom):       4-pin row (rear/right of bottom):
  ┌──────────────────────────────┐       ┌──────────────────────┐
  │  3V3   G22   G19   G23   G33 │       │  G21   G25   5V   GND │
  │  pos1  pos2  pos3  pos4  pos5│       │  pos1  pos2  pos3 pos4│
  └──────────────────────────────┘       └──────────────────────┘
```

The pins we care about for this build:

| M5 Atom Lite header position    | ESP32 GPIO | Used for             |
| ------------------------------- | ---------- | -------------------- |
| 5-pin row, position 1 (`3V3`)   | —          | +3.3 V to MB7851 V+  |
| 4-pin row, position 4 (`GND`)   | —          | Common ground        |
| 5-pin row, position 5 (`G33`)   | GPIO 33    | ADC1_CH5 — reads AN  |

`G33` is on **ADC1**, which is the only ADC unit usable while Wi-Fi is
active. Do not use any GPIO on ADC2 (e.g. GPIO 25, 26) for the analog
input — readings are unreliable when Wi-Fi is connected.

### Procedure (no soldering)

1. Take three male-to-male Dupont jumper wires, ideally Red, Black, and
   Yellow (see §3).
2. On each jumper, snip off the male pin at **one** end with side cutters
   and strip ~6 mm of insulation from the cut end. Leave the other male
   pin intact.
3. Land the stripped ends into the MB7851 screw terminal:
   - Red → screw terminal **Pin 6 (V+)**
   - Black → screw terminal **Pin 7 (GND)**
   - Yellow → screw terminal **Pin 3 (AN)**
   Tighten each screw firmly but don't crush the strands.
4. Plug the intact male ends into the M5 Atom Lite bottom female headers:
   - Red male → 5-pin row, position 1 (`3V3`)
   - Black male → 4-pin row, position 4 (`GND`)
   - Yellow male → 5-pin row, position 5 (`G33`)
5. Power the M5 Atom Lite via its USB-C port.

### Wiring diagram

Three wires, one per row. Each row is one jumper.

```
  MB7851 screw terminal           wire          M5 Atom Lite female header
  ─────────────────────           ────          ──────────────────────────
  Pin 6   V+    ────────────── Red    ────────► 5-pin row, position 1   (3V3)
  Pin 7   GND   ────────────── Black  ────────► 4-pin row, position 4   (GND)
  Pin 3   AN    ────────────── Yellow ────────► 5-pin row, position 5   (G33)

  Pin 1   TEMP  ──── (empty, no wire)
  Pin 2   PW    ──── (empty, no wire)
  Pin 4   RX    ──── (empty, no wire)
  Pin 5   TX    ──── (empty, no wire)
```

For reference, the M5 Atom Lite bottom female-header layout you described:

```
   5-pin row                              4-pin row
   ┌────────────────────────────┐         ┌────────────────────────┐
   │  3V3   G22   G19   G23  G33│         │  G21   G25   5V    GND │
   │  pos1  pos2  pos3  pos4 pos5│         │  pos1  pos2  pos3  pos4│
   └────────────────────────────┘         └────────────────────────┘
       ▲                       ▲                                ▲
       │ Red wire goes here    │ Yellow wire goes here          │ Black wire goes here
       │ (V+ from sensor)      │ (AN signal from sensor)        │ (GND from sensor)
```

---

## 5. Why 3.3 V supply (and not 5 V)

The MB7851 supports 3.0 – 5.5 V, and the M5 Atom Lite exposes a 5 V pin.
Powering at 5 V is tempting — finer mV per mm — but the MB7851's analog
output scales with Vcc, so:

| Vcc       | V_AN at 5000 mm | Fits ESP32 ADC?                                         |
| --------- | --------------- | ------------------------------------------------------- |
| 3.3 V     | ~3.22 V         | Yes — directly into G33 with 12 dB attenuation          |
| 5.0 V     | ~4.88 V         | **No** — ESP32 GPIOs are not 5 V-tolerant; pin damage   |

To use 5 V supply you would need a voltage divider on the AN line (two
resistors) to bring the signal back into ESP32-safe range. That's extra
parts and a tuning step for no useful gain — the ESP32's 12-bit ADC
already over-resolves the sensor's 1 mm step at 3.3 V. Stay at 3.3 V.

---

## 6. Analog → distance math

The MB7851 outputs a voltage on AN proportional to range:

```
V_AN = (Vcc / 5120) × distance_mm
```

With `Vcc = 3.3 V`:

```
V_AN per mm  =  3.3 / 5120  =  0.6445 mV/mm
distance_mm  =  V_AN × (5120 / 3.3)  =  V_AN × 1551.515
```

Sanity-check the endpoints of the rated range:

| Distance | V_AN (at 3.3 V Vcc) |
| -------- | ------------------- |
| 300 mm   | 0.193 V             |
| 1000 mm  | 0.645 V             |
| 2500 mm  | 1.611 V             |
| 5000 mm  | 3.223 V             |

All values fit inside the ESP32 ADC's 12 dB attenuation range (≈0–3.1 V
linear, with mild non-linearity above 3.0 V). For best accuracy near a
full tank, calibrate the sensor against a known distance after install
and adjust the multiplier in the YAML if needed.

### Water level from distance

Sensor mounted at the top of a tank pointing down. Define:

- `D_empty` = distance from sensor face to **tank bottom** (tank empty)
- `D_full`  = distance from sensor face to **maximum water surface** (tank full)

Then:

```
water_height_mm = D_empty − distance_mm
percent_full    = (D_empty − distance_mm) / (D_empty − D_full) × 100
```

The YAML exposes `D_empty` and `D_full` as substitutions so they can be
tuned per tank without editing the template logic.

---

## 7. Mounting notes

- Mount the sensor at the **top center** of the tank, transducer pointing
  straight down.
- Keep the transducer face at least **300 mm** above the maximum water
  level — anything closer reads as 300 mm and is indistinguishable from a
  full tank.
- Avoid a position directly above the inlet stream; falling water creates
  acoustic noise. Aim for the calmest part of the surface.
- The MB7851 head is IP67 but the **screw terminal block is not**. Mount
  it (and the M5 Atom Lite) inside a dry enclosure outside the tank.
- Run only the sensor head's factory cable into the tank space; keep the
  3-wire jumper run dry.

---

## 8. Files

- `calestis-water-level-sensor.yaml` — ESPHome config for this device.
- `calestis-water-level-sensor.md` — this document.
