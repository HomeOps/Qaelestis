use <connector.scad>
$fn = 64;
// male (left) and female (right), both sliced at Y=0, no overlap
intersection() {
    union() {
        color("SteelBlue")                       snap_male();
        color("Tan")        translate([16,0,0])  snap_female();
    }
    translate([-60,-60,-80]) cube([120,60,180]);
}
