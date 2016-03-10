Introduction
------------
A 3D-surface can be described by a list of vertices in 3D-space, along with a list of faces tha connect the vertices together. `.obj` do exactly this. For example, the following lines define a triangle in 3D-space whose vertices are on the points *(1,0,0)*, *(0,1,0)*, and *(0,0,1)*.

    v 1 0 0
    v 0 1 0
    v 0 0 1
    f 1 2 3

The face of the triangle is then specified by listing the vertices consecutively. In this way, each edge of a face always has a next edge to go to. By default, we assume a counter-clockwise orientation of the triangle, so that the triangle face is only visible to us when (from our point-of-view!) we can traverse the vertices of the triangle in a counter-clockwise fashion. Equivalently, by the right-hand-rule, the face will only be visible to us if and only if the normal vector of the face points towards us (i.e. out of the screen).

For this project, we assume that our `.obj` files contain nothing more than a list of vertices and faces, and that they describe no more than one 3D-surface at a time. It should be noted that faces do not need to always be triangular -- we allow for faces to have an arbitrary amount of sides.

This small project verifies the discrete Gauss-Bonnet theorem for surfaces described by .obj files by parsing them into a halfedge data structure, written in Ruby.

Usage
-----
From the command-line, just execute `./objinfo` followed by a `.obj` file of your choice. Some cool info will then be printed for the provided `.obj` file. For example,

    $ ./objinfo objs/sphere-with-one-puncture.obj
    Surface is not closed.
    Here are the stats of the surface:
    
    Number of vertices........... V = 62
    Number of edges.............. E = 177
    Number of faces.............. F = 119
    Number of boundaries......... b = 1
    Euler characteristic......... χ = 1
    Genus........................ g = 0.5
    Curvature of surface......... κ = 6.283185307179575
    Check................ |κ - 2πχ| = 1.1546319456101628e-14
    
    Additional info:
    No. of boundary vertices..... 3
    No. of boundary edges........ 3
