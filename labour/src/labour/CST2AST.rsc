module labour::CST2AST

import String;
import ParseTree;

import labour::AST;
import labour::Syntax;

/*
 * Mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs).
 *
 * Design decisions:
 * - One overloaded cst2ast function per language construct, dispatching on
 *   concrete syntax patterns (no implode, as required).
 * - Lexical nodes are mapped to Rascal primitives: StringLit/HoldIdLit -> str
 *   (surrounding quotes stripped), IntegerLit -> int, Colour -> str.
 * - Separated lists (star or plus, {X ","}...) are mapped to list[...] by
 *   comprehension.
 * - The two concrete spellings of a hold position (`pos:` and `pos`, both
 *   used by the assignment's listings) map to the same AST constructors via
 *   the shared pos2ast helper, so the AST is notation-independent.
 * - The face-hold sections of a volume (front/side resp. left/right/bottom)
 *   are collected per face by filtering the star list with a concrete
 *   pattern; repeated sections of the same face are concatenated.
 * - The source location of each concrete node is preserved in the src
 *   keyword field of the corresponding AST node.
 */

// Entry point, as called by Plugin::checkWellformedness
BoulderingWall cst2ast(start[BoulderingWall] wall) = cst2ast(wall.top);

BoulderingWall cst2ast(w:(BoulderingWall)`bouldering_wall <StringLit name> { <Routes rs> , <Volumes vs> }`)
  = boulderingWall(unquote(name), cst2ast(rs), cst2ast(vs), src=w.src);

// ---------- Routes ----------

// Note for all list comprehensions in this module: the enumerated elements
// are deliberately left untyped (`x <- xs` instead of `Type x <- xs`). The
// AST data types share their names with the syntax non-terminals, so a typed
// pattern would resolve to the AST type, never match a parse-tree element,
// and silently produce an empty list.
list[BoulderingRoute] cst2ast((Routes)`routes [ <{BoulderingRoute ","}* rs> ]`)
  = [cst2ast(r) | r <- rs];

BoulderingRoute cst2ast(r:(BoulderingRoute)`bouldering_route <StringLit name> { grade : <StringLit g> , grid_base_point { x : <IntegerLit x> , y : <IntegerLit y> } , holds [ <{RouteHoldRef ","}* hs> ] }`)
  = boulderingRoute(unquote(name), unquote(g), coord(toI(x), toI(y)),
                    [cst2ast(h) | h <- hs], src=r.src);

RouteHoldRef cst2ast(r:(RouteHoldRef)`<HoldIdLit id>`)
  = single(unquote(id), src=r.src);

RouteHoldRef cst2ast(r:(RouteHoldRef)`{ <{HoldIdLit ","}+ ids> }`)
  = subRoute([unquote(i) | i <- ids], src=r.src);

// ---------- Volumes ----------

list[Volume] cst2ast((Volumes)`volumes [ <{Volume ","}* vs> ]`)
  = [cst2ast(v) | v <- vs];

Volume cst2ast((Volume)`<CircleVolume c>`) = cst2ast(c);
Volume cst2ast((Volume)`<TriangleVolume t>`) = cst2ast(t);

Volume cst2ast(c:(CircleVolume)`circle { pos : <XYCoord p> , depth : <IntegerLit d> , radius : <IntegerLit r> <CircleFaceHolds* fs> }`)
  = circle(cst2ast(p), toI(d), toI(r),
      [cst2ast(h) | (CircleFaceHolds)`, front_holds [ <{Hold ","}* hs> ]` <- fs, h <- hs],
      [cst2ast(h) | (CircleFaceHolds)`, side_holds [ <{Hold ","}* hs> ]` <- fs, h <- hs],
      src=c.src);

Volume cst2ast(t:(TriangleVolume)`triangle { pos : <XYCoord p> , extrusion : <XYCoord e> , depth : <IntegerLit d> , corners [ <XYCoord c1> , <XYCoord c2> , <XYCoord c3> ] <TriangleFaceHolds* fs> }`)
  = triangle(cst2ast(p), cst2ast(e), toI(d),
      [cst2ast(c1), cst2ast(c2), cst2ast(c3)],
      [cst2ast(h) | (TriangleFaceHolds)`, left_holds [ <{Hold ","}* hs> ]` <- fs, h <- hs],
      [cst2ast(h) | (TriangleFaceHolds)`, right_holds [ <{Hold ","}* hs> ]` <- fs, h <- hs],
      [cst2ast(h) | (TriangleFaceHolds)`, bottom_holds [ <{Hold ","}* hs> ]` <- fs, h <- hs],
      src=t.src);

// ---------- Shared coordinate ----------

Coord cst2ast(c:(XYCoord)`{ x : <IntegerLit x> , y : <IntegerLit y> }`)
  = coord(toI(x), toI(y), src=c.src);

// ---------- Holds ----------

Hold cst2ast(h:(Hold)`hold <HoldIdLit id> { <{HoldProp ","}+ ps> }`)
  = hold(unquote(id), [cst2ast(p) | p <- ps], src=h.src);

// Both pos spellings map to the same AST constructors (see Syntax.rsc)
HoldProp cst2ast(p:(HoldProp)`pos : <HoldPos hp>`) = pos2ast(hp, p.src);
HoldProp cst2ast(p:(HoldProp)`pos <HoldPos hp>`)   = pos2ast(hp, p.src);

HoldProp cst2ast(p:(HoldProp)`shape : <StringLit s>`)
  = shape(unquote(s), src=p.src);

HoldProp cst2ast(p:(HoldProp)`colours [ <{Colour ","}+ cs> ]`)
  = colours(["<c>" | c <- cs], src=p.src);

HoldProp cst2ast(p:(HoldProp)`start_hold : <IntegerLit n>`)
  = startHold(toI(n), src=p.src);

HoldProp cst2ast(p:(HoldProp)`end_hold`)
  = endHold(src=p.src);

HoldProp cst2ast(p:(HoldProp)`rotation : <IntegerLit r>`)
  = rotation(toI(r), src=p.src);

HoldProp pos2ast((HoldPos)`<XYCoord c>`, loc src)
  = posXY(cc.x, cc.y, src=src) when Coord cc := cst2ast(c);

HoldProp pos2ast((HoldPos)`{ angle : <IntegerLit a> }`, loc src)
  = posAngle(toI(a), src=src);

// ---------- Lexical helpers ----------

// Strip the surrounding double quotes from a StringLit/HoldIdLit
private str unquote(Tree t) {
  str s = "<t>";
  return substring(s, 1, size(s) - 1);
}

private int toI(IntegerLit i) = toInt("<i>");
