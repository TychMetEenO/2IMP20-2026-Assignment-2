module labour::AST

// A bouldering wall has a id and is composed of volumes and routes
data BoulderingWall(loc src=|unknown:///|)
  = boulderingWall(str id, list[BoulderingRoute] routes, list[Volume] volumes)
  ;

// A bouldering route must have a grade, a base point, a unique id and an array of hold identifiers
data BoulderingRoute(loc src=|unknown:///|)
  = boulderingRoute(str id, str grade, Coord gridBasePoint, list[RouteHoldRef] holds)
  ;

// A step in a route, either a single hold, or a group of hold ids
// where the route splits into parallel sub-routes
data RouteHoldRef(loc src=|unknown:///|)
  = single(str holdId)
  | subRoute(list[str] holdIds)
  ;

// A volume can either be a circle or a triangle
// A circle has a position, radius and a depth. It also optionally has holds
// A triangle has a position, a list of corners, an extrusion point and a depth. It also optionally has holds
data Volume(loc src=|unknown:///|)
  = circle(Coord pos, int depth, int radius,
           list[Hold] frontHolds, list[Hold] sideHolds)
  | triangle(Coord pos, Coord extrusion, int depth, list[Coord] corners,
             list[Hold] leftHolds, list[Hold] rightHolds, list[Hold] bottomHolds)
  ;

// A hold has an id and a list of properties, these are later verified in Check.rsc
data Hold(loc src=|unknown:///|)
  = hold(str id, list[HoldProp] props)
  ;

// All properties a hold can have
data HoldProp(loc src=|unknown:///|)
  = posXY(int x, int y)
  | posAngle(int angle)
  | shape(str shapeId)
  | colours(list[str] names)
  | startHold(int hand)
  | endHold()
  | rotation(int angle)
  ;

// Coordinates are used for volumes, and route grid base points and have an x and y position
data Coord(loc src=|unknown:///|)
  = coord(int x, int y)
  ;
