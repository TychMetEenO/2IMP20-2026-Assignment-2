module labour::Check

import labour::AST;

import IO;
import List;
import Set;
import String;

/*
 * Well-formedness checker for LaBouR, operating on the AST.
 *
 * Division of labour between the grammar (Syntax.rsc) and this module:
 *
 * Rules already enforced at parse time, hence NOT re-checked here:
 *  - rules 5/6: a route always has a grade, grid_base_point (with x and y)
 *    and identifier — the route body has a fixed, mandatory structure
 *  - rule 9:  hold ids are exactly four digits (HoldIdLit lexical)
 *  - rule 15: only the nine valid colour names parse (Colour non-terminal)
 *  - rule 16: only circle/triangle volumes exist
 *  - rules 17/19: mandatory circle/triangle properties, exactly 3 corners
 *  - rules 18/20: circles only have front/side hold lists, triangles only
 *    left/right/bottom hold lists
 *
 * Rules checked here: 1, 2, 3, 4, 7, 8, 10, 11, 12, 13, 14. In addition we
 * check things the spec states in prose (sections 2.1.1/2.1.3):
 *  - a start_hold takes 1 or 2 as its argument
 *  - hold identifiers are unique, route identifiers are unique
 *
 * Deliberately NOT checked: that the position kind (xy vs angle) matches the
 * hold list a hold appears in. Section 2.1.2 suggests side_holds use an
 * angle, but the spec's own valid example (Listing 6) puts an (x, y) hold in
 * side_holds; we therefore read rule 12 as "either position kind is fine".
 *
 * Every check prints a message per violation, so a `false` outcome is
 * actionable for the user.
 */

bool checkBoulderWallConfiguration(BoulderingWall wall) {
  // Evaluate all checks first (collecting all error messages), then combine
  results = [
    checkWallHasVolumeAndRoute(wall),
    checkIdentifiers(wall),
    checkUniqueHoldIds(wall),
    checkNumberOfHolds(wall),
    checkStartingHoldsTotalLimit(wall),
    checkUniqueEndHold(wall),
    checkSubRouteStructure(wall),
    checkRouteColours(wall),
    checkHoldProperties(wall)
  ];
  return all(bool b <- results, b);
}

// The assignment text names the checker checkBoulderRouteConfiguration, while
// the skeleton (and Plugin.rsc) use checkBoulderWallConfiguration; we provide
// both names for the same check.
bool checkBoulderRouteConfiguration(BoulderingWall wall)
  = checkBoulderWallConfiguration(wall);

// ---------- Helpers ----------

// All holds defined anywhere in the wall's volumes (deep match)
list[Hold] allHolds(BoulderingWall wall) = [h | /Hold h := wall.volumes];

// The hold ids a single route step refers to
list[str] refIds(single(str id)) = [id];
list[str] refIds(subRoute(list[str] ids)) = ids;

// All hold ids referenced by a route, in climbing order
list[str] routeHoldIds(BoulderingRoute r) = [*refIds(ref) | ref <- r.holds];

// The hold definitions a route references; ids without a matching hold
// definition are skipped
list[Hold] routeHolds(BoulderingWall wall, BoulderingRoute r) {
  defs = (h.id : h | h <- allHolds(wall));
  return [defs[id] | id <- routeHoldIds(r), id in defs];
}

list[int] startHoldValues(Hold h) = [n | startHold(int n) <- h.props];
bool isEndHold(Hold h) = [1 | endHold() <- h.props] != [];
set[str] holdColours(Hold h) = {*ns | colours(list[str] ns) <- h.props};
bool routeHasSplit(BoulderingRoute r) = [1 | subRoute(_) <- r.holds] != [];

// ---------- Rule 1: at least one volume and one route ----------

bool checkWallHasVolumeAndRoute(BoulderingWall wall) {
  bool ok = true;
  if (size(wall.volumes) == 0) {
    println("Wall \"<wall.id>\": must have at least one volume (rule 1)");
    ok = false;
  }
  if (size(wall.routes) == 0) {
    println("Wall \"<wall.id>\": must have at least one route (rule 1)");
    ok = false;
  }
  return ok;
}

// ---------- Rule 10 (+ uniqueness) ----------

// The spec restricts wall/route ids to "any alphanumeric character", but its
// own examples ("Example wall", "my route") contain spaces, so spaces are
// accepted as well.
bool validId(str id, str kind) {
  if (/^[a-zA-Z0-9 ]+$/ := id) {
    return true;
  }
  println("Invalid <kind> identifier \"<id>\": only alphanumeric characters and spaces are allowed (rule 10)");
  return false;
}

bool checkIdentifiers(BoulderingWall wall) {
  bool ok = validId(wall.id, "wall");
  for (r <- wall.routes) {
    ok = validId(r.id, "route") && ok;
  }
  routeIds = [r.id | r <- wall.routes];
  for (str id <- {i | i <- routeIds, size([1 | j <- routeIds, j == i]) > 1}) {
    println("Route identifier \"<id>\" is used more than once; route identifiers must be unique");
    ok = false;
  }
  return ok;
}

// ---------- Hold ids must be unique (spec 2.1.1) ----------

bool checkUniqueHoldIds(BoulderingWall wall) {
  ids = [h.id | h <- allHolds(wall)];
  dups = {id | id <- ids, size([1 | i <- ids, i == id]) > 1};
  for (str id <- dups) {
    println("Hold \"<id>\" is defined more than once; hold identifiers must be unique");
  }
  return dups == {};
}

// ---------- Rule 2: every route has two or more holds ----------

bool checkNumberOfHolds(BoulderingWall wall) {
  bool ok = true;
  for (r <- wall.routes, size(routeHoldIds(r)) < 2) {
    println("Route \"<r.id>\": must have two or more holds (rule 2)");
    ok = false;
  }
  return ok;
}

// ---------- Rule 3: between zero and two hand start holds ----------

bool checkStartingHoldsTotalLimit(BoulderingWall wall) {
  bool ok = true;
  for (r <- wall.routes) {
    vals = [*startHoldValues(h) | h <- routeHolds(wall, r)];
    if (size(vals) > 2) {
      println("Route \"<r.id>\": has <size(vals)> start holds, at most two are allowed (rule 3)");
      ok = false;
    }
  }
  return ok;
}

// ---------- Rule 7: at most one end hold (two if the route splits) ----------

bool checkUniqueEndHold(BoulderingWall wall) {
  bool ok = true;
  for (r <- wall.routes) {
    ends = [h | h <- routeHolds(wall, r), isEndHold(h)];
    int limit = routeHasSplit(r) ? 2 : 1;
    if (size(ends) > limit) {
      println("Route \"<r.id>\": has <size(ends)> end holds, at most <limit> allowed here (rule 7)");
      ok = false;
    }
  }
  return ok;
}

// ---------- Rules 4 and 8: sub-route structure ----------

// A braced group {a, b} is a step where two parallel sub-routes are climbing;
// consecutive braced groups continue the same two sub-routes and a return to
// single ids is a merge. So: each braced group may contain at most two ids
// (no more than two sub-routes, rule 4), and the whole route may contain at
// most one consecutive run of braced groups (no new split after a merge,
// rules 4 and 8; cf. the invalid example in Listing 5).
bool checkSubRouteStructure(BoulderingWall wall) {
  bool ok = true;
  for (r <- wall.routes) {
    int splitRuns = 0;
    bool inRun = false;
    for (ref <- r.holds) {
      if (subRoute(list[str] ids) := ref) {
        if (!inRun) {
          splitRuns += 1;
          inRun = true;
        }
        if (size(ids) > 2) {
          println("Route \"<r.id>\": a split may have at most two sub-routes, found a group of <size(ids)> (rule 4)");
          ok = false;
        }
      } else {
        inRun = false;
      }
    }
    if (splitRuns > 1) {
      println("Route \"<r.id>\": splits again after a merge; only one split is allowed (rules 4 and 8)");
      ok = false;
    }
  }
  return ok;
}

// ---------- Rule 11: all route holds share a colour ----------

bool checkRouteColours(BoulderingWall wall) {
  bool ok = true;
  for (r <- wall.routes) {
    hs = routeHolds(wall, r);
    if (hs != []) {
      set[str] common = holdColours(hs[0]);
      for (h <- hs) {
        common = common & holdColours(h);
      }
      if (common == {}) {
        println("Route \"<r.id>\": the holds do not share a common colour (rule 11)");
        ok = false;
      }
    }
  }
  return ok;
}

// ---------- Rules 12, 13, 14 (+ start_hold value) ----------

bool checkHoldProperties(BoulderingWall wall) {
  bool ok = true;
  for (h <- allHolds(wall)) {
    int nPos     = size([1 | posXY(_, _) <- h.props]) + size([1 | posAngle(_) <- h.props]);
    int nShape   = size([1 | shape(_) <- h.props]);
    int nColours = size([1 | colours(_) <- h.props]);

    // Rule 12: position, shape and colours are mandatory
    if (nPos == 0) {
      println("Hold \"<h.id>\": missing position (rule 12)");
      ok = false;
    }
    if (nShape == 0) {
      println("Hold \"<h.id>\": missing shape (rule 12)");
      ok = false;
    }
    if (nColours == 0) {
      println("Hold \"<h.id>\": missing colours (rule 12)");
      ok = false;
    }

    // Rule 13: angle positions range over 0..359
    for (posAngle(int a) <- h.props, a < 0 || a > 359) {
      println("Hold \"<h.id>\": angle <a> is out of range, must be between 0 and 359 (rule 13)");
      ok = false;
    }

    // Rule 14: rotations range over 0..359
    for (rotation(int rot) <- h.props, rot < 0 || rot > 359) {
      println("Hold \"<h.id>\": rotation <rot> is out of range, must be between 0 and 359 (rule 14)");
      ok = false;
    }

    // start_hold "takes either 1 or 2 as an argument" (spec 2.1.1)
    for (startHold(int n) <- h.props, n != 1 && n != 2) {
      println("Hold \"<h.id>\": start_hold takes 1 or 2 as an argument, found <n>");
      ok = false;
    }
  }
  return ok;
}
