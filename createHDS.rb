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

    if heMesh.is_closed? then
        vertices = heMesh.hevs.size
        edges = heMesh.hehash.size / 2
        faces = heMesh.hefs.size
        characteristic = vertices - edges + faces
        genus = 1 - characteristic / 2
        curvature = heMesh.curvature
        puts "\nSurface is closed. No boundary edges found."
        puts "Here are the stats of the surface:\n"
        puts "Number of vertices..... V = #{vertices}"
        puts "Number of edges........ E = #{edges}"
        puts "Number of faces........ F = #{faces}"
        puts "Euler characteristic... χ = #{characteristic}"
        puts "Genus.................. g = #{genus}"
        puts "Curvature of surface... κ = #{heMesh.curvature}"
        puts "Check.......... |κ - 2πχ| = #{(2 * Math::PI * characteristic - curvature).abs}"

        puts heMesh.hevs[1303].adjacent_to? heMesh.hevs[168]
    else
        heMesh.hevs.each do |v|
            if v.outHalfEdge.nil? then puts "#{v.x} #{v.y} #{v.z}" end
        end
        puts "Number of boundary edges: #{heMesh.boundary_edges.size}"
        # heMesh.boundary_edges.values.map(&:endVertex).each do |v|
        #     puts "#{v.x}, #{v.y}, #{v.z}"
        # end
        boundaryVertices = heMesh.hevs.select{ |v| v.is_boundary_vertex? }
        # boundaryVertices = heMesh.hevs.select{ |v| v.is_boundary_vertex? }
        puts "Number of boundary vertices... #{boundaryVertices.size}"
        boundaryVertices.each do |v|
            puts "#{v.x}, #{v.y}, #{v.z}"
        end

        # boundaryVertices[0].outgoing_half_edges

        # boundaryComponents = []
        # index = 0
        # until boundaryVertices.empty? do
        #     boundaryComponents << boundaryVertices.select{|bv| bv.adjacent_to? boundaryVertices.first}
        #     boundaryVertices = boundaryVertices - boundaryComponents.flatten
        #     puts boundaryVertices.size
        # end
        puts "Number of boundary components is: #{heMesh.boundary_components.size}\n"


        puts "Curvature of surface with boundary is #{heMesh.curvature}\n"
    end
    #

    puts heMesh.mesh.vertices.size
    puts heMesh.mesh.faces.size
    puts "---"
    puts "Number of vertices #{heMesh.hevs.size}"
    puts (heMesh.hehash.size)/2

    puts "Number of faces #{heMesh.hefs.size}"

    puts "Number of non-boundary edges: #{heMesh.hehash.values.select{|e| not e.is_boundary_edge?}.size / 2}"
    #
    #
    # puts heMesh.boundary_edges.values[0]
    # puts heMesh.boundary_edges.values[1]
    # puts heMesh.boundary_edges.values[2]
    # puts heMesh.boundary_edges.values[3]
    # puts heMesh.boundary_edges.values[4]
    # puts heMesh.boundary_edges.values[5]
    # puts ""
    # # puts heMesh.hehash.key(heMesh.boundary_edges.values[0].nextHalfEdge)
    # puts heMesh.boundary_edges.values[1].nextHalfEdge
    # puts heMesh.boundary_edges.values[2].nextHalfEdge
    # puts heMesh.boundary_edges.values[3].nextHalfEdge
    # puts heMesh.boundary_edges.values[4].nextHalfEdge
    # puts heMesh.boundary_edges.values[5].nextHalfEdge

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