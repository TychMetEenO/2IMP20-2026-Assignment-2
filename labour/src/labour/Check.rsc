module labour::Check

import labour::AST;

import IO;
import List;
import Set;
import String;

bool checkBoulderWallConfiguration(BoulderingWall wall) { // Runs all checks.
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

// Collects all objects of a certain type in a list.
list[Hold] allHolds(BoulderingWall wall) = [h | /Hold h := wall.volumes];
list[str] refIds(single(str id)) = [id];
list[str] refIds(subRoute(list[str] ids)) = ids;
list[str] routeHoldIds(BoulderingRoute r) = [*refIds(ref) | ref <- r.holds];
list[Hold] routeHolds(BoulderingWall wall, BoulderingRoute r) {
  defs = (h.id : h | h <- allHolds(wall));
  return [defs[id] | id <- routeHoldIds(r), id in defs];
}
list[int] startHoldValues(Hold h) = [n | startHold(int n) <- h.props];
bool isEndHold(Hold h) = [1 | endHold() <- h.props] != [];
set[str] holdColours(Hold h) = {*ns | colours(list[str] ns) <- h.props};
bool routeHasSplit(BoulderingRoute r) = [1 | subRoute(_) <- r.holds] != [];


bool checkWallHasVolumeAndRoute(BoulderingWall wall) {  // every wall must have at least one volume and route.
  bool ok = true;
  if (size(wall.volumes) == 0) {
    println("Wall \"<wall.id>\": must have at least one volume");
    ok = false;
  }
  if (size(wall.routes) == 0) {
    println("Wall \"<wall.id>\": must have at least one route");
    ok = false;
  }
  return ok;
}

bool validId(str id, str kind) {  // The wall and route ids can take any alphanumeric character string
  if (/^[a-zA-Z0-9 ]+$/ := id) {
    return true;
  }
  println("Invalid <kind> identifier \"<id>\": only alphanumeric characters and spaces are allowed");
  return false;
}

bool checkIdentifiers(BoulderingWall wall) {  // Uniqueness of route ids
  bool ok = validId(wall.id, "wall");
  for (r <- wall.routes) {
    ok = validId(r.id, "route") && ok;
  }
  routeIds = [r.id | r <- wall.routes];
  for (str id <- {i | i <- routeIds, size([1 | j <- routeIds, j == i]) > 1}) {
    println("Route identifier \"<id>\" is used more than once");
    ok = false;
  }
  return ok;
}

bool checkUniqueHoldIds(BoulderingWall wall) {  // Uniqueness of hold ids
  ids = [h.id | h <- allHolds(wall)];
  dups = {id | id <- ids, size([1 | i <- ids, i == id]) > 1};
  for (str id <- dups) {
    println("Hold identifiers must be unique");
  }
  return dups == {};
}

bool checkNumberOfHolds(BoulderingWall wall) {  // Every route must have two or more holds.
  bool ok = true;
  for (r <- wall.routes, size(routeHoldIds(r)) < 2) {
    println("Route \"<r.id>\": must have two or more holds");
    ok = false;
  }
  return ok;
}

bool checkStartingHoldsTotalLimit(BoulderingWall wall) { // Only two start holds at most
  bool ok = true;
  for (r <- wall.routes) {
    vals = [*startHoldValues(h) | h <- routeHolds(wall, r)];
    if (size(vals) > 2) {
      println("More than two start holds");
      ok = false;
    }
  }
  return ok;
}

bool checkUniqueEndHold(BoulderingWall wall) {  // At most two end holds if split otherwise only one
  bool ok = true;
  for (r <- wall.routes) {
    ends = [h | h <- routeHolds(wall, r), isEndHold(h)];
    int limit = routeHasSplit(r) ? 2 : 1;
    if (size(ends) > limit) {
      println("Route \"<r.id>\": has <size(ends)> end holds, at most <limit> allowed");
      ok = false;
    }
  }
  return ok;
}

bool checkSubRouteStructure(BoulderingWall wall) {  // No more than two subroutes and no split after merge.
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
          println("Route \"<r.id>\": a split may have at most two sub-routes");
          ok = false;
        }
      } else {
        inRun = false;
      }
    }
    if (splitRuns > 1) {
      println("Route \"<r.id>\": splits again after a merge, only one split is allowed");
      ok = false;
    }
  }
  return ok;
}

bool checkRouteColours(BoulderingWall wall) { // All holds in a route have the same color
  bool ok = true;
  for (r <- wall.routes) {
    hs = routeHolds(wall, r);
    if (hs != []) {
      set[str] common = holdColours(hs[0]);
      for (h <- hs) {
        common = common & holdColours(h);
      }
      if (common == {}) {
        println("Route \"<r.id>\": the holds do not share a common colour");
        ok = false;
      }
    }
  }
  return ok;
}

bool checkHoldProperties(BoulderingWall wall) { // Defines the mandatory hold properties
  bool ok = true;
  for (h <- allHolds(wall)) {
    int nPos     = size([1 | posXY(_, _) <- h.props]) + size([1 | posAngle(_) <- h.props]);
    int nShape   = size([1 | shape(_) <- h.props]);
    int nColours = size([1 | colours(_) <- h.props]);

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
      println("Hold \"<h.id>\": angle <a> is out of range");
      ok = false;
    }

    // Rule 14: rotations range over 0..359
    for (rotation(int rot) <- h.props, rot < 0 || rot > 359) {
      println("Hold \"<h.id>\": rotation <rot> is out of range");
      ok = false;
    }

    // start_hold "takes either 1 or 2 as an argument" (spec 2.1.1)
    for (startHold(int n) <- h.props, n != 1 && n != 2) {
      println("Hold \"<h.id>\": start_hold only takes 1 or 2 as an argument");
      ok = false;
    }
  }
  return ok;
}
