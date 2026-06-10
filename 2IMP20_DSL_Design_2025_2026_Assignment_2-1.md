2IMP20 - DSL Design

Assignment 2: Developing a Language for
Bouldering Route Specifications

2IMP20 - DSL Design
May 22, 2026

1 Introduction

The goal of this assignment is to design and implement a Domain-Specific Language (DSL) for
specifying bouldering gym routes (see https://en.wikipedia.org/wiki/Bouldering).
This assignment must be implemented using the Rascal language workbench. Make sure to
first follow the instructions in the document on how to install the Rascal language workbench.

Then,

• Get the assignment’s project skeleton from the template repository.
• Open the assignment folder in VS Code, Ctrl/Cmd+K, Ctrl/Cmd+O or File → Open

Folder.

If you are using git repository to manage your project, make sure to:

• Create your own repository in Gitlab, Github, or your preferred repository manager. More

information can be found on this website.
• Change the origin of the project skeleton:

git remote set-url origin <NEW_GIT_URL_HERE>

2 Assignment

This assignment is meant to familiarize you with the basics of defining languages using Rascal.

The assignment aims to build a DSL called LaBouR (Language for Bouldering Routes) for
defining routes for a bouldering gym. You have already done so before but with Ecore. One of
the tasks in this assignment is to develop a concrete syntax for LaBouR, which can then be used
to parse LaBouR programs. In the template repository, you will find a VS Code project with
the skeleton of the assignment. Look at the src folder within VS Code. This folder contains
all the necessary language modules. Each module contains the instructions for the exercises
and hints to guide the development.

LaBouR allows users to define bouldering routes consisting of bouldering holds. Both the
routes and the holds have properties that are described below. Furthermore, LaBouR allows
the definition of “volumes” that represent the depth of the bouldering wall. Figure 1 shows a
bouldering wall composed of coloured holds and polygonal volumes.

We will use LaBouR to demonstrate the various aspects of language design discussed in this
course. As mentioned, we will do this with the Rascal language workbench. Hereafter, we
introduce more details about the LaBouR language.

1

2IMP20 - DSL Design

Figure 1: Example of a bouldering wall [source: walltopia]

2.1 Main Concepts
A bouldering wall has a unique ID, and it is composed of volumes and routes. Volumes define
which holds are available in a wall, and the routes are defined based on these holds.

2.1.1 Holds

A hold can be labelled as a start_hold, which takes either 1 or 2 as an argument, or end_hold.
There can be a maximum of two starting holds and a maximum of one end hold per route. If
there are sub-routes, then each sub-route may have an end hold. If no end hold is defined, the
bouldering route is finished by climbing over the top of the wall (onto a landing area). Each
hold provides information describing:

• a unique hold identifier defined by a four-character string.
• its (x, y) coordinates. These coordinates are in cm and defined with integer values. (more

about this in Section 2.1.2).

• a hold shape identifier defined by a string, e.g., “52”.
• a list of colours (to accommodate not just unicoloured holds, but also multicoloured
ones—in practice, think transparent holds that have small coloured holds or stickers inside
them corresponding to the multiple colours).

• an optional rotation that defines the angle of the hold. The angle can be any integer

between 0 and 359.

An example of a hold described using the LaBouR language is provided in Listing 1.

1 hold "0001" {
2
3
4
5
6
7 }

pos { x: 30, y: 70 },
shape: "107",
colours [ red, green ],
start_hold: 1,
rotation: 30

Listing 1: Example definition of a Hold

2

2IMP20 - DSL Design

2.1.2 Volumes

Volumes define the shape of the wall; there are two different types of volumes:

1. Circle: a cylindrical volume defined by its (x, y) position, radius and depth. The depth
describes how extruded the volume is. Note that this depth can also be negative if the
shape “subtracts” from the wall. Listing 2 provides an example of a circle in LaBouR and
Figure 2 provides a visual description of the different circle properties.
. For holds in a cylindrical volume, their position is defined in relation to the
volume position. For holds in the side_holds, instead of (x, y) coordinates,
the holds are defined by their angle (in degrees) around the cylinder side
surface. For front_holds, the (x, y) coordinates are defined relative to the
centre of the front face of the cylinder.

Figure 2: Circle volume representation

1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19

circle {

pos: { x: 50, y: 200 },
depth: -10,
radius: 50,
front_holds [

hold "0001" {

pos: { x: 15, y: 30 },
shape: "52",
colours [ blue, white ]

}

],
side_holds [

hold "0002" {

pos: { angle: 30 },
shape: "42",
colours [ blue ]

}

]

}

Listing 2: Example definition of a Circle volume

2. Triangle: a triangular volume defined by its (x, y) position, an array of three corners,
an extrusion point and a depth. Listing 3 provides an example of a triangle in LaBouR
and Figure 3 provides a visual description of the different triangle properties.

3

depthradiuspos(x,y)SidefaceFrontfaceholddefinedinsidefront_holdsholddefinedinsideside_holdshold{pos:(x,y)}hold{angle:θ}θ2IMP20 - DSL Design

. For holds in a triangular volume, their position (x, y) coordinates are defined

relative to the centre of the volume.

Figure 3: Triangle volume representation

triangle {

pos: { x: 0, y: 0 },
extrusion: { x: 10, y: 5 }, // Relative to center of triangle
depth: 40,
corners [ // Relative to the center of the triangle (pos)

{ x: 2, y: 0 },
{ x: -2, y: 0 },
{ x: 0, y: 2 }

],
left_holds [ // Other options: right_holds, bottom_holds

hold "0012" {

pos: { x: 108, y: 50 },
shape: "5",
rotation: 98,
colours [ white ],
end_hold

}

]

}

1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19

Listing 3: Example definition of a Triangle volume

2.1.3 Routes

Besides the volumes, the wall can also contain multiple routes. A bouldering route must have
a few properties:

• a grade defined by a string, e.g., “5A”.
• a grid_base_point defined by an (x, y) coordinate. These coordinates are relative to the

left lower corner of the bouldering wall.

• a unique route identifier defined by a string, e.g., “my route”
• an array of hold identifiers that indicate which holds are part of this route and which

sub-routes are present.

4

depthcornersBottomfaceLeftfaceRightfacepos(x,y)extrusion:(xe,ye)xeyeholddefinedinsideleft_holds2IMP20 - DSL Design

Moreover, a route can split at a certain hold into two sub-routes that can later merge or end
up in two different end holds (if not merged). An example of such a route is given in Listing 4.

1
2
3
4
5
6

routes [

bouldering_route "Split route" {

grade: "5A",
grid_base_point { x: 0, y: 0 },
holds ["0001", "0002", {"0003", "0004"}, {"0005", "0006"}, "0007"]

}

Listing 4: Example definition of a single route that splits into two sub-routes

For the route in Listing 4, it is possible to imagine the split as two separate routes:

1. “0001”, “0002”, “0003”, “0005”, “0007”
2. “0001”, “0002”, “0004”, “0006”, “0007”

2.2 Well-formedness of routes
To have a valid LaBouR bouldering route definition, some requirements have to be satisfied.
The following conditions ensure the well-formedness of a LaBouRbouldering route definition.
Note that if a data type is not specified, you may choose something sensible yourself; do not
forget to explain why,

1. Every wall must have at least one volume and one route.
2. Every route must have two or more holds.
3. Every route must have between zero and two hand start holds.
4. Every route must have at most one splitting hold where sub-routes start (i.e. no more than

two sub-routes).

5. Every route must have a grade, a grid_base_point, and an identifier.
6. The grid_base_point must have an x and a y component.
7. Every route has at most two holds indicated as end_hold if it splits into sub-routes, and at

most one end_hold if it does not split.

8. In a route, after a split, there should be no new split if there was a merge before.

1 holds ["0001", "0002", {"0003", "0004"}, "0007",
2
> Merge

> Split

{"0005", "0006"}]
> Split

Listing 5: Example of an invalid route

9. Hold IDs are always defined with four digits, for example, ”0025“.
10. The wall and route IDs can take any alphanumeric character.
11. The holds in a bouldering route must all have the same colour. In multicoloured holds,
the intersection of the colour lists must be non-empty. The order of the colours in a
multicoloured hold is not relevant.

12. Every hold must have a position (defined by x and y, or by and angle), a shape, and

colour.

13. If a hold position is defined by an angle, the angle must be between 0 and 359.
14. Holds may have a rotation property. If a hold has a rotation, its value must be between

0 and 359.

15. The colour values used must be valid. For now, we assume valid colours to be white,

yellow, green, blue, red, purple, pink, black, and orange.

16. There are only two types of volumes: circle and triangle.

5

2IMP20 - DSL Design

17. A circular volume must have a radius, a depth and a position.
18. A circular volume may only contain holds in the front_holds or side_holds lists.
19. A triangular volume must have a position, depth, an extrude point, and a corner

array, with three items that defines the corners of the triangle.

20. A triangular volume may only contain holds in the left_holds, right_holds, or

bottom_holds lists.

. Some of these validations can be embedded in your concrete syntax directly,

others must be validated separately. It is up to you to decide which checks are
easier or better to validate in the concrete syntax or in a separate function.

Listing 6 shows a valid bouldering route definition using the LaBouR language.

bouldering_route "Split route" {

grade: "5A",
grid_base_point { x: 0, y: 0 },
holds ["0001", "0002", {"0003", "0004"}, {"0005", "0006"}, "0007"]

}

circle {

routes [

hold "0001" {

],
volumes [

pos: { x: 50, y: 200 },
depth: -10,
radius: 50,
front_holds [

pos: { x: 2, y: 20 },
shape: "5",
rotation: 98,
colours [ white ],
start_hold: 1

1 bouldering_wall "Example wall" {
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42

pos: { x: 2, y: 20 },
shape: "5",
rotation: 98,
colours [ white ]

},
hold "0003" {

},
hold "0002" {

pos: { x: 15, y: 30 },
shape: "52",
colours [ blue, white ]

],
side_holds [

},
triangle {

hold "0004" {

]

}

}

pos: { x: 30, y: 20 },
shape: "42",
colours [ white, orange, green ]

6

2IMP20 - DSL Design

43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74 }

pos: { x: 0, y: 0 },
extrusion: { x: 10, y: 2 },
depth: 40,
corners [

{ x: 20, y: 0 },
{ x: -20, y: 0 },
{ x: 0, y: 30 }

],
left_holds [

hold "0005" {

pos: { x: 12, y: 25 },
shape: "5",
rotation: 0,
colours [ white ]

},
hold "0006" {

pos: { x: 10, y: 14 },
shape: "53",
rotation: 98,
colours [ white ]

},
hold "0007" {

pos: { x: 15, y: 19 },
shape: "53",
rotation: 0,
colours [ white, red ],
end_hold

}

]

}

]

Listing 6: Complete example of a route definition with the LaBouR language

3 Deliverable

This assignment consists of five parts:

• Define a concrete syntax of LaBouR using Rascal’s grammar formalism (module Syntax.rsc).
• Define a parse function for LaBouR. The name of the function is parseLaBouR(...).
It gets a location (loc) as parameter and it returns the parse tree corresponding to the
concrete LaBouR bouldering route in the file at loc (module Parser.rsc).

• Define an abstract syntax for LaBouR (module AST.rsc).
• Define the function cst2ast(...), which takes a parse tree of a LaBouR bouldering
route as parameter and returns an abstract syntax tree as described in the AST (module
CST2AST.rsc). Obviously, you are not allowed to use Rascal’s built in implode
function—one of the goals of this assignment is to make you understand and
implement the process to go from CST to AST.

• Specify a well-formedness checker for LaBouR. To do this, it is nevessary to define the
function checkBoulderRouteConfiguration(...), which takes the AST of a boul-
dering route as parameter and verifies that all well-formedness checks succeed (module
Check.rsc).

7

2IMP20 - DSL Design

4 Testing

The assignment’s skeleton contains two modules, one called Plugin.rsc and another called
Server.rsc. The Plugin.rsc module registers the LaBouR into VS Code. This means that
VS Code will recognize files with extension .labour, and it will call the LaBouR’s parser. If the
program is syntactically correct, you should observe syntax highlighting on it. If that is not the
case, it is highly probable that the program contains a parse error. To activate such functionality,
you have to open Rascal’s REPL, import the module labour::Plugin, and call the main();
function. Likewise, this module also contains a function called checkWellformedness()
that receives the path of a LaBouR program as a parameter and returns a Boolean value. If the
program is correct, it returns true, and it returns false otherwise.

Now, you can create your first e.g. myfirst.labour file. Open it and enter your first
bouldering route specification using LaBouR. Observe what happens if you write a syntactically
correct and incorrect LaBouR specification respectively.

(cid:242) Rascal can be memory hungry if you keep restarting. It is a lot more stable now,

but if keep encountering random issues, clean your project, restart VS Code and
make sure there are no trailing Rascal processes running.

(cid:242) For more information about Rascal execution, you can check the “Rascal MPL

Language Server” in VS Code’s output tab:

5 Submission

You have to submit a zip file containing:

• Your LaBouR language solution, including all modified files.
• The test programs demonstrating the correct validation of non-trivial LaBouR specifications.
• Test programs containing invalid route descriptions to demonstrate the correctness of the

checker.

It is also important to add comments to the files explaining the modifications/extensions you
have made. You have to submit this zip file as a Canvas group of two students before 23:59 of
Friday, 12th of June via Canvas. The rubric of this assignment can be found below.

8

2IMP20 - DSL Design

5.1 Rubric

Description
Concrete Syntax
Well-thought separation of concrete syntax validation and external validation
Decoupled syntax, easy to modify and extend
Abstract Syntax
Matches the concrete syntax
CST to AST transformation
Clean transformation, one mapping per language construct
Constraints
Route has two or more holds
All route properties are present
Correct number of start and end holds
All required hold properties are present and correct
All route holds have the same colour
All required volume properties are present and correct
Sub-routes constraints are validated.
Other
All constraints are validated with test programs
The test programs validate individual constraints
Reasoning behind language design decisions is present (as comments)

Table 1: Rubric for the first assignment

Grade

1
1

1

2

0.5
0.5
0.5
0.5
0.5
0.5
0.5

0.5
0.5
0.5

9

