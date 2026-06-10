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
 * - The spec's listings are inconsistent about the colon after "pos": Listing 1
 *   writes `pos { x: 30, y: 70 }` while Listings 2/3/6 write `pos: { ... }`.
 *   We accept both spellings (posColon / posPlain); they map onto the same
 *   abstract syntax, since the difference is purely a matter of notation.
 * - The hold lists of a volume (front/side resp. left/right/bottom) are star
 *   lists of "face" rules that carry their own leading comma. This makes every
 *   face list optional, allows the lists in any order, and lets CST2AST bind
 *   all of them with a single star variable instead of awkward optionals.
 *   A repeated face list (e.g. two front_holds sections) is not forbidden by
 *   the spec; CST2AST simply concatenates them.
 * - Valid colours are enumerated in the Colour non-terminal (well-formedness
 *   rule 15), so invalid colour names are caught at parse time.
 * - The corners array of a triangle has exactly three XYCoord items, which
 *   enforces the "three corners" part of rule 19 at parse time.
 * - Line comments (`// ...`) are part of the layout because the spec's own
 *   listings (e.g. Listing 3) contain them.
 * - Minimum cardinalities (>= 1 volume/route, >= 2 route holds), value range
 *   checks (rotation 0-359, angle 0-359, start_hold 1 or 2), uniqueness of
 *   identifiers, and sub-route structure constraints are deferred to Check.rsc
 *   because they require counting, arithmetic or cross-referencing that a
 *   context-free grammar cannot (reasonably) express.
 */

lexical Comment = @category="comment" "//" ![\n\r]*;

lexical WhitespaceOrComment = [\ \t\n\r] | Comment;

layout Whitespace = WhitespaceOrComment* !>> [\ \t\n\r] !>> "//";

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

// Route body has a fixed order (grade, grid_base_point, holds) per all spec
// examples; this also enforces rules 5 and 6 (all properties present, and the
// grid_base_point having an x and a y component) at parse time.
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

// Only two volume kinds exist (rule 16), enforced at parse time
syntax Volume
  = circle:   CircleVolume
  | triangle: TriangleVolume
  ;

// Circle: mandatory pos/depth/radius (rule 17, parse time)
syntax CircleVolume
  = circleVolume: "circle" "{"
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
  = triangleVolume: "triangle" "{"
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
  = hold: "hold" HoldIdLit "{" {HoldProp ","}+ "}"
  ;

// Hold properties are order-independent; required/optional/duplicate
// validation is in Check.rsc. The position property exists in two concrete
// spellings ("pos:" and "pos", see module comment) that mean the same thing.
syntax HoldProp
  = posColon:     "pos" ":" HoldPos
  | posPlain:     "pos" HoldPos
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
