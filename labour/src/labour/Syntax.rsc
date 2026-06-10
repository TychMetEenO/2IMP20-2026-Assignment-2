module labour::Syntax

/*
 * Concrete syntax for LaBouR (Language for Bouldering Routes).
 *
 * Design decisions:
 * - Hold properties use an order-independent {HoldProp ","}+ list because the
 *   examples in the spec show varying property orderings (e.g. rotation appears
 *   both before and after colours). Presence of required properties (pos, shape,
 *   colours) and absence of duplicates are validated in Check.rsc.
 * - Volume and route bodies use a fixed ordering matching all provided examples.
 *   This keeps the grammar unambiguous without extra semantic deduplication in
 *   the syntax, and is consistent with everything in the spec.
 * - Hold IDs are restricted to exactly 4 decimal digits in the lexical rule,
 *   catching well-formedness rule 9 at parse time.
 * - start_hold uses IntegerLit; the 1-or-2 constraint is a value check validated
 *   in Check.rsc (Rascal syntax rules cannot have bare string literals as their
 *   sole alternative, so a separate StartHoldVal rule is not viable).
 * - Valid colours are enumerated in the Colour non-terminal (well-formedness
 *   rule 15), catching invalid colour names at parse time.
 * - Minimum cardinalities (>= 1 volume/route, >= 2 route holds), value range
 *   checks (rotation 0-359, angle 0-359), and sub-route structure constraints
 *   are deferred to Check.rsc because they require counting or arithmetic that
 *   a context-free grammar cannot express.
 */

layout Whitespace = [\ \t\n\r]* !>> [\ \t\n\r];

// General quoted string for wall/route identifiers and hold shape names
lexical StringLit = "\"" ![\"]* "\"";

// Hold IDs: exactly four decimal digits, quoted (well-formedness rule 9)
lexical HoldIdLit = "\"" [0-9][0-9][0-9][0-9] "\"";

// Integer literal allowing negative values (e.g. depth: -10)
lexical IntegerLit = "-"? [0-9]+ !>> [0-9];

// ---------- Top-level ----------

start syntax BoulderingWall
  = boulderingWall: "bouldering_wall" StringLit "{" Routes "," Volumes "}"
  ;

// ---------- Routes ----------

syntax Routes
  = routes: "routes" "[" {BoulderingRoute ","}* "]"
  ;

// Route body has a fixed order (grade, grid_base_point, holds) per all spec examples
syntax BoulderingRoute
  = boulderingRoute: "bouldering_route" StringLit "{"
      "grade" ":" StringLit ","
      "grid_base_point" "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}" ","
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

syntax Volume
  = circle:   CircleVolume
  | triangle: TriangleVolume
  ;

// Circle: mandatory pos/depth/radius; front_holds and side_holds are each optional
syntax CircleVolume
  = circleVolume: "circle" "{"
      "pos" ":" XYCoord ","
      "depth" ":" IntegerLit ","
      "radius" ":" IntegerLit
      ("," FrontHoldsList)?
      ("," SideHoldsList)?
    "}"
  ;

syntax FrontHoldsList
  = frontHolds: "front_holds" "[" {Hold ","}* "]"
  ;

syntax SideHoldsList
  = sideHolds: "side_holds" "[" {Hold ","}* "]"
  ;

// Triangle: mandatory pos/extrusion/depth/corners (exactly 3); face hold lists optional
syntax TriangleVolume
  = triangleVolume: "triangle" "{"
      "pos" ":" XYCoord ","
      "extrusion" ":" XYCoord ","
      "depth" ":" IntegerLit ","
      "corners" "[" XYCoord "," XYCoord "," XYCoord "]"
      ("," TriangleFaceHolds)*
    "}"
  ;

// Each triangle face has its own hold list; all three are independently optional
syntax TriangleFaceHolds
  = leftHolds:   "left_holds"   "[" {Hold ","}* "]"
  | rightHolds:  "right_holds"  "[" {Hold ","}* "]"
  | bottomHolds: "bottom_holds" "[" {Hold ","}* "]"
  ;

// ---------- Shared coordinate ----------

// XYCoord is reused for volume pos, extrusion, triangle corners, and hold xy-position
syntax XYCoord
  = xyCoord: "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}"
  ;

// ---------- Holds ----------

syntax Hold
  = hold: "hold" HoldIdLit "{" {HoldProp ","}+ "}"
  ;

// Hold properties are order-independent; required/optional validation is in Check.rsc
syntax HoldProp
  = posXY:        "pos" ":" "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}"
  | posAngle:     "pos" ":" "{" "angle" ":" IntegerLit "}"
  | shapeProp:    "shape" ":" StringLit
  | coloursProp:  "colours" "[" {Colour ","}+ "]"
  | startHold:    "start_hold" ":" IntegerLit
  | endHold:      "end_hold"
  | rotationProp: "rotation" ":" IntegerLit
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
