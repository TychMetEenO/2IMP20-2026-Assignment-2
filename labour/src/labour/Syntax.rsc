module labour::Syntax

layout Whitespace = [\ \t\n\r]* !>> [\ \t\n\r]; // Skips spaces in the entire syntax.

lexical StringLit = "\"" ![\"]* "\""; // Defines basic string type.
lexical HoldIdLit = "\"" [0-9][0-9][0-9][0-9] "\""; // Defines type for hold id: exactly 4 numbers.
lexical IntegerLit = "-"? [0-9]+ !>> [0-9]; // Defines type for numbers, allows for a minus sign and forces the entire string to be matched.

start syntax BoulderingWall
  = boulderingWall: "bouldering_wall" StringLit ":" "{" Routes "," Volumes "}"
  ;

syntax Routes // Holds the list of routes.
  = routes: "routes" "[" {BoulderingRoute ","}* "]"
  ;

syntax BoulderingRoute  // Defines a route.
  = boulderingRoute: "bouldering_route" StringLit ":" "{"
      "grade" ":" StringLit ","
      "grid_base_point" ":" "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}" ","
      "holds" "[" {RouteHoldRef ","}* "]"
    "}"
  ;

syntax RouteHoldRef // contains either a hold or a reference to a subroute consisting of more refs.
  = single:   HoldIdLit
  | subRoute: "{" {HoldIdLit ","}+ "}"
  ;

syntax Volumes // Holds the list of volumes.
  = volumes: "volumes" "[" {Volume ","}* "]"
  ;

syntax Volume // Volumes can be circles or triangles.
  = circle:   CircleVolume
  | triangle: TriangleVolume
  ;

syntax CircleVolume // Defines a circle
  = circleVolume: "circle" ":" "{"
      "pos" ":" XYCoord ","
      "depth" ":" IntegerLit ","
      "radius" ":" IntegerLit
      CircleFaceHolds*
    "}"
  ;

syntax CircleFaceHolds  // Circles can have front and/or side holds.
  = frontHolds: "," "front_holds" "[" {Hold ","}* "]"
  | sideHolds:  "," "side_holds"  "[" {Hold ","}* "]"
  ;

syntax TriangleVolume // Defines a triangle.
  = triangleVolume: "triangle" ":" "{"
      "pos" ":" XYCoord ","
      "extrusion" ":" XYCoord ","
      "depth" ":" IntegerLit ","
      "corners" "[" XYCoord "," XYCoord "," XYCoord "]"
      TriangleFaceHolds*
    "}"
  ;

syntax TriangleFaceHolds  // A triangle can have left, right, and/or bottom holds.
  = leftHolds:   "," "left_holds"   "[" {Hold ","}* "]"
  | rightHolds:  "," "right_holds"  "[" {Hold ","}* "]"
  | bottomHolds: "," "bottom_holds" "[" {Hold ","}* "]"
  ;

syntax XYCoord  // Defines the basic coord format.
  = xyCoord: "{" "x" ":" IntegerLit "," "y" ":" IntegerLit "}"
  ;

syntax Hold // A hold has an id and a set of properties.
  = hold: "hold" HoldIdLit ":" "{" {HoldProp ","}+ "}"
  ;

syntax HoldProp // The set of properties holds can have.
  = posProp:      "pos" ":" HoldPos
  | shapeProp:    "shape" ":" StringLit
  | coloursProp:  "colours" "[" {Colour ","}+ "]"
  | startHold:    "start_hold" ":" IntegerLit
  | endHold:      "end_hold"
  | rotationProp: "rotation" ":" IntegerLit
  ;

syntax HoldPos // A hold has a position and a possible rotation.
  = posXY:    XYCoord
  | posAngle: "{" "angle" ":" IntegerLit "}"
  ;

// All possible color values.
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
