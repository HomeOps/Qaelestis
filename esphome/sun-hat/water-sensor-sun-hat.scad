// ============================================================================
//  Water-Level-Sensor Sun Hat  —  Donut Base  (Stage 1 of: base + 4 arms + canopy)
// ----------------------------------------------------------------------------
//  Shades the M5 Atom Lite enclosure that sits on top of the water-tank lid,
//  over the RAINPAL 2" PVC bulkhead (body OD 70.8 mm, ASIN B0DQ61T7BV).
//  Material: WHITE ASA (UV- and weather-resistant — outdoor Calestis, Costa Rica).
//
//  This file currently builds ONLY the donut base. The 4 arms and the umbrella
//  canopy attach to the bosses on top of the ring in later stages.
//
//  All dimensions are PARAMETRIC — every value below is an assumption marked
//  [VERIFY] until measured on the real install. Edit the number, re-render.
// ============================================================================

// ---- Render quality -------------------------------------------------------
$fn = 160;                 // facets for the revolve / cylinders

// ---- Z/S-donut cross-section (from the hand sketch, 2026-06-07) ------------
//  Profile is an "S"/"Z" ribbon of constant thickness `ribbon_w`:  _|  + upper -
//   - bottom FOOT : horizontal, extends INWARD  (the "_|")
//   - vertical COLUMN : the bore wall, height `total_height`, bore Ø109 -> Ø109.3
//   - top ARM : horizontal, extends OUTWARD      (the upper "-")
//  Revolved into a donut.  ribbon_w is the inner-ring-to-outer-ring wall (2.6 mm).
bore_bottom_d = 109;       // [SKETCH] bore diameter at the bottom / lower ring (Ø109)
bore_top_d    = 109.3;     // [SKETCH] bore diameter at the top / upper ring   (Ø109.3)
                           //          0.3 mm bigger at top -> wall tilts out ~1.4deg
column_height = 6.1;       // [SKETCH] height of the vertical column (6.1 mm)
ribbon_w      = 2.6;       // [SKETCH] ribbon thickness = inner-ring to outer-ring (2.6 mm)
arm_reach     = 7.4;       // [SKETCH] top arm overhang past the wall (1 cm - 2.6 = 7.4 mm)
inner_ring_w  = 5.2;       // [SKETCH] inner-ring (foot) TOTAL width = 2.6 + 2.6 (lip + wall)
total_height  = column_height + ribbon_w;   // = 8.7 mm (arm thickness stacks on column)

// Debug: set true (or -D show_section_2d=true) to render just the 2D Z profile.
show_section_2d = false;
// Debug: set true (or -D show_dims=true) to render the dimensioned cross-section.
show_dims       = false;

// ---- Arms: 3 at 120°, each a Ø5 mm rod, 20 cm tall, CHAINED to the ring -----
arm_count = 3;             // number of arms, equally spaced
arm_d     = 5;             // arm rod diameter (mm)
arm_h     = 170;           // arm rod height (17 cm)
show_arms = true;          // show the arms

// Print-in-place SINGLE chain joint: ring-eye interlinks the arm-lug directly.
hole_d     = 3;            // hole inside each loop (ring-eye & arm-lug)
link_stock = 2;            // loop stock diameter (Ø)
clearance  = 0.4;          // print-in-place gap for free movement (ASA)
rod_drop   = 0.5;          // lower the rod into the lug loop for a stronger weld

// The arm TOP end is a PIN with a tight (friction) fit into an umbrella socket.
pin_d       = 4;           // pin diameter (reduced from the rod -> shoulder stop)
pin_len     = 10;          // pin engagement depth into the umbrella socket
pin_fit     = 0.15;        // socket clearance — tight friction fit for ASA
socket_wall = 2.5;         // wall around each umbrella socket

// ---- Umbrella (canopy) held by the 3 arms, hooked at its rim ----------------
umbrella_d    = 200;       // max canopy diameter (20 cm) — HARD outer limit
umbrella_h    = 30;        // canopy height (3 cm)
umbrella_wall = 2;         // canopy shell wall
attach_inset  = 0.5;       // extra margin inside the flush-with-rim socket position
show_umbrella = true;

// ===========================================================================
//  Derived
// ===========================================================================
bore_b_r   = bore_bottom_d / 2;            // bore radius, bottom
bore_t_r   = bore_top_d / 2;               // bore radius, top
col_o_b    = bore_b_r + ribbon_w;          // column outer face, bottom
col_o_t    = bore_t_r + ribbon_w;          // column outer face, top
foot_tip   = col_o_b  - inner_ring_w;      // foot inner tip (inward); lip = 2.6 past bore
arm_tip    = col_o_t  + arm_reach;         // top arm outer tip (outward)
arm_pcd_r  = (col_o_t + arm_tip) / 2;      // arms centred on the top flange
link_rt    = link_stock / 2;               // chain stock tube radius
loop_R     = hole_d / 2 + link_rt;         // loop major radius (inner hole = hole_d)
link_dz    = loop_R;                       // vertical centre-to-centre of chain loops

// chain z-stack (local, above the flange) and arm geometry
ze_c       = loop_R;                       // eye loop centre
zg_c       = ze_c + link_dz;               // lug loop centre
za_c       = zg_c + loop_R - rod_drop;     // rod base (local)
rod_base_z = total_height + za_c;          // world z where each rod starts
umb_r      = umbrella_d / 2;               // canopy radius (Ø200 -> 100), HARD outer limit
attach_r   = umb_r - (pin_d / 2 + socket_wall) - attach_inset;  // socket OUTER edge ~flush with the Ø200 rim
// EASY MATH, counting the chain (rod_base_z) AND the hook (hook_reach):
arm_eff    = arm_h;                                    // rod reaches the umbrella underside
arm_angle  = asin((attach_r - arm_pcd_r) / arm_eff);   // outward tilt from vertical (deg)
arm_rise   = arm_eff * cos(arm_angle);                 // vertical rise (rod base -> umbrella underside)
grab_z     = rod_base_z + arm_rise;                    // socket-opening height (at attach_r)
dome_h_in  = umbrella_h * sqrt(1 - pow(attach_r / umb_r, 2));  // dome height over rim at attach_r

// ===========================================================================
//  Modules
// ===========================================================================

// 2D cross-section of the Z/S-donut: a constant-`ribbon_w` ribbon, in the
// radial plane (x = radius, y = height). Three overlapping rects = the ribbon.
module ring_section() {
    // bottom FOOT — horizontal, extends inward to foot_tip  (z 0 .. ribbon_w)
    polygon([
        [foot_tip, 0], [col_o_b, 0],
        [col_o_b, ribbon_w], [foot_tip, ribbon_w],
    ]);
    // vertical COLUMN — the bore wall, tilts out bore_b_r -> bore_t_r  (z 0 .. column_height)
    polygon([
        [bore_b_r, 0], [col_o_b, 0],
        [col_o_t, column_height], [bore_t_r, column_height],
    ]);
    // top ARM — horizontal, extends outward to arm_tip  (z column_height .. total_height)
    polygon([
        [bore_t_r, column_height], [arm_tip, column_height],
        [arm_tip, total_height], [bore_t_r, total_height],
    ]);
}

module donut_ring() {
    rotate_extrude(convexity = 4) ring_section();
}

// A torus ring (hole axis = Z, lies in the XY plane).
module ring(R, r) rotate_extrude($fn = 64) translate([R, 0]) circle(r = r, $fn = 24);
module loop() ring(loop_R, link_rt);                 // the chain loop

// The rod only, built straight along +z (tilted later by the caller).
// The vertical pin is added separately in chain_arm so it stays vertical.
module arm_rod() {
    cylinder(d = arm_d, h = arm_h, $fn = 48);                            // Ø5 rod
}

// One chained arm, built in a local frame (x = radial, y = tangential, z = up):
//   flange -> stem -> EYE loop -> LUG loop -> tilted rod -> HOOK.
// The two loops interlink directly (single chain); the rod tilts out `arm_angle`
// so its hooked top reaches the wider umbrella rim.
module chain_arm() {
    cylinder(d = link_stock, h = ze_c, $fn = 24);              // stem to the eye
    translate([0, 0, ze_c]) rotate([90, 0, 0]) loop();        // EYE  (X-Z plane)
    translate([0, 0, zg_c]) rotate([0, 90, 0]) loop();        // LUG  (Y-Z plane)
    translate([0, 0, za_c]) rotate([0, arm_angle, 0]) arm_rod();   // tilted rod
    // VERTICAL pin at the rod top so the umbrella lifts straight off
    rtx = arm_h * sin(arm_angle);                  // rod top, radial offset (local)
    rtz = za_c + arm_h * cos(arm_angle);           // rod top, height (local) = grab_z - total_height
    translate([rtx, 0, rtz - 1])
        cylinder(d = pin_d, h = pin_len + 1, $fn = 32);   // (1 mm overlaps the rod)
}

module arms() {
    for (i = [0 : arm_count - 1])
        rotate([0, 0, i * 360 / arm_count])
            translate([arm_pcd_r, 0, total_height])
                chain_arm();
}

// Shallow dome (top half of an ellipsoid): diameter d, height h, rim at z=0.
module dome(d, h) {
    intersection() {
        resize([d, d, 2 * h]) sphere(d = d, $fn = 96);
        cylinder(r = d / 2 + 1, h = h + 1, $fn = 96);    // keep only z in [0, h]
    }
}

// The umbrella canopy: a thin dome shell with `arm_count` tight-fit sockets on
// the underside (inside the rim, at attach_r) — the arm pins push into these.
module umbrella() {
    translate([0, 0, grab_z])                          // canopy rim at the socket-opening height
        difference() {
            dome(umbrella_d, umbrella_h);
            dome(umbrella_d - 2 * umbrella_wall, umbrella_h - umbrella_wall);
        }
    for (i = [0 : arm_count - 1])
        rotate([0, 0, i * 360 / arm_count])
            translate([attach_r, 0, grab_z])
                difference() {                         // VERTICAL socket (straight down)
                    cylinder(d = pin_d + 2 * socket_wall, h = dome_h_in, $fn = 32);  // boss up to the dome
                    translate([0, 0, -0.1])
                        cylinder(d = pin_d + pin_fit, h = pin_len + 0.1, $fn = 32);  // socket hole
                }
}

module sun_hat_base() {
    donut_ring();
    if (show_arms)     arms();
    if (show_umbrella) umbrella();
}

// ---- Dimensioned cross-section (to compare against the hand sketch) --------
//  Renders the Z profile flat (foot lower-left toward the axis, arm upper-right)
//  with every sketch dimension annotated. View flat: render top-ortho.
module _dline(p1, p2, w = 0.1)
    hull() { translate(p1) circle(w, $fn = 8); translate(p2) circle(w, $fn = 8); }

module _dtext(p, s, sz = 1.6, rot = 0)
    translate(p) rotate(rot) text(s, size = sz, halign = "center", valign = "center", $fn = 32);

module dimensioned_section() {
    // the actual profile, light grey
    color([0.8, 0.8, 0.82]) ring_section();
    color([0.1, 0.1, 0.1]) {
        // axis-of-revolution hint (to the left, smaller radius)
        _dline([foot_tip - 11, 0], [foot_tip - 8, 0]);
        _dtext([foot_tip - 11.5, 1.0], "axis <-", 1.2);

        // inner-ring total width 5.2  (bottom: foot_tip -> col_o_b)
        _dline([foot_tip, -2.4], [col_o_b, -2.4]);
        _dline([foot_tip, 0], [foot_tip, -2.7]);
        _dline([col_o_b, 0], [col_o_b, -2.7]);
        _dtext([(foot_tip + col_o_b) / 2, -3.6], "5.2  (total)");

        // exposed lip = 2.6 x 2.6 square (left + top of the inner ring)
        _dline([foot_tip, ribbon_w + 1.4], [bore_b_r, ribbon_w + 1.4]);     // top width 2.6
        _dline([bore_b_r, ribbon_w], [bore_b_r, ribbon_w + 1.7]);
        _dtext([(foot_tip + bore_b_r) / 2, ribbon_w + 2.3], "2.6");
        _dline([foot_tip - 1.4, 0], [foot_tip - 1.4, ribbon_w]);            // left height 2.6
        _dline([foot_tip - 1.7, 0], [foot_tip, 0]);
        _dline([foot_tip - 1.7, ribbon_w], [foot_tip, ribbon_w]);
        _dtext([foot_tip - 2.9, ribbon_w / 2], "2.6", 1.4, 90);

        // wall / ribbon 2.6  (top of arm, bore_t_r -> col_o_t)
        _dline([bore_t_r, total_height + 2.4], [col_o_t, total_height + 2.4]);
        _dline([bore_t_r, total_height], [bore_t_r, total_height + 2.7]);
        _dline([col_o_t,  total_height], [col_o_t,  total_height + 2.7]);
        _dtext([(bore_t_r + col_o_t) / 2, total_height + 3.4], "2.6");

        // arm reach 7.4  (top, outward)
        _dline([col_o_t, total_height + 2.4], [arm_tip, total_height + 2.4]);
        _dline([arm_tip, total_height], [arm_tip, total_height + 2.7]);
        _dtext([(col_o_t + arm_tip) / 2, total_height + 3.4], "7.4");

        // total height 8.7  (far right)
        _dline([arm_tip + 4, 0], [arm_tip + 4, total_height]);
        _dline([arm_tip, 0], [arm_tip + 4.3, 0]);
        _dline([arm_tip, total_height], [arm_tip + 4.3, total_height]);
        _dtext([arm_tip + 6, total_height / 2], "8.7", 1.6, 90);

        // column height 6.1  (further left of the foot)
        _dline([foot_tip - 6, 0], [foot_tip - 6, column_height]);
        _dline([foot_tip - 6.3, 0], [foot_tip - 1.4, 0]);
        _dline([foot_tip - 6.3, column_height], [bore_b_r, column_height]);
        _dtext([foot_tip - 7.6, column_height / 2], "6.1", 1.6, 90);

        // bore diameters at the two rings
        _dline([bore_b_r, 0], [bore_b_r + 3, -1.3]);
        _dtext([bore_b_r + 7.5, -1.6], "Ø109  (lower)", 1.4);
        _dline([bore_t_r, column_height], [bore_t_r + 3, column_height + 1.3]);
        _dtext([bore_t_r + 8.5, column_height + 1.6], "Ø109.3  (upper)", 1.4);
    }
}

// ===========================================================================
//  Build
// ===========================================================================
if      (show_dims)       dimensioned_section();  // annotated 2D cross-section
else if (show_section_2d) ring_section();         // plain 2D Z profile
else                      sun_hat_base();          // the donut (+ arms if show_arms)
