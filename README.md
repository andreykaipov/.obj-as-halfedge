Introduction
------------
This small project was an open-ended assignment for a Computer Graphics course at FIU. It verifies the discrete Gauss-Bonnet theorem for surfaces described by `.obj` files by parsing them into a half-edge data structure.

This script supports `.obj` files with faces containing an arbitrary amount of sides, and also supports files containing named groups via `o` or `g` tags. Texture and normal indices for vertices are fine as they are ignored.

These [notes](http://courses.cms.caltech.edu/cs171/assignments-2014/hw5/hw5-html/cs171hw5.html#x1-80006) helped a lot.


Usage
-----
From the command-line, just execute `ruby objinfo some-obj-file.obj`. Some cool info will then be printed for the provided `.obj` file. For example,

    $ ruby objinfo objs/sphere-with-one-puncture.obj
    Here is some information about the surface:
    
    Number of vertices............. V = 62
    Number of edges................ E = 180
    Number of faces................ F = 119
    
    Surface is not closed and has boundaries.
    
    Number of boundaries........... b = 1
    - boundary vertices............ 3
    - boundary edges............... 3
    
    Euler characteristic........... χ = 1
    Genus.......................... g = 0
    Curvature of surface........... κ = 6.283185307179571
    Check Gauss-Bonnet..... |κ - 2πχ| = 1.509903313490213e-14

Background
----------
The Gauss-Bonnet theorem is a remarkable statement about surfaces, relating their geometry to their topology. Specifically, it goes something like this (I wish GitHub supported MathJax).

[**Gauss-Bonnet theorem for 2D manifolds.**](https://en.wikipedia.org/wiki/Gauss%E2%80%93Bonnet_theorem#Statement_of_the_theorem)
*The integral of the Gaussian curvature over a surface (with respect to the area), plus the integral over the boundary of that same surface of the geodesic curvature (with respect to the arc length), is equal to 2π times the Euler characteristic of the surface.*

If we now try to discretize a 2D manifold by representing it as a polygonal mesh (i.e. the surface of a polyhedron), then the curvature of the manifold will be concentrated at its vertices. Precisely, the curvature of each vertex would be its angular defect. What we then get is the discrete analog of the Gauss-Bonnet theorem.

[**Descartes' theorem.**](https://en.wikipedia.org/wiki/Angular_defect#Descartes.27_theorem)
*The sum of the curvatures of the vertices of the surface is equal to the 2π times the Euler characteristic of the surface.*

Note that if that surface has a boundary, then the angular defect for boundary vertices would be π less than the angular defect for vertices within the interior of a surface.

Now, `.obj` files do a great job at desribing polygonal meshes. For example, the following lines describe the surface of a tetrahedron in the first octant of the xyz-grid.

    v 0 0 0
    v 1 0 0
    v 0 1 0
    v 0 0 1
    f 3 2 1
    f 1 2 4
    f 2 3 4
    f 4 3 1

We're given a list of vertices, and a list of faces defined on those vertices. The default orientation of each face is counter-clockwise, so that each face of the tetrahedron is only visible to us when we can traverse the defining vertices of each face in a counter-clockwise fashion (from our point-of-view!). Equivalently, by the right-hand-rule, the faces that are visible to us have their normal vectors pointing toward us (i.e. out of the screen).

If we would like to verify the discrete Gauss-Bonnet theorem for polyhedral surfaces, then we have to compute the curvatures of each vertex. Unfortunately, the current description of the mesh isn't too efficient. Luckily, hidden in the above syntax is an efficient data structure waiting to be formed -- the [half-edge data structure](http://www.flipcode.com/archives/The_Half-Edge_Data_Structure.shtml), since the *links* between defining vertices of each face are precisely the half-edges.
