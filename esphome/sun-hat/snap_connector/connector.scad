// ============================================================
// connector.scad — reusable cantilever snap-fit connector
//
// A self-contained, parametric component. Import it with `use`
// and call the modules; every dimension is a module argument
// that defaults to the globals below, so a consumer can override
// any of them per call without editing this file.
//
// MALE:   flexible arm with a hook. Hook underside is the flat
//         catch face; hook top is a ramp for tool-free insertion.
//         The male is printed `fit` mm undersize per side so it
//         is never a zero-clearance press fit.
// FEMALE: socket with a latch window through the front wall, plus
//         a shallow ramp-to-flat-ledge "catch lip" on the inner
//         wall (_|-|_). The head rides the ramp inward on the way
//         in, then its flat catch face drops onto the ledge and
//         locks. The window doubles as flathead-screwdriver access
//         (sized 5.0 x 1.8 x 3.0 mm deep by default).
//
// RELEASE: insert a flathead screwdriver into the front window,
//          push the head inward (toward the arm) to clear the
//          ledge, then pull the male down/out.
//
// Usage in your own designs:
//   use <snap_connector/connector.scad>   // from the parent dir
//   use <connector.scad>                  // from this dir
//   snap_male();                          // union into part A
//   difference(){ yourBody(); snap_female_cutout(wall=YOUR_WALL); }
//   ...or snap_female();                  // standalone socket block
// Override anything per call, e.g. snap_male(arm_w=6, fit=0.2).
//
// Both parts share the same origin: male fully inserted ==
// both modules placed at the same position/orientation. (The
// female's open bottom then sits flush on the male's base plate.)
//
// PRINTING (ASA):
// - Print the MALE on its side so layer lines run ALONG the
//   arm; printed upright, the hook shears off at a layer line.
// - clr (female) + fit (male) set the slip gap; tune those two
//   to taste. `back` keeps flex room when clr is shrunk.
// - Cantilever strain ~ 1.5 * arm_t * hook_d / arm_l^2.
//   Keep <= ~2% for ASA. Defaults: 1.5*1.2*1.0/12^2 = 1.25%.
// ============================================================

/* [Fit] */
clr   = 0.15;   // per-side clearance in the FEMALE cavity (smaller = tighter hole)
fit   = -0.10;  // per-side size offset on the MALE. POSITIVE = undersize (looser),
                // NEGATIVE = oversize (fatter/tighter). Net slip gap = clr + fit:
                //   0.25 / +0.15 -> 0.40/side (original: too loose, wouldn't snap)
                //   0.15 / -0.10 -> 0.05/side (tight: smaller hole + fatter male)
                // If it won't go together, raise fit toward 0 (or clr toward 0.20);
                // if still loose, push fit to -0.15.
slack = 0.15;   // vertical engagement slack (ledge sits this far below catch)
back  = 0.4;    // extra flex pocket behind the arm, so shrinking clr does NOT
                // starve the hook's deflection room (keeps it from jamming)

/* [Snap geometry] */
arm_w  = 4.7;   // arm width  (Y) -> latch window = arm_w + 2*clr = 5.0 mm wide
arm_t  = 1.2;   // arm thickness (X) -- thinned so the short arm can flex
arm_l  = 12;    // flexible arm length below the catch face
hook_d = 1.0;   // hook overhang (deflection distance)
hook_h = 1.5;   // hook ramp height -> latch window = hook_h + clr + slack = 1.8 mm tall
wall   = 3.0;   // female wall thickness -> latch window = 3.0 mm deep (screwdriver reach)
top_w  = 2.4;   // female top wall thickness
chm    = 0.8;   // entry chamfer on female opening

/* [Catch lip] */
lip_d  = 0.3;   // how far the female catch lip protrudes into the channel
lip_h  = 2.0;   // vertical run of the lip's lead-in ramp (slope = lip_d/lip_h)

eps = 0.01;

/* [Preview] */
part = "demo"; // [demo, male, female, assembled, cutout]

// ---------------------- MALE ----------------------
// Arm rises from z=0; catch face at z=arm_l; hook points +X.
module snap_male(arm_w=arm_w, arm_t=arm_t, arm_l=arm_l,
                 hook_d=hook_d, hook_h=hook_h, fit=fit,
                 base=true, base_pad=4, base_t=3,
                 plug=true, plug_h=3, plug_clr=0.0)  // 0 = fills cavity fully;
{                                                    // go negative for a press fit

    // Undersize the printed male so it slips into the female cavity.
    // Width loses `fit` per side; front face pulls back by `fit`.
    // The catch overhang `hook_d` is kept full so engagement on the
    // ledge is unchanged.
    mw = arm_w - 2*fit;          // male width (Y)
    mt = arm_t - fit;            // male front-face thickness (X)

    // arm + hook: 2D profile in XZ extruded across Y
    translate([0, mw/2, 0])
        rotate([90, 0, 0])
            linear_extrude(mw)
                polygon([
                    [0, 0],
                    [mt, 0],
                    [mt, arm_l],                 // front face
                    [mt + hook_d, arm_l],        // 90° catch face
                    [mt, arm_l + hook_h],        // insertion ramp
                    [0, arm_l + hook_h]
                ]);

    // optional mounting base (delete and union the arm into your part)
    if (base)
        translate([-(base_pad + hook_d), -arm_w/2 - base_pad, -base_t])
            cube([arm_t + hook_d + 2*base_pad,
                  arm_w + 2*base_pad,
                  base_t]);

    // bottom plug: almost-fills the female's LOWER cavity so the male
    // seats with no wobble (held at the base AND the hook). Sized to the
    // female channel (uses globals clr, back) minus plug_clr per side.
    if (plug) {
        pcx0 = -hook_d - clr - back;     // female channel back
        pcx1 = arm_t + clr;              // female channel front
        pcw  = arm_w + 2*clr;            // female channel width
        translate([pcx0 + plug_clr, -pcw/2 + plug_clr, 0])
            cube([(pcx1 - pcx0) - 2*plug_clr,
                  pcw - 2*plug_clr,
                  plug_h]);
    }
}

// ----------------- FEMALE (cavity) -----------------
// Subtract this from your own solid. The latch window extends
// `wall` in +X — pass your actual wall thickness if thicker,
// so the window goes all the way through for the screwdriver.
module snap_female_cutout(arm_w=arm_w, arm_t=arm_t, arm_l=arm_l,
                          hook_d=hook_d, hook_h=hook_h,
                          clr=clr, slack=slack, wall=wall, chm=chm,
                          lip_d=lip_d, lip_h=lip_h)
{
    cw  = arm_w + 2*clr;            // channel width
    cx0 = -hook_d - clr - back;     // channel back (room for deflection)
    cx1 = arm_t + clr;              // channel front inner face
    ch  = arm_l + hook_h + clr;     // channel height

    difference() {
        union() {
            // insertion channel (open at bottom, z=0)
            translate([cx0, -cw/2, -eps])
                cube([cx1 - cx0, cw, ch + eps]);

            // latch window through the front (+X) wall
            translate([cx1 - eps, -cw/2, arm_l - slack])
                cube([wall + 2*eps, cw, hook_h + clr + slack]);

            // entry chamfer around the opening
            hull() {
                translate([cx0 - chm, -cw/2 - chm, -eps])
                    cube([cx1 - cx0 + 2*chm, cw + 2*chm, eps]);
                translate([cx0, -cw/2, chm])
                    cube([cx1 - cx0, cw, eps]);
            }
        }

        // CATCH LIP — a shallow ramp on the inner front wall rising to
        // a flat ledge at the window bottom (the "_|-|_" detent). Carved
        // OUT of the channel so it stays as solid material whether the
        // socket is built standalone or this cutout is differenced from
        // your own body. On insertion the male head rides the ramp inward;
        // at the top its flat catch face drops onto the ledge and locks.
        translate([0, cw/2 + eps, 0])
            rotate([90, 0, 0])
                linear_extrude(cw + 2*eps)
                    polygon([
                        [cx1 + eps,   arm_l - slack - lip_h],  // ramp foot (at wall)
                        [cx1 + eps,   arm_l - slack],          // ledge outer
                        [cx1 - lip_d, arm_l - slack]           // ledge inner (protrudes)
                    ]);
    }
}

// --------------- FEMALE (standalone block) ---------------
module snap_female(arm_w=arm_w, arm_t=arm_t, arm_l=arm_l,
                   hook_d=hook_d, hook_h=hook_h,
                   clr=clr, slack=slack, wall=wall, top_w=top_w, chm=chm)
{
    cw  = arm_w + 2*clr;
    cx0 = -hook_d - clr - back;
    cx1 = arm_t + clr;
    ch  = arm_l + hook_h + clr;

    difference() {
        translate([cx0 - wall, -cw/2 - wall, 0])
            cube([(cx1 - cx0) + 2*wall, cw + 2*wall, ch + top_w]);
        snap_female_cutout(arm_w, arm_t, arm_l, hook_d, hook_h,
                           clr, slack, wall, chm);
    }
}

// ---------------------- PREVIEW ----------------------
if (part == "male")        snap_male();
else if (part == "female") snap_female();
else if (part == "cutout") snap_female_cutout();
else if (part == "assembled") { snap_male(); %snap_female(); }
else { // demo: side by side
    snap_male();
    translate([25, 0, 0]) snap_female();
}
