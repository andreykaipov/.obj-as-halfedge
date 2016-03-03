#!/usr/bin/env ruby

require_relative "OBJParser"
require_relative "HalfEdgeDataStructure/HalfEdgeMesh"

if __FILE__ == $PROGRAM_NAME

    mesh = OBJParser.parse ARGV[0]
    heMesh = HalfEdgeMesh.new( mesh )
    heMesh.build
    heMesh.orient

    puts heMesh.mesh.vertices.size
    puts heMesh.mesh.faces.size

    puts heMesh.hevs.size
    puts heMesh.hefs.size

end