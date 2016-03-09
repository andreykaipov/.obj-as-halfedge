#!/usr/bin/env ruby

require_relative "OBJParser"
require_relative "HalfEdgeDataStructure/HalfEdgeMesh"

if __FILE__ == $PROGRAM_NAME

    mesh = OBJParser.parse ARGV[0]
    heMesh = HalfEdgeMesh.new( mesh )
    heMesh.build
    heMesh.orient

    # puts heMesh.hevs[0].outgoing_half_edges.size
    # puts heMesh.hevs[1].outgoing_half_edges.size
    # puts heMesh.hevs[2].outgoing_half_edges.size

    vertices = heMesh.hevs.size
    # edges = heMesh.hehash.size / 2
    edges = heMesh.hehash.values.select{|e| not e.is_boundary_edge?}.size / 2
    faces = heMesh.hefs.size
    characteristic = heMesh.characteristic
    genus = heMesh.genus
    curvature = heMesh.curvature

    if heMesh.is_closed? then
        puts "\nSurface is closed. No boundary edges found."
        puts "\nHere are the stats of the surface:"
        puts "Number of vertices........... V = #{vertices}"
        puts "Number of edges.............. E = #{edges}"
        puts "Number of faces.............. F = #{faces}"
        puts "Euler characteristic......... χ = #{characteristic}"
        puts "Genus........................ g = #{genus}"
        puts "Curvature of surface......... κ = #{curvature}"
        puts "Check................ |κ - 2πχ| = #{(2 * Math::PI * characteristic - curvature).abs}"
    else
        boundaryEdges = heMesh.boundary_edges.size
        boundaryVertices = heMesh.boundary_vertices.size
        boundaryComponents = heMesh.boundary_components.size
        puts "\nSurface is not closed."
        puts "\nHere are the stats of the surface:\n"
        puts "No. of vertices.............. V = #{vertices}"
        puts "No. of non-boundary edges.... E = #{edges}"
        puts "No. of faces................. F = #{faces}"
        puts "Boundary components.......... b = #{boundaryComponents}"
        puts "Euler characteristic......... χ = #{characteristic}"
        puts "Genus........................ g = #{genus}"
        puts "Curvature of surface......... κ = #{curvature}"
        puts "Check................ |κ - 2πχ| = #{(2 * Math::PI * characteristic - curvature).abs}"

        puts "\nAdditional stats:\n"
        puts "No. of boundary vertices..... #{boundaryVertices}"
        puts "No. of boundary edges........ #{boundaryEdges}"
    end


end