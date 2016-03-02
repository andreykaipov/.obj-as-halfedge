require "matrix"
load 'Mesh.rb'
load 'parse_obj.rb'

# class HalfEdge
#     attr_accessor :endVertex, :ajdFace, :oppHalfEdge, :nextHalfEdge

#     def initialize endVertex=nil, adjFace=nil, oppHalfEdge=nil, nextHalfEdge=nil
#         @endVertex = endVertex
#         @adjFace = adjFace
#         @oppHalfEdge = oppHalfEdge
#         @nextHalfEdge = nextHalfEdge
#     end

#     def has_good_opposite?
#     end
# end
HalfEdge = Struct.new(:endVertex, :adjFace, :oppHalfEdge, :nextHalfEdge)
HalfEdgeVertex = Struct.new(:x, :y, :z, :outHalfEdge, :index, :curvature)


## A half-edge's endVertex should NOT be equal to its opposite's endVertex.
def check_opposite halfEdge
    return halfEdge.oppHalfEdge == nil ||
            halfEdge.endVertex != halfEdge.oppHalfEdge.endVertex
end

# A half-edge is good if it's opposite is good, or
# if it's adjacent face is not oriented, or if it's opposite face is not oriented???
def check_half_edge halfEdge
    return check_opposite halfEdge || !halfEdge.adjFace.oriented || !halfEdge.oppHalfEdge.adjFace.oriented
end

def check_face face
    b1 = check_half_edge face.adjHalfEdge
    b2 = if face.adjHalfEdge.nextHalfEdge != nil then check_half_edge face.adjHalfEdge.nextHalfEdge else true end
    b3 =
    if face.adjHalfEdge.nextHalfEdge != nil then
        if face.adjHalfEdge.nextHalfEdge.nextHalfEdge != nil then
            check_half_edge face.adjHalfEdge.nextHalfEdge.nextHalfEdge
        else
            true
        end
    else
        true
    end

    return b1 && b2 && b3
end


# The starter for our recursive calls.
# This takes in an already oriented face and calls orient_face on its adjacent faces.
def orient_adj_faces face
    orient_flip_face face.adjHalfEdge
    orient_flip_face face.adjHalfEdge.nextHalfEdge
    orient_flip_face face.adjHalfEdge.nextHalfEdge.nextHalfEdge
end


def orient_face face

    stack = []
    stack.push face.adjHalfEdge
    stack.push face.adjHalfEdge.nextHalfEdge
    stack.push face.adjHalfEdge.nextHalfEdge.nextHalfEdge

    number_of_boundary_edges = 0
    number_of_faces_oriented = 0
    number_of_faces_left_alone = 0

    while not stack.empty?
        poppedHE = stack.pop
        oppFace = poppedHE.oppHalfEdge.adjFace unless poppedHE.oppHalfEdge.nil?

        if poppedHE.oppHalfEdge == nil then
            number_of_boundary_edges += 1
        elsif oppFace.oriented? then
            # puts "you're good scotty!"
        elsif poppedHE.endVertex == poppedHE.oppHalfEdge.endVertex then
            puts "orienting face..."
puts oppFace.adj_vertices.map(&:x)
            v1 = poppedHE.oppHalfEdge.endVertex
            v2 = poppedHE.oppHalfEdge.nextHalfEdge.endVertex
            v3 = poppedHE.oppHalfEdge.nextHalfEdge.nextHalfEdge.endVertex

            if v1 == v2 || v1 == v3 || v2 == v3 then
                raise "Found a degenerate face.\n"\
                      "Face does not have three unique vertices.#{v1} and #{v2} and #{v3}"
            end

            he1 = poppedHE.oppHalfEdge
            he2 = poppedHE.oppHalfEdge.nextHalfEdge
            he3 = poppedHE.oppHalfEdge.nextHalfEdge.nextHalfEdge

            unless he1.endVertex == v1 && he2.endVertex == v2 && he3.endVertex == v3 then
                raise "Lol why would this happen?"
            end

            # Make the edges "point" in the correct direction.
            he1.endVertex = v3
            he2.endVertex = v1
            he3.endVertex = v2

            # Make the edges traversable in the correct direction.
            he1.nextHalfEdge = he3
            he2.nextHalfEdge = he1
            he3.nextHalfEdge = he2

            # Let the vertices know one of their emanating edges.
            v1.outHalfEdge = he1
            v2.outHalfEdge = he2
            v3.outHalfEdge = he3

            # We're done with this face!
            oppFace.oriented = true

            number_of_faces_oriented += 1

            # We don't have to look at the opposite face of he1. That's where we came from!
            stack.push he2
            stack.push he3
        else
            # puts "turns out this face was already oriented"
            number_of_faces_left_alone += 1
            oppFace.oriented = true
            stack.push poppedHE.oppHalfEdge.nextHalfEdge # he2
            stack.push poppedHE.oppHalfEdge.nextHalfEdge.nextHalfEdge # he3
        end

        unless oppFace.adjHalfEdge == oppFace.adjHalfEdge.nextHalfEdge.nextHalfEdge.nextHalfEdge then
            abort "#{oppFace.adjHalfEdge.endVertex.x} and #{oppFace.adjHalfEdge.nextHalfEdge.endVertex.x} and #{oppFace.adjHalfEdge.nextHalfEdge.nextHalfEdge.endVertex.x} Geometry is non manifold"
        end

    end

    puts "Number of boundary edges encountered: #{number_of_boundary_edges}"
    puts "Number of faces oriented: #{number_of_faces_oriented}"
    puts "Number of faces that were already oriented: #{number_of_faces_left_alone}"

end


# Here x can be thought of as the source and y as the target of a half-edge.
# By sorting the pair of vertices and using a hash, we are able to detect
# a half-edge's opposite half-edge.
def get_edge_key x, y
    return [ [x,y].min, [x,y].max ]
end

# Since the half-edge's source and target are sorted, if a half-edge exists
# in the hash, that means we've already added its opposite.
def hash_edge halfEdge, halfEdgeKey, halfEdgesHash

    if (halfEdgesHash.has_key? halfEdgeKey) && (halfEdgesHash.has_key? halfEdgeKey.reverse) then
        abort "Geometry is non-manifold bro.\n"\
              "The edge along the vertices #{halfEdgeKey} touches more than two faces!"
    elsif halfEdgesHash.has_key? halfEdgeKey then
        halfEdge.oppHalfEdge = halfEdgesHash[halfEdgeKey]
        halfEdgesHash[halfEdgeKey].oppHalfEdge = halfEdge

        # Flip key
        halfEdgeKey.reverse!        
    end

    halfEdgesHash[halfEdgeKey] = halfEdge

end

def build_HalfEdge_mesh mesh, halfEdgeVertices, halfEdgeFaces

    halfEdgesHash = Hash.new()

    mesh.vertices.each do |v|
        halfEdgeVertex = HalfEdgeVertex.new(v[0], v[1], v[2])
        halfEdgeVertex.outHalfEdge = nil
        halfEdgeVertices << halfEdgeVertex
    end

    # This is for the first face we will process.
    # Since it's the first face, we will assume for it to be properly oriented,
    # and use this info to recursively orient all of the other faces.
    firstHalfEdgeFace = nil

    mesh.faces.each do |face|
        # Each og face will correspond to a halfEdgeFace.
        halfEdgeFace = HalfEdgeFace.new()
# p face
        # Create our half-edges for this face and store them in an array.
        # Note that the length of `face` is the number of half-edges for this face.
        faceHalfEdges = []
        face.length.times do
            halfEdge = HalfEdge.new()
            halfEdge.adjFace = halfEdgeFace
            faceHalfEdges << halfEdge
        end

        # For each half-edge, connect it to the next one -- like a circle.
        # This gives each face an arbitary orientation. We'll fix it later if necessary.
        # Also set the opposite of each half-edge via hashing.
        # Note: The edge-vertex connection is not
        faceHalfEdges.size.times do |i|
            faceHalfEdges[i].endVertex = halfEdgeVertices[ face[i] ]
            faceHalfEdges[i - 1].nextHalfEdge = faceHalfEdges[i]
            halfEdgeVertices[ face[i - 1] ].outHalfEdge = faceHalfEdges[i]

            if face[i - 1] == face[i] then
                abort "Woah!\nThere is a half-edge whose source and target vertex are the same!\n"\
                      "Offending half-edge occurs in face `f #{face.map{|v| v+1}.join(' ')}`.\n"\
                      "Vertex in question is `v #{halfEdgeVertices[face[i]].x} #{halfEdgeVertices[face[i]].y} #{halfEdgeVertices[face[i]].z}`."
            else
                hash_edge faceHalfEdges[i], (get_edge_key face[i - 1], face[i]), halfEdgesHash
            end
        end

        # Set the face to touch one of its half-edges. Doesn't matter which one.
        halfEdgeFace.adjHalfEdge = faceHalfEdges[0]
        halfEdgeFace.oriented = false

        halfEdgeFaces << halfEdgeFace

        # If we're processing the first face, assume for it be properly oriented
        if firstHalfEdgeFace.nil? then
            firstHalfEdgeFace = halfEdgeFace
            firstHalfEdgeFace.oriented = true
        end

    end

    puts "Number of vertices in the half-edge mesh is #{halfEdgeVertices.size}"
    puts "Number of edges in the half-edge mesh is #{halfEdgesHash.size}"
    puts "Number of faces in the half-edge mesh is #{halfEdgeFaces.size}"

    # puts check_opposite halfEdgeFaces[0].adjHalfEdge
    # puts check_half_edge halfEdgeFaces[0].adjHalfEdge

    puts orient_face firstHalfEdgeFace

    puts "Number of vertices in the half-edge mesh is #{halfEdgeVertices.size}"
    puts "Number of edges in the half-edge mesh is #{halfEdgesHash.size}"
    puts "Number of faces in the half-edge mesh is #{halfEdgeFaces.size}"

end

mesh = parse_obj ARGV[0]
hevs = []
hefs = []

build_HalfEdge_mesh mesh, hevs, hefs


# puts hefs[2].adjHalfEdge.endVertex
# puts hefs[2].adjHalfEdge.oppHalfEdge.endVertex

# puts ""

# puts hefs[2].adjHalfEdge.nextHalfEdge.endVertex
# puts hefs[2].adjHalfEdge.nextHalfEdge.oppHalfEdge.endVertex

# puts ""

# puts hefs[2].adjHalfEdge.nextHalfEdge.nextHalfEdge.endVertex
# puts hefs[2].adjHalfEdge.nextHalfEdge.nextHalfEdge.oppHalfEdge.endVertex

# puts "whatever after this"

# puts hefs[1].adjHalfEdge.endVertex
# puts hefs[1].adjHalfEdge.nextHalfEdge.endVertex
# puts hefs[1].adjHalfEdge.nextHalfEdge.nextHalfEdge.endVertex
# puts hefs[1].adjHalfEdge.nextHalfEdge.nextHalfEdge.nextHalfEdge.endVertex

# puts ""

# puts hefs[2].adjHalfEdge.endVertex
# puts hefs[2].adjHalfEdge.nextHalfEdge.endVertex
# puts hefs[2].adjHalfEdge.nextHalfEdge.nextHalfEdge.endVertex
# puts hefs[2].adjHalfEdge.nextHalfEdge.nextHalfEdge.nextHalfEdge.endVertex

# puts ""

# puts hefs[3].adjHalfEdge.endVertex
# puts hefs[3].adjHalfEdge.nextHalfEdge.endVertex
# puts hefs[3].adjHalfEdge.nextHalfEdge.nextHalfEdge.endVertex
# puts hefs[3].adjHalfEdge.nextHalfEdge.nextHalfEdge.nextHalfEdge.endVertex


# Private methods.

private
