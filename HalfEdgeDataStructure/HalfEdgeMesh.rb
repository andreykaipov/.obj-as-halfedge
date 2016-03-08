require_relative "HalfEdge"
require_relative "HalfEdgeVertex"
require_relative "HalfEdgeFace"
require_relative "HalfEdgesHash"

class HalfEdgeMesh

    attr_accessor :mesh, :hevs, :hefs, :hehash

    def initialize mesh
        @mesh = mesh
        @hevs = []
        @hefs = []
        @hehash = Hash.new()

        # Find duplicates with their sizes in (I think) linear time.
        fakeVertices = mesh.vertices.group_by{|v| v}.select{|k,v| v.size > 1}.map{|k,v| [k, v.size]}.to_h
        unless fakeVertices.empty?
            puts "\nYou have several pseudo-unique vertices in this mesh. Say what?\n"\
                 "The following vertices are listed uniquely in your .obj file,\n"\
                 "but have identical coordinates:\n\n"
            fakeVertices.each do |fv, multiplicity|
                puts "(#{fv[0]}, #{fv[1]}, #{fv[2]}) occurs #{multiplicity} times."
            end
            puts "\nThis is fine, but the total curvature of the surface may be a bit off"
            puts "since we'll ignore the angles formed by adjacent edges on these vertices."
        end
        puts fakeVertices.values.reduce(0,:+)
    end

    def build

        mesh.vertices.each do |v|
            halfEdgeVertex = HalfEdgeVertex.new(v[0], v[1], v[2])
            @hevs << halfEdgeVertex
        end

        mesh.faces.each do |face|
            # Each og face will correspond to a halfEdgeFace.
            halfEdgeFace = HalfEdgeFace.new()

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
                faceHalfEdges[i].endVertex = @hevs[ face[i] ]
                faceHalfEdges[i - 1].nextHalfEdge = faceHalfEdges[i]
                @hevs[ face[i - 1] ].outHalfEdge = faceHalfEdges[i]

                if face[i - 1] == face[i] then
                    abort "Woah!\nThere is a half-edge whose source and target vertex are the same!\n"\
                    "Offending half-edge occurs in face `f #{face.map{|v| v+1}.join(' ')}`.\n"\
                    "Vertex in question is `v #{@hevs[face[i]].x} #{@hevs[face[i]].y} #{@hevs[face[i]].z}`."
                else
                    key = @hehash.form_edge_key face[i - 1], face[i]
                    @hehash.hash_edge key, faceHalfEdges[i]
                end
            end

            # Set the face to touch one of its half-edges. Doesn't matter which one.
            halfEdgeFace.adjHalfEdge = faceHalfEdges[0]
            halfEdgeFace.oriented = false

            @hefs << halfEdgeFace

        end

    end

    # Here we iteratively orient all of the faces in our mesh. The recursive solution overflows the stack!
    # What we do is suppose the first face is oriented, and then orient its adjacent faces.
    # Then we orient the faces that were oriented! In this was, the stack always gets smaller!
    def orient
        @hefs[0].oriented = true
        stack = [ @hefs[0] ]
        until stack.empty?
            face = stack.pop
            orientedFaces = face.orient_adj_faces
            orientedFaces.each { |face| stack.push face }
        end
    end

    # The mesh acts as a surface. If the surface is closed, this returns true.
    # Otherwise, the surface is a surface with boundary.
    def is_closed?
        @hehash.values.each do |he|
            if he.is_boundary_edge? then
                return false
            end
        end
        return true
    end

    def curvature
        @hevs.map(&:compute_curvature).reduce(0, &:+)
    end

    def boundary_edges
        @hehash.select { |key, he| he.is_boundary_edge?}
    end

end