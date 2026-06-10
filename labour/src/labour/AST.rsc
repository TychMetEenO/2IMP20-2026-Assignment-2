module labour::AST

/*
 * Abstract syntax for LaBouR.
 *
 * Design decisions:
 * - The data types correspond almost one-to-one with the grammar in
 *   Syntax.rsc, but are purely structural: keywords and punctuation are
 *   dropped, and lexical nodes are mapped to Rascal primitives
 *   (StringLit/HoldIdLit -> str, IntegerLit -> int, Colour -> str).
 * - Colours become plain str values (rather than an enum-like ADT) because the
 *   grammar already guarantees that only the nine valid colour names can
 *   occur; str makes the set-intersection check in Check.rsc trivial.
 * - The two concrete spellings of a hold position ("pos:" and "pos") and the
 *   wrapper HoldPos non-terminal collapse into the posXY/posAngle
 *   constructors; the notation difference carries no meaning.
 * - The optional face-hold lists of a volume map to plain (possibly empty)
 *   lists, so the checker can treat "absent" and "empty" uniformly. Circle
 *   keeps front/side lists, triangle keeps left/right/bottom lists, mirroring
 *   rules 18 and 20 of the spec.
 * - Hold properties stay a list[HoldProp] (instead of fixed fields) because
 *   the concrete syntax allows them in any order and multiplicity; presence,
 *   duplication and value-range constraints are validated in Check.rsc.
 * - Every node carries a src keyword field (defaulting to |unknown:///|) that
 *   CST2AST fills with the source location of the concrete node, enabling
 *   precise error reporting.
 */

data BoulderingWall(loc src=|unknown:///|)
  = boulderingWall(str id, list[BoulderingRoute] routes, list[Volume] volumes)
  ;

data BoulderingRoute(loc src=|unknown:///|)
  = boulderingRoute(str id, str grade, Coord gridBasePoint, list[RouteHoldRef] holds)
  ;

// A step in a route: either a single hold, or a braced group of hold ids
// where the route splits into parallel sub-routes
data RouteHoldRef(loc src=|unknown:///|)
  = single(str holdId)
  | subRoute(list[str] holdIds)
  ;

data Volume(loc src=|unknown:///|)
  = circle(Coord pos, int depth, int radius,
           list[Hold] frontHolds, list[Hold] sideHolds)
  | triangle(Coord pos, Coord extrusion, int depth, list[Coord] corners,
             list[Hold] leftHolds, list[Hold] rightHolds, list[Hold] bottomHolds)
  ;

data Hold(loc src=|unknown:///|)
  = hold(str id, list[HoldProp] props)
  ;

data HoldProp(loc src=|unknown:///|)
  = posXY(int x, int y)
  | posAngle(int angle)
  | shape(str shapeId)
  | colours(list[str] names)
  | startHold(int hand)
  | endHold()
  | rotation(int angle)
  ;

data Coord(loc src=|unknown:///|)
  = coord(int x, int y)
  ;
