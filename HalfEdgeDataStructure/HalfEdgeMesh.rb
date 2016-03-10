require_relative "HalfEdge"
require_relative "HalfEdgeVertex"
require_relative "HalfEdgeFace"
require_relative "HalfEdgesHash"

class HalfEdgeMesh

    attr_reader :mesh, :hevs, :hefs, :hehash
    attr_reader :numVertices, :numEdges, :numFaces, :chi, :genus, :curvature

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
    end

    def build
        self.build_vertices
        self.build_faces
    end

    def build_vertices
        mesh.vertices.each do |v|
            halfEdgeVertex = HalfEdgeVertex.new(v[0], v[1], v[2])
            @hevs << halfEdgeVertex
        end
    end

    def build_faces
        mesh.faces.each do |face|
            # Each og face will correspond to a halfEdgeFace.
            halfEdgeFace = HalfEdgeFace.new()
            halfEdgeFace.oriented = false
            # Create our half-edges for this face and store them in an array.
            # Note that the length of `face` is the number of half-edges for this face.
            faceHalfEdges = []
            face.length.times do
                halfEdge = HalfEdge.new()
                halfEdge.adjFace = halfEdgeFace
                faceHalfEdges << halfEdge
            end
            # Set the face to touch one of its half-edges. Doesn't matter which one.
            halfEdgeFace.adjHalfEdge = faceHalfEdges[0]

            # For each half-edge, connect it to the next one -- like a circle you know.
            # This gives each face an arbitary orientation. We'll fix it later if necessary.
            # Also set the opposite of each half-edge via hashing.
            # Note: The edge-vertex connection is not -- NOT WHAT? I FORGOT TO FINISH THIS COMMENT
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

            @hefs << halfEdgeFace
        end
    end

    # Here we iteratively orient all of the faces in our mesh. The recursive solution overflows the stack!
    # What we do is suppose the first face is oriented, and then orient its adjacent faces.
    # Then we orient the faces that were oriented! In this way, the stack always gets smaller!
    def orient
        @hefs[0].oriented = true
        stack = [ @hefs[0] ]
        until stack.empty?
            face = stack.pop
            orientedFaces = face.orient_adj_faces
            orientedFaces.each { |face| stack.push face }
        end
    end

    def curvature
        @hevs.map(&:compute_curvature).reduce(0, &:+)
    end

    def boundary_edges
        @hehash.select { |key, he| he.is_boundary_edge? }
    end

    def boundary_vertices
        @hevs.select{ |v| v.is_boundary_vertex? }
    end

    # The mesh acts as a surface. It's either closed or it has a boundary.
    def is_closed?
        return self.boundary_edges.size == 0
    end

    # Finds the number of boundary components. Considers bow-ties as one component.
    # The strategy here is to find adjacent boundary vertices by testing against the most
    # recently found adjacent vertex. Doing so advances our search in a boundary component.
    def boundary_components
        boundaryVertices = @hevs.select{ |v| v.is_boundary_vertex? }
        boundaryComponents = []
        until boundaryVertices.empty? do
            component = [ boundaryVertices.first ]
            (boundaryVertices - component).each do |bv|
                component << bv if component.any?{ |v| bv.adjacent_to? v }
            end
            boundaryVertices = boundaryVertices - component
            boundaryComponents << component
        end
        return boundaryComponents
    end

    # don't forget to check for faces when doing the characteristic stuff for surfaces with boundary.
    # X(S) = X(S') - b where S is the surface with boundary and S' is the patched up surface
    # Then once we have X(S), to find g(S), we just use X(S) = 2 - 2g(S).
    def characteristic
        edges = @hehash.values.select{|e| not e.is_boundary_edge?}.size / 2
        boundaryEdges = self.boundary_edges.size
        b = self.boundary_components.size
        χ = @hevs.size - (edges + boundaryEdges) + @hefs.size
        return χ
    end

    def genus
        return 1 - self.characteristic / 2.0
    end

    def print_stats
        @numVertices = @hevs.size
        @numEdges = @hehash.select{|key, edge| not edge.is_boundary_edge?}.size / 2
        @numFaces = @hefs.size
        @chi = self.characteristic
        @genus = self.genus
        @curvature = self.curvature
        if self.is_closed? then
            self.print_stats_for_closed
        else
            self.print_stats_for_boundary
        end
    end

    def print_stats_for_closed
        puts "Surface is closed. No boundary edges found."
        puts ""
        puts "Here are the stats of the surface:"
        puts "Number of vertices........... V = #{@numVertices}"
        puts "Number of edges.............. E = #{@numEdges}"
        puts "Number of faces.............. F = #{@numFaces}"
        puts "Euler characteristic......... χ = #{@chi}"
        puts "Genus........................ g = #{@genus}"
        puts "Curvature of surface......... κ = #{@curvature}"
        puts "Check................ |κ - 2πχ| = #{(2 * Math::PI * @chi - @curvature).abs}"
    end

    def print_stats_for_boundary
        puts "Surface is not closed."
        puts "Here are the stats of the surface:"
        puts ""
        puts "Here are the stats of the surface:"
        puts "Number of vertices........... V = #{@numVertices}"
        puts "Number of edges.............. E = #{@numEdges}"
        puts "Number of faces.............. F = #{@numFaces}"
        puts "Number of boundaries......... b = #{self.boundary_components.size}"
        puts "Euler characteristic......... χ = #{@chi}"
        puts "Genus........................ g = #{@genus}"
        puts "Curvature of surface......... κ = #{@curvature}"
        puts "Check................ |κ - 2πχ| = #{(2 * Math::PI * @chi - @curvature).abs}"
        puts ""
        puts "Additional stats:"
        puts "No. of boundary vertices..... #{self.boundary_vertices.size}"
        puts "No. of boundary edges........ #{self.boundary_edges.size}"
    end

end