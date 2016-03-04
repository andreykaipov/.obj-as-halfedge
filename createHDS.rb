#!/usr/bin/env ruby

require_relative "OBJParser"
require_relative "HalfEdgeDataStructure/HalfEdgeMesh"

if __FILE__ == $PROGRAM_NAME

    mesh = OBJParser.parse ARGV[0]
    heMesh = HalfEdgeMesh.new( mesh )
    heMesh.build
    heMesh.orient

    if heMesh.is_closed? then
        vertices = heMesh.hevs.size
        edges = heMesh.hehash.size / 2
        faces = heMesh.hefs.size
        characteristic = vertices - edges + faces
        genus = 1 - characteristic / 2
        curvature = heMesh.curvature
        puts "Surface is closed. No boundary edges detected."
        puts "Here are the stats of the surface:"
        puts "Number of vertices..... V = #{vertices}"
        puts "Number of edges........ E = #{edges}"
        puts "Number of faces........ F = #{faces}"
        puts "Euler characteristic... χ = #{characteristic}"
        puts "Genus.................. g = #{genus}"
        puts "Curvature of surface... κ = #{heMesh.curvature}"
        puts "Check.......... |κ - 2πχ| = #{(2 * Math::PI * characteristic - curvature).abs}"
    end

    # puts heMesh.mesh.vertices.size
    # puts heMesh.mesh.faces.size
    # puts "---"
    # puts "Number of vertices #{heMesh.hevs.size}"
    # puts (heMesh.hehash.size + 6)/2
    # puts "Number of non-boundary edges: #{heMesh.hehash.values.select{|e| not e.is_boundary_edge?}.size / 2}"
    # puts "Number of boundary edges: #{heMesh.hehash.values.select{|e| e.is_boundary_edge?}.size}"
    # puts "Number of faces #{heMesh.hefs.size}"

    # don't forget to check for faces when doing the characteristic stuff for surfaces with boundary.
    # X(S) = X(S') - b where S is the surface with boundary and S' is the patched up surface
    # Then once we have X(S), to find g(S), we just use X(S) = 2 - 2g(S).

    # arr = []
    # heMesh.hehash.values.each  do |edge|
    #     if edge.is_boundary_edge? then
    #         # p heMesh.hehash.key( edge )
    #         arr << edge
    #     end
    # end
    # p arr.size
end