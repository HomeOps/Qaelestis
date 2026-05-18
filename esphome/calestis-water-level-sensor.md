# Calestis Water Level Sensor

Ultrasonic water-level sensor for the Calestis property in Costa Rica, where
water is a precious resource and reliable level monitoring is imperative.
Built around a **MaxBotix MB7851-B36 (HRXL-MaxSonar-WRMT)** ranging head and
an **M5 Atom Lite (ESP32-PICO-D4)** controller running ESPHome and reporting
to Home Assistant.

The sensor mounts at the top of a water tank, transducer pointing straight
down at the water surface, and reports the distance from the sensor face to
the water. Tank height minus that distance gives the water level.

> **This build uses the sensor's SERIAL (UART) output**, not the analog
> output. See §6 for the reasoning — in short: serial gives an exact 1 mm
> digital reading with no calibration and no ADC noise, which is what a
> critical water supply deserves. This document is the authoritative wiring
> and configuration reference; the deployed ESPHome config follows it.

---

## 1. Hardware

| Item                                      | Notes                                                                                                                                          |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| MaxBotix MB7851-B36                       | HRXL-MaxSonar-WRMT, IP67, 36 in (≈914 mm) factory cable into a 7-position screw-terminal block                                                  |
| └ screw-terminal block                    | **WANJIE WJEK254-2.54** — 2.54 mm-pitch PCB screw terminal, 150 V / 7 A, 26–18 AWG, M2 screws. **Soldered fixed to the PCB — it does not unplug** |
| M5 Atom Lite                              | ESP32-PICO-D4 module with **two female headers on the bottom**: a 5-pin row (3V3, G22, G19, G23, G33) and a 4-pin row (G21, G25, 5V, GND)        |
| 3 × Male-to-male Dupont jumper, ~15–20 cm | One male end plugs into the M5 bottom female header; the other end has its male pin snipped off and is stripped ~4 mm to land in the screw block |
| Power                                     | 3.3 VDC supplied directly from the M5 Atom Lite `3V3` pin                                                                                       |

**No solder, no WAGOs, no breadboard, no extra components.** Total active
build = three jumper wires.

### Sensor specifications (MB7851)

- Acoustic range: **50 mm – 5000 mm** (objects closer than 50 mm read as 50 mm; "no target detected" reports ~6500 mm)
- Resolution: **1 mm**
- Operating voltage: **3.0 – 5.5 VDC** (we use 3.3 V — see §5 for why)
- Outputs available: Serial (TX), Analog (AN), Pulse-Width (PW), Trigger (RX)
- Serial format (WRMT): ASCII `Rnnnn Tnnn\r` — distance **and** temperature, **9600 baud, 8-N-1** (see §6)

For this build we use only the **Serial (TX)** output. The other outputs
remain in their screw terminals, unconnected.

---

## 2. MB7851-B36 pinout — labelling all 7 pins

The factory cable terminates in a 7-position WANJIE WJEK254-2.54 screw
terminal. The block follows MaxBotix HRXL-MaxSonar-WRMT pin numbering, but
the "1" and "7" markings are easy to miss. This section is the authoritative
reference.

### Confirmed orientation (this unit — verified by multimeter)

The pin order on the installed sensor was confirmed **empirically**, not
trusted from markings:

- **Method:** multimeter in diode mode, sensor unpowered. GND is the pin
  that shows a forward-diode drop (~0.5 V) to every other pin — it is the
  common net every chip ties to. That test identified GND unambiguously.
- **Result:** with the engraved **`MB7851-B36`** label reading right-side up
  (not upside down), **Pin 7 (GND) is the RIGHTMOST terminal**. Pins then
  run **1 → 7, left to right**, so **Pin 1 is the LEFTMOST terminal**.

| Terminal (label upright) | Pin | Signal | This build      |
| ------------------------ | --- | ------ | --------------- |
| Rightmost                | 7   | GND    | **USED** → `GND` |
| 2nd from right           | 6   | V+     | **USED** → `3V3` |
| 3rd from right           | 5   | TX     | **USED** → `G33` |
| 4th from right           | 4   | RX     | empty           |
| 5th from right           | 3   | AN     | empty           |
| 6th from right           | 2   | PW     | empty           |
| Leftmost                 | 1   | TEMP   | empty           |

**The three wires all land in the right-hand half of the block:** the
rightmost three terminals are GND, V+, TX. The four leftmost terminals
(1–4) stay empty.

### General method (any unit, if the label is missing)

If you ever need to re-verify or identify a different unit:

1. **Diode mode, unpowered** — find GND: the pin with a ~0.5 V forward drop
   to most/all other pins. Find V+: black probe on it, red sweeping the
   others shows drops *into* it.
2. **Capacitance mode** — the V+ ↔ GND pair reads a real µF value (the bulk
   decoupling cap); no other pair does.
3. **Physical cross-check** — Pins 6 (V+) and 7 (GND) are always the
   adjacent pair at one *end* of the block, with **7 the outermost**. Pin 1
   is the lone terminal at the opposite end.
4. **Powered confirmation** — with only power connected, the V+ pin reads
   ~3.3 V; the TX pin shows a flickering voltage (serial data).

### Pin table

| Pin | Label | Name (datasheet)         | Direction | Function in this build                                                          |
| --- | ----- | ------------------------ | --------- | -------------------------------------------------------------------------------- |
| 1   | TEMP  | Temperature sensor input | Input     | Optional external temperature compensation. **Leave unconnected**.               |
| 2   | PW    | Pulse-Width Output       | Output    | Distance as a pulse width (1 µs = 1 mm). **Not used; leave unconnected**.         |
| 3   | AN    | Analog Voltage Output    | Output    | Distance as an analog voltage. **Not used in this build** (serial is preferred). |
| 4   | RX    | Ranging Start / Hold     | Input     | Left open → sensor ranges continuously and auto-transmits. **Leave unconnected**.|
| 5   | TX    | Serial Output            | Output    | **USED.** ASCII `Rnnnn\r` range data, 9600 baud → M5 `G33`.                       |
| 6   | V+    | Supply voltage           | Power     | **USED.** 3.3 VDC from the M5 Atom Lite `3V3` pin.                                |
| 7   | GND   | Ground                   | Power     | **USED.** Common ground with the M5 Atom Lite `GND` pin.                          |

**Wires used in this build: Pin 5 (TX), Pin 6 (V+), Pin 7 (GND).**

---

## 3. Cable colors for the 3-wire run

| Function       | MB7851 pin / screw   | M5 Atom Lite header position         | Wire color |
| -------------- | -------------------- | ------------------------------------ | ---------- |
| +3.3 VDC       | Pin 6 (V+)           | 5-pin row, position 1 — `3V3`        | **Red**    |
| Ground         | Pin 7 (GND)          | 4-pin row, position 4 — `GND`        | **Black**  |
| Serial signal  | Pin 5 (TX)           | 5-pin row, position 5 — `G33`        | **Yellow** |

- **Red = +V** and **Black = GND** is the universal DC convention.
- **Yellow** marks the signal line and is visually distinct from the rails,
  making accidental signal-to-rail shorts unlikely. White is an acceptable
  substitute; never use red or black for the signal.

If your jumper kit is single-colour, mark each wire at *both* ends with
coloured tape matching the table before landing it.

---

## 4. M5 Atom Lite wiring

### Bottom-header pin map

```
  5-pin row (rear/left of bottom):       4-pin row (rear/right of bottom):
  ┌──────────────────────────────┐       ┌──────────────────────┐
  │  3V3   G22   G19   G23   G33 │       │  G21   G25   5V   GND │
  │  pos1  pos2  pos3  pos4  pos5│       │  pos1  pos2  pos3 pos4│
  └──────────────────────────────┘       └──────────────────────┘
```

| M5 Atom Lite header position  | ESP32 GPIO | Used for                       |
| ----------------------------- | ---------- | ------------------------------ |
| 5-pin row, position 1 (`3V3`) | —          | +3.3 V to MB7851 V+            |
| 4-pin row, position 4 (`GND`) | —          | Common ground                  |
| 5-pin row, position 5 (`G33`) | GPIO 33    | UART RX — reads the MB7851 TX  |

`GPIO33` is used as the UART RX pin. The ESP32 routes UART through the GPIO
matrix, so any free GPIO works; G33 is convenient because it sits on the
same 5-pin header as `3V3`.

### Procedure (no soldering)

1. Take three male-to-male Dupont jumpers — Red, Black, Yellow (see §3).
2. On each jumper, snip off the male pin at **one** end and strip **~4 mm**
   of insulation. (4 mm, not 6 mm — the WJEK254 block is a fine 2.54 mm
   pitch; longer strip risks bridging adjacent terminals.)
3. Land the stripped ends in the MB7851 screw terminal — *label upright*:
   - Red → **rightmost-but-one** terminal = Pin 6 (V+)
   - Black → **rightmost** terminal = Pin 7 (GND)
   - Yellow → **3rd-from-right** terminal = Pin 5 (TX)
   Twist each wire's strands tight; tighten the M2 screw firmly without
   crushing the strands.
4. Plug the intact male ends into the M5 Atom Lite bottom female headers:
   - Red → 5-pin row, position 1 (`3V3`)
   - Black → 4-pin row, position 4 (`GND`)
   - Yellow → 5-pin row, position 5 (`G33`)
5. **Verify before powering** — see §9.
6. Power the M5 Atom Lite via its USB-C port.

### Wiring diagram

```
  MB7851 screw terminal (label upright)   wire          M5 Atom Lite female header
  ─────────────────────────────────────   ────          ──────────────────────────
  Pin 5  TX   (3rd from right) ────────── Yellow ──────► 5-pin row, position 5  (G33)
  Pin 6  V+   (2nd from right) ────────── Red    ──────► 5-pin row, position 1  (3V3)
  Pin 7  GND  (rightmost)      ────────── Black  ──────► 4-pin row, position 4  (GND)

  Pins 1–4  (the four leftmost terminals)  ──── empty, no wire
```

---

## 5. Why 3.3 V supply (and not 5 V)

The MB7851 supports 3.0 – 5.5 V, and the M5 Atom Lite exposes a 5 V pin —
but **the supply voltage must be 3.3 V for this serial build.**

The MB7851's TX output swings between 0 V and Vcc. The ESP32's GPIOs are
**not 5 V-tolerant**:

| Vcc   | TX line swing | Safe for `G33`?                                |
| ----- | ------------- | ----------------------------------------------- |
| 3.3 V | 0 – 3.3 V     | **Yes** — directly into G33                     |
| 5.0 V | 0 – 5.0 V     | **No** — 5 V on G33 damages the ESP32 GPIO      |

Powering from `3V3` keeps the TX line in the ESP32-safe range with no extra
parts. (The serial *data* is identical at any Vcc — distance is encoded as
ASCII digits, not as a voltage — so 5 V buys nothing here. The Grove port
carries 5 V; **do not power the sensor from the Grove port.**)

---

## 6. Serial output — why it is used, and how distance is read

The MB7851 reports the same measurement three ways. This build uses serial:

| Output         | Pin | Notes                                                                       |
| -------------- | --- | --------------------------------------------------------------------------- |
| **Serial (TX)**| 5   | **USED.** Exact 1 mm digital value, no calibration, Vcc-independent, robust. |
| Analog (AN)    | 3   | Voltage ∝ distance. Subject to ADC noise/non-linearity; needs calibration.  |
| Pulse-Width    | 2   | 1 µs = 1 mm. Works, but no advantage over serial here.                      |

Serial is the right choice for a critical water supply: the reading is an
exact integer in millimetres, immune to ADC drift and supply variation, and
needs no per-unit calibration.

### The `Rnnnn Tnnn\r` serial frame (WRMT)

The **WRMT** ("MaxTemp") variant transmits a distance field **and** a
temperature field every measurement, at **9600 baud, 8-N-1** — 11 bytes:

| Part   | Bytes              | Meaning                                          |
| ------ | ------------------ | ------------------------------------------------ |
| `R`    | ASCII 0x52         | Start marker — distance field follows            |
| `nnnn` | 4 ASCII digits     | Range in **millimetres**, zero-padded            |
| ` `    | ASCII 0x20 (space) | Field separator                                  |
| `T`    | ASCII 0x54         | Start marker — temperature field follows         |
| `nnn`  | 3 ASCII digits     | Temperature reading (units unverified)           |
| `\r`   | ASCII 0x0D (CR)    | End marker                                       |

Example (captured by UART debug): `R2435 T012\r` → 2435 mm distance. The
sensor free-runs (Pin 4 left open), transmitting ~2 frames per second.

> **⚠ Not parseable by `hrxl_maxsonar_wr`.** ESPHome's stock
> `hrxl_maxsonar_wr` component accepts only the plain `Rnnnn\r` frame and
> rejects every WRMT frame as "Invalid data read from sensor". This build
> therefore parses the frame itself in the UART handler — see §7.

> **⚠ Serial polarity.** The supplier packing slip lists this unit's
> output as **"TTL/RS232"** (§11). In practice it reads correctly with a
> **non-inverted** ESPHome UART — confirmed by clean `Rnnnn` frames on this
> unit (`rx_pin: GPIO33`, no `inverted:`). Only if a *future* unit shows
> **no readings at all** on first boot is the output RS232-format
> (inverted); then set `rx_pin` to the inverted block form in §7.

---

## 7. ESPHome configuration

The device is deployed to the Home Assistant ESPHome host as
`water-tank-sensor.yaml`. Key sections:

```yaml
uart:
  id: maxbotix_uart
  rx_pin: GPIO33
  baud_rate: 9600
  # The WRMT frame "Rnnnn Tnnn\r" is not parseable by hrxl_maxsonar_wr
  # (§6), so it is parsed here: the debug feature splits the RX stream on
  # CR, and the lambda reads the 4 distance digits and publishes them.
  debug:
    direction: RX
    dummy_receiver: true
    after:
      delimiter: "\r"
    sequence:
      - lambda: |-
          // Reject only structurally-corrupt frames; publish every
          // well-formed reading — see "No range gate" below.
          if (bytes.size() < 5 || bytes[0] != 'R') return;
          int mm = 0;
          for (int i = 1; i <= 4; i++) {
            if (bytes[i] < '0' || bytes[i] > '9') return;
            mm = mm * 10 + (bytes[i] - '0');
          }
          id(tank_distance).publish_state(mm / 1000.0f);

sensor:
  - platform: template
    name: "Tank Distance"
    id: tank_distance
    unit_of_measurement: "m"
    device_class: distance
    accuracy_decimals: 3
    state_class: measurement
    filters:
      - sliding_window_moving_average: { window_size: 5, send_every: 5 }
```

`hrxl_maxsonar_wr` is **not** used — see §6.

### No range gate — faults must stay visible

The parser publishes **every** well-formed reading. It rejects *only*
structurally-corrupt frames (no `R` prefix, non-digit characters — i.e.
line noise). It does **not** discard readings for being out of the normal
tank range, because those readings are exactly the ones that matter:

- **~50 mm** — water (or an object) right at the transducer → the tank is
  **overflowing**, or the sensor has dropped onto something.
- **~6500 mm** — the sensor's "no target detected" value → it has been
  knocked askew, fallen off, or the water is below sensing range.

Silently dropping these would freeze `tank_distance` at its last good
value and **disguise a fault as a healthy, stable level** — the worst
failure mode for a critical water supply. So they are published, and the
fault conditions are surfaced explicitly (next section).

### Fault detection

Two `binary_sensor`s (device class `problem`) watch `tank_distance` and
turn **on** when it leaves the normal tank window. A `delayed_on: 30s`
filter ignores brief spikes — they trip only on a sustained condition.

```yaml
substitutions:
  overflow_distance_m: "0.30"    # closer than this = overfull / overflowing
  no_target_distance_m: "5.0"    # beyond this = no target / sensor displaced

binary_sensor:
  - platform: template
    name: "Water Tank Overflow Risk"
    device_class: problem
    lambda: |-
      if (isnan(id(tank_distance).state)) return {};
      return id(tank_distance).state < ${overflow_distance_m};
    filters:
      - delayed_on: 30s

  - platform: template
    name: "Water Tank Sensor Fault"
    device_class: problem
    lambda: |-
      if (isnan(id(tank_distance).state)) return {};
      return id(tank_distance).state > ${no_target_distance_m};
    filters:
      - delayed_on: 30s
```

Both thresholds are `substitutions` — **tune them after install** to the
real tank geometry. Wire a Home Assistant automation to these entities to
get notified the moment the tank overflows or the sensor is disturbed.

### Water level math

The deployed config models a 5 m-tall, 5000 L tank:

```yaml
  - platform: template          # Water Tank Level, %
    lambda: |-
      if (isnan(id(tank_distance).state)) return NAN;
      float depth_m = 5.0f - id(tank_distance).state;
      return clamp(depth_m / 5.0f * 100.0f, 0.0f, 100.0f);

  - platform: template          # Water Tank Volume, L
    lambda: |-
      if (isnan(id(tank_distance).state)) return NAN;
      float depth_m = 5.0f - id(tank_distance).state;
      return clamp(depth_m / 5.0f * 5000.0f, 0.0f, 5000.0f);
```

The two `5.0` constants are the **tank height in metres** and the `5000` is
the **tank capacity in litres**. **Set these to the real tank dimensions
after install** — measure the sensor-face-to-bottom distance for an empty
tank and the tank's rated capacity.

### Diagnostics

A `wifi_signal` sensor publishes the Wi-Fi RSSI as **"Wi-Fi Signal"**:

```yaml
  - platform: wifi_signal
    name: "Wi-Fi Signal"
    update_interval: 60s
```

Use it to judge how much the enclosure attenuates Wi-Fi (see §8). Healthy
is better than −70 dBm; −80 dBm or worse means dropped readings.

---

## 8. Mounting notes

- Mount the sensor at the **top centre** of the tank, transducer pointing
  straight down.
- Keep the transducer face at least **50 mm** above the maximum water
  level — that is the sensor's near-field floor; anything closer all reads
  as 50 mm. A generous margin above that is recommended for stable readings.
- Avoid mounting directly above the inlet stream; falling water creates
  acoustic noise. Aim for the calmest part of the surface.
- The MB7851 head is IP67 but the **WJEK254 screw-terminal block is not**.
  Mount the terminal block and the M5 Atom Lite inside a dry enclosure
  outside the tank.
- **Enclosure material & Wi-Fi.** The M5 Atom Lite has only a small
  on-board PCB antenna. A **plastic enclosure is RF-transparent** and the
  safe choice. A metal enclosure acts as a partial Faraday cage — if metal
  is unavoidable, mount the Atom with its antenna end against the plastic
  cap, ≥10 mm from any metal surface, and confirm the "Wi-Fi Signal"
  reading after install (better than −70 dBm). A short link (the AP a few
  metres away) leaves plenty of margin for a partial metal enclosure.
- Run only the sensor head's factory cable into the tank space; keep the
  3-wire jumper run and the M5 dry.

---

## 9. Verifying the wiring (before first power-up)

Use a multimeter to catch a mistake while it is still harmless. The MB7851
has **no reverse-polarity protection** — a wrong screw can kill it.

1. **Continuity check (everything unpowered).** Meter in continuity mode,
   confirm each jumper connects the intended points:
   - M5 `3V3` ↔ Pin 6 terminal — should beep
   - M5 `GND` ↔ Pin 7 terminal — should beep
   - M5 `G33` ↔ Pin 5 terminal — should beep
   - Adjacent screw terminals ↔ each other — should **NOT** beep (no stray
     strand bridging the 2.54 mm pitch).
2. **Powered voltage check.** Power the M5 by USB; meter on DC volts, black
   probe on M5 `GND`:
   - Red probe on Pin 6 terminal → must read **~3.3 V**.
   - Red probe on Pin 5 terminal → a *flickering* low voltage = serial data
     (the sensor is alive).
3. **Smoke test.** In the first 1–2 seconds of power, feel the MB7851 — it
   must stay **cold**. Any warmth or smell → pull USB immediately.

---

## 10. Files

- `water-tank-sensor.yaml` — ESPHome config for this device (deployed to the
  Home Assistant ESPHome host at `/config/esphome/`).
- `calestis-water-level-sensor.md` — this document, the authoritative
  wiring and configuration reference.

---

## 11. Product identification & procurement

Recorded from the product label and the MaxBotix packing slip, for
traceability, warranty, and re-ordering.

### Product label (on the anti-static bag)

| Field             | Value                                               |
| ----------------- | --------------------------------------------------- |
| Part #            | MB7851-B36                                          |
| Lot #             | 80427                                               |
| Date code         | 2550 (year 2025, week 50)                           |
| Country of origin | US                                                  |
| UPC               | 665096105253                                        |
| US Patent         | 7,679,996                                           |
| Compliance        | CE, RoHS, FCC; California Prop 65 warning on label  |

### Packing slip

| Field                      | Value                                                       |
| -------------------------- | ----------------------------------------------------------- |
| Supplier                   | MaxBotix Inc., 13860 Shawkia Drive, Brainerd, MN 56401, USA  |
| Contact                    | sensors@maxbotix.com · +1 218 307 9251                      |
| Manufacturer's description | **XL-TankSensor-WRMT**                                      |
| Output details             | **TTL/RS232**                                               |
| Connection details         | **Screw Terminal Block (7-pin)**                            |
| Packing slip #             | 102522                                                      |
| Invoice #                  | 12514                                                       |
| Order date / shipped       | 2025-12-12, UPS Ground                                      |
| Tracking #                 | 1Z29V0F10399881108                                          |

The packing slip confirms two facts this document relies on: the output is
**TTL/RS232** (see the polarity note in §6) and the connector is a **7-pin
screw terminal block** (§2). MaxBotix markets MB7851-B36 as the
**XL-TankSensor-WRMT**, a tank-level member of the MaxSonar WRMT family.

> **Naming note.** The body of this document also refers to the sensor as
> "HRXL-MaxSonar-WRMT"; the manufacturer's own description is
> "XL-TankSensor-WRMT". Both denote part **MB7851-B36**. If exact
> resolution/range figures matter, verify them against the MaxBotix
> MB7851 datasheet.
