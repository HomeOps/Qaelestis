# Water-Level-Sensor Sun Hat — Donut Base

Parametric base for the sun/rain hat that shades the M5 Atom Lite enclosure
sitting on top of the water-tank lid, over the RAINPAL 2" PVC bulkhead
(see `../calestis-water-level-sensor.md`). Printed in **white ASA** (UV- and
weather-resistant) for the outdoor Calestis environment.

The base is a **Z/S-shaped ribbon revolved into a donut**. Model:
`water-sensor-sun-hat.scad`. This document covers the **cross-section** only.

---

## Cross-section (revolved about the axis on the LEFT)

```
                    ribbon_w                  arm_reach = 7.4
                     = 2.6
                    |<--->|<----------------------------------->|
                    +-----+-------------------------------------+   --+
                    |     |        top ARM  (outer ring)        |     | ribbon_w
   bore_top_d  ---> |     +-------------------------------------+   --+  = 2.6
   Ø109.3 (upper)   |     |
                    |     |
                    |  w  | --+
                    |  a  |   |
                    |  l  |   | column_height = 6.1
                    |  l  |   |
              +-----+     | --+
   Ø109  ---> | lip |     |          bore_bottom_d  Ø109 (lower)
   (lower)    +-----+-----+   --+
              |           |     | ribbon_w = 2.6   (inner-ring height)
              +-----------+   --+
              |<--- 5.2 -->|
               inner_ring_w  ( = 2.6 lip + 2.6 under wall )

   axis              total_height = column_height + ribbon_w = 6.1 + 2.6 = 8.7
   <---
```

- The **inner ring (foot)** is a `2.6 x 5.2` rectangle. Its exposed **lip** is a
  `2.6 x 2.6` square; the other `2.6` of its width sits under the column wall.
- The **column** is the bore wall, `ribbon_w` thick. Because the upper bore
  (Ø109.3) is `0.3 mm` larger than the lower bore (Ø109), the wall is **conical**
  — it tilts out ~1.4° over its height.
- The **top arm (outer ring)** is `ribbon_w` thick and overhangs the wall by
  `arm_reach`. Measured from the bore it spans `1 cm` (`2.6 + 7.4`).

---

## Parameters (from the hand sketch)

All editable at the top of `water-sensor-sun-hat.scad`; units are millimetres.

| Parameter        | Value | Meaning                                                                 |
| ---------------- | ----- | ----------------------------------------------------------------------- |
| `bore_bottom_d`  | 109   | Bore diameter at the **bottom** (lower ring)                            |
| `bore_top_d`     | 109.3 | Bore diameter at the **top** (upper ring); +0.3 ⇒ conical wall ~1.4°     |
| `column_height`  | 6.1   | Height of the vertical column (the bore wall)                           |
| `ribbon_w`       | 2.6   | Ribbon thickness — inner-ring→outer-ring wall, inner-ring height, AND arm thickness |
| `arm_reach`      | 7.4   | Top-arm overhang past the wall (`1 cm − 2.6`)                            |
| `inner_ring_w`   | 5.2   | Inner-ring (foot) **total** width (`2.6` lip + `2.6` under wall)         |
| `total_height`   | 8.7   | **Derived**: `column_height + ribbon_w` (arm stacks on the column)      |

---

## Derived dimensions

| Feature                | Radius (mm) | Diameter (mm) | Formula                          |
| ---------------------- | ----------- | ------------- | -------------------------------- |
| Lower bore             | 54.5        | **109**       | `bore_bottom_d / 2`              |
| Upper bore             | 54.65       | **109.3**     | `bore_top_d / 2`                 |
| Column outer (bottom)  | 57.1        | 114.2         | `bore_b_r + ribbon_w`            |
| Column outer (top)     | 57.25       | 114.5         | `bore_t_r + ribbon_w`            |
| Inner-ring lip tip     | 51.9        | **103.8**     | `col_o_b − inner_ring_w`         |
| Outer arm edge         | 64.65       | **129.3**     | `col_o_t + arm_reach`            |

---

## Rendering

OpenSCAD (CLI). The model has three view modes via flags:

```powershell
$scad = "C:\Program Files\OpenSCAD\openscad.exe"

# The donut (default)
& $scad -o iso.png --camera=0,0,0,62,0,30,380 --colorscheme=Tomorrow water-sensor-sun-hat.scad

# Plain 2D Z profile
& $scad -o section.png -D "show_section_2d=true" --viewall --autocenter water-sensor-sun-hat.scad

# Dimensioned cross-section (flat, top-down — matches this doc)
& $scad -o dims.png -D "show_dims=true" --camera=0,0,0,0,0,0,100 --viewall --autocenter --projection=ortho water-sensor-sun-hat.scad
```

---

## Files

- `water-sensor-sun-hat.scad` — parametric model of the base.
- `water-sensor-sun-hat.md` — this document.
- `preview-dims.png`, `preview-iso.png`, `preview-section.png` — rendered previews.
