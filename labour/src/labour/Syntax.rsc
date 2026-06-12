module labour::Syntax

layout Whitespace = [\ \t\n\r]* !>> [\ \t\n\r];

// General quoted string for wall/route identifiers and hold shape names
lexical StringLit = "\"" ![\"]* "\"";

// Hold IDs: exactly four decimal digits, quoted (well-formedness rule 9)
lexical HoldIdLit = "\"" [0-9][0-9][0-9][0-9] "\"";

// Integer literal allowing negative values (e.g. depth: -10)
lexical IntegerLit = "-"? [0-9]+ !>> [0-9];

// ---------- Top-level ----------

start syntax BoulderingWall
  = boulderingWall: "bouldering_wall" StringLit ":" "{" Routes "," Volumes "}"
  ;

// ---------- Routes ----------

syntax Routes
  = routes: "routes" "[" {BoulderingRoute ","}* "]"
  ;

// Route body has a fixed order (grade, grid_base_point, holds) per all spec
// examples; this also enforces rules 5 and 6 (all properties present, and the
// grid_base_point having an x and a y component) at parse time.
syntax BoulderingRoute
  = boulderingRoute: "bouldering_route" StringLit ":" "{"
      "grade" ":" StringLit ","
      "grid_base_point" ":" "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}" ","
      "holds" "[" {RouteHoldRef ","}* "]"
    "}"
  ;

// A route hold entry is a direct hold ID or a sub-route branch {id, id, ...}
syntax RouteHoldRef
  = single:   HoldIdLit
  | subRoute: "{" {HoldIdLit ","}+ "}"
  ;

// ---------- Volumes ----------

syntax Volumes
  = volumes: "volumes" "[" {Volume ","}* "]"
  ;

// Only two volume kinds exist (rule 16), enforced at parse time
syntax Volume
  = circle:   CircleVolume
  | triangle: TriangleVolume
  ;

// Circle: mandatory pos/depth/radius (rule 17, parse time)
syntax CircleVolume
  = circleVolume: "circle" ":" "{"
      "pos" ":" XYCoord ","
      "depth" ":" IntegerLit ","
      "radius" ":" IntegerLit
      CircleFaceHolds*
    "}"
  ;

// A circle may only contain front_holds/side_holds lists (rule 18, parse time)
syntax CircleFaceHolds
  = frontHolds: "," "front_holds" "[" {Hold ","}* "]"
  | sideHolds:  "," "side_holds"  "[" {Hold ","}* "]"
  ;

// Triangle: mandatory pos/extrusion/depth/corners with exactly 3 corner items
// (rule 19, parse time)
syntax TriangleVolume
  = triangleVolume: "triangle" ":" "{"
      "pos" ":" XYCoord ","
      "extrusion" ":" XYCoord ","
      "depth" ":" IntegerLit ","
      "corners" "[" XYCoord "," XYCoord "," XYCoord "]"
      TriangleFaceHolds*
    "}"
  ;

// A triangle may only contain left/right/bottom hold lists (rule 20, parse time)
syntax TriangleFaceHolds
  = leftHolds:   "," "left_holds"   "[" {Hold ","}* "]"
  | rightHolds:  "," "right_holds"  "[" {Hold ","}* "]"
  | bottomHolds: "," "bottom_holds" "[" {Hold ","}* "]"
  ;

// ---------- Shared coordinate ----------

// XYCoord is reused for volume pos, extrusion, triangle corners, and hold xy-position
syntax XYCoord
  = xyCoord: "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}"
  ;

// ---------- Holds ----------

syntax Hold
  = hold: "hold" HoldIdLit ":" "{" {HoldProp ","}+ "}"
  ;

// Hold properties are order-independent; required/optional validation is in
// Check.rsc.
syntax HoldProp
  = posProp:      "pos" ":" HoldPos
  | shapeProp:    "shape" ":" StringLit
  | coloursProp:  "colours" "[" {Colour ","}+ "]"
  | startHold:    "start_hold" ":" IntegerLit
  | endHold:      "end_hold"
  | rotationProp: "rotation" ":" IntegerLit
  ;

// A hold position is either an (x, y) coordinate or an angle (rule 12)
syntax HoldPos
  = posXY:    XYCoord
  | posAngle: "{" "angle" ":" IntegerLit "}"
  ;

// start_hold value (1 or 2) and rotation/angle ranges (0-359) are value checks
// that require arithmetic — validated in Check.rsc rather than the grammar.

// ---------- Colours ----------

// All valid colour literals (well-formedness rule 15), enforced at parse time
syntax Colour
  = white:  "white"
  | yellow: "yellow"
  | green:  "green"
  | blue:   "blue"
  | red:    "red"
  | purple: "purple"
  | pink:   "pink"
  | black:  "black"
  | orange: "orange"
  ;
