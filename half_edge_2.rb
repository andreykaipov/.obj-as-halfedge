require "matrix"
require "pp"
load 'parse_obj.rb'

HalfEdge = Struct.new(:endVertex, :adjFace, :oppHalfEdge, :nextHalfEdge)
HalfEdgeFace = Struct.new(:adjHalfEdge, :oriented)
HalfEdgeVertex = Struct.new(:x, :y, :z, :outHalfEdge, :index, :curvature)

# Here x can be thought of as the source and y as the target of a half-edge.
# By sorting the pair of vertices and using a hash, we are able to detect
# a half-edge's opposite half-edge.
def get_edge_key x, y
    return [ [x,y].min, [x,y].max ]
end

# Since the half-edge's source and target are sorted, if a half-edge exists
# in the hash, that means we've already added its opposite.
def hash_edge halfEdge, halfEdgeKey, halfEdgesHash
    if halfEdgesHash.has_key? halfEdgeKey then
        halfEdge.oppHalfEdge = halfEdgesHash[halfEdgeKey]
        halfEdgesHash[halfEdgeKey].oppHalfEdge = halfEdge
    else
        halfEdgesHash[halfEdgeKey] = halfEdge
    end
end

# A half-edge's endVertex should not be equal to its opposite's endVertex.
def check_opposite halfEdge
    # halfEdge.oppHalfEdge == nil ||
    return halfEdge.endVertex != halfEdge.oppHalfEdge.endVertex
end

# A half-edge is good if it's opposite is good,
# if the key
def check_half_edge halfEdge
    return !halfEdge.adjFace.oriented
end

def orient_face_iterative face

    stack = []
    stack.push face.adjHalfEdge.oppHalfEdge.adjFace
    stack.push face.adjHalfEdge.nextHalfEdge.oppHalfEdge.adjFace
    stack.push face.adjHalfEdge.nextHalfEdge.nextHalfEdge.oppHalfEdge.adjFace

    while not stack.empty?

        poppedFace = stack.pop

        if poppedFace.oriented then
            # you're good scotty
            # puts "abcsss"
        else

            borderingHalfEdge = poppedFace.adjHalfEdge

            halfEdge1 = borderingHalfEdge
            halfEdgeVertex2 = borderingHalfEdge.endVertex

            halfEdge2 = borderingHalfEdge.nextHalfEdge
            halfEdgeVertex3 = borderingHalfEdge.nextHalfEdge.endVertex

            halfEdge3 = borderingHalfEdge.nextHalfEdge.nextHalfEdge
            halfEdgeVertex1 = borderingHalfEdge.nextHalfEdge.nextHalfEdge.endVertex

            if halfEdge1.endVertex == halfEdge1.oppHalfEdge.endVertex then
                puts "WOAH #{halfEdge1.endVertex.x} #{halfEdge1.endVertex.y} #{halfEdge1.endVertex.z}"
                halfEdge1.endVertex = halfEdgeVertex1
                halfEdge1.nextHalfEdge = halfEdge3

            end
            if halfEdge2.endVertex == halfEdge2.oppHalfEdge.endVertex then
                puts "WOAH #{halfEdge2.endVertex.x} #{halfEdge2.endVertex.y} #{halfEdge2.endVertex.z}"
                halfEdge2.endVertex = halfEdgeVertex2
                halfEdge2.nextHalfEdge = halfEdge1

            end
            if halfEdge3.endVertex == halfEdge3.oppHalfEdge.endVertex then
                puts "WOAH #{halfEdge3.endVertex.x} #{halfEdge3.endVertex.y} #{halfEdge3.endVertex.z}"
                halfEdge3.endVertex = halfEdgeVertex3
                halfEdge3.nextHalfEdge = halfEdge2

            end

            poppedFace.oriented = true

            stack.push poppedFace.adjHalfEdge.oppHalfEdge.adjFace
            stack.push poppedFace.adjHalfEdge.nextHalfEdge.oppHalfEdge.adjFace
            stack.push poppedFace.adjHalfEdge.nextHalfEdge.nextHalfEdge.oppHalfEdge.adjFace

        end
    end

end

# The starter for our recursive calls.
# This takes in an already oriented face and calls orient_face on its adjacent faces.
def orient_adj_faces face
    orient_face face.adjHalfEdge.oppHalfEdge.adjFace
    orient_face face.adjHalfEdge.nextHalfEdge.oppHalfEdge.adjFace
    orient_face face.adjHalfEdge.nextHalfEdge.nextHalfEdge.oppHalfEdge.adjFace
end


def build_HalfEdge_mesh mesh, halfEdgeVertices, halfEdgeFaces

    halfEdgesHash = Hash.new()

    # Remember, mesh.vertices is 1-indexed.
    mesh.vertices.each do |v|
        halfEdgeVertex = HalfEdgeVertex.new(v.x, v.y, v.z)
        halfEdgeVertex.outHalfEdge = nil
        halfEdgeVertices << halfEdgeVertex
    end

    # This is for the first face we will process.
    # Since it's the first face, we will assume for it to be properly oriented,
    # and use this info to recursively orient all of the other faces.
    firstHalfEdgeFace = nil

    mesh.faces.each do |f|

        # For each face, there are three half-edges touching it.
        halfEdge1 = HalfEdge.new()
        halfEdge2 = HalfEdge.new()
        halfEdge3 = HalfEdge.new()

        halfEdge1.oppHalfEdge = nil
        halfEdge1.oppHalfEdge = nil
        halfEdge1.oppHalfEdge = nil

        halfEdgeFace = HalfEdgeFace.new()

        # Set the face to touch one of its half-edges.
        halfEdgeFace.adjHalfEdge = halfEdge1
        halfEdgeFace.oriented = false

        # Let the three half-edges touch the face.
        halfEdge1.adjFace = halfEdgeFace
        halfEdge2.adjFace = halfEdgeFace
        halfEdge3.adjFace = halfEdgeFace

        # Arbitarily assign some orientation to our mesh. We'll fix it later if it's not good.
        halfEdge1.nextHalfEdge = halfEdge2
        halfEdge2.nextHalfEdge = halfEdge3
        halfEdge3.nextHalfEdge = halfEdge1

        halfEdge1.endVertex = halfEdgeVertices[f.idv2]
        halfEdge2.endVertex = halfEdgeVertices[f.idv3]
        halfEdge3.endVertex = halfEdgeVertices[f.idv1]

        halfEdgeVertices[f.idv1].outHalfEdge = halfEdge1
        halfEdgeVertices[f.idv2].outHalfEdge = halfEdge2
        halfEdgeVertices[f.idv3].outHalfEdge = halfEdge3

        # Currently the triangulated face orientation looks like
        # ... -> he1 --> f.idv2 --> he2 --> f.idv3 --> he3 --> f.idv1 --> he1 --> ...

        # Sets the opposite's of these half-edges.
        hash_edge halfEdge1, (get_edge_key f.idv1, f.idv2), halfEdgesHash
        hash_edge halfEdge2, (get_edge_key f.idv2, f.idv3), halfEdgesHash
        hash_edge halfEdge3, (get_edge_key f.idv3, f.idv1), halfEdgesHash

        halfEdgeFaces << halfEdgeFace

        # If we process the first face, assume for it be properly oriented
        if firstHalfEdgeFace.nil? then
            firstHalfEdgeFace = halfEdgeFace
            firstHalfEdgeFace.oriented = true
        end

    end

    # puts check_opposite halfEdgeFaces[0].adjHalfEdge
    # puts check_half_edge halfEdgeFaces[0].adjHalfEdge

    orient_face_iterative firstHalfEdgeFace
    # puts halfEdgeFaces[0].adjHalfEdge.endVertex
    # puts halfEdgeFaces[0].adjHalfEdge.oppHalfEdge.endVertex
    # puts halfEdgeFaces[0].adjHalfEdge.nextHalfEdge.nextHalfEdge.endVertex

    # Use the firstHalfEdgeFace to orient all of the other faces.
    # return orient_face firstHalfEdgeFace

    puts "Number of vertices in the half-edge mesh is #{halfEdgeVertices.size - 1}"
    puts "Number of edges in the half-edge mesh is #{halfEdgesHash.size}"
    puts "Number of faces in the half-edge mesh is #{halfEdgeFaces.size}"

end

mesh = parse_obj ARGV[0]
hevs = []

build_HalfEdge_mesh mesh, hevs, []

# Private methods.

private
