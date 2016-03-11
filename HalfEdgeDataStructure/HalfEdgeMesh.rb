require_relative "HalfEdge"
require_relative "HalfEdgeVertex"
require_relative "HalfEdgeFace"
require_relative "HalfEdgesHash"

class HalfEdgeMesh

    attr_reader :mesh, :hevertices, :hefaces, :hehash,
                :numVertices, :numEdges, :numFaces, :numBoundaryVertices, :numBoundaryEdges,
                :characteristic, :boundaries, :genus, :curvature

    # Many attributes here can exist as methods, but I think it's pretty nice to initialize all of them here.
    def initialize mesh
        @mesh = mesh
        @hevs = []
        @hefs = []
        @hehash = Hash.new()

        self.build
        self.orient

        # After building and orienting, we can get the following info...

        @numBoundaryVertices = @hevs.select{ |v| v.is_boundary_vertex? }.size
        @numBoundaryEdges = @hehash.select { |_, he| he.is_boundary_edge? }.size

        @numVertices = @hevs.size
        @numEdges = @hehash.select { |_, he| !he.is_boundary_edge? }.size / 2 + @numBoundaryEdges
        @numFaces = @hefs.size

        @characteristic = @numVertices - @numEdges + @numFaces
        @boundaries = self.boundary_components.size
        @genus = 1 - (@characteristic + @boundaries) / 2
        @curvature = @hevs.map(&:compute_curvature).reduce(0, &:+)
    end

    # Builds the simple mesh as a half-edge data structure.
    def build
        self.build_vertices
        self.build_faces
    end

    # Transforms our simple vertices into half-edge vertices.
    def build_vertices
        @mesh.vertices.each do |v|
            @hevs << HalfEdgeVertex.new(v[0], v[1], v[2])
        end
    end

    # Transforms our faces into half-edge faces, and create the links between half-edges around each face.
    # The orientation we give each face is arbitrary -- we'll fix it later if necessary.
    def build_faces
        @mesh.faces.each do |face|
            halfEdgeFace = HalfEdgeFace.new()
            halfEdgeFace.oriented = false

            # For each vertex of our face, there is a corresponding half-edge.
            faceHalfEdges = face.map do |_|
                halfEdge = HalfEdge.new()
                halfEdge.adjFace = halfEdgeFace
                halfEdge
            end

            # Set the face to touch one of its half-edges. Doesn't matter which one.
            halfEdgeFace.adjHalfEdge = faceHalfEdges[0]

            # For each half-edge, connect it to the next one, and set the opposite of it via hashing.
            faceHalfEdges.size.times do |i|
                faceHalfEdges[i].endVertex = @hevs[ face[i] ]
                faceHalfEdges[i - 1].nextHalfEdge = faceHalfEdges[i]
                @hevs[ face[i - 1] ].outHalfEdge = faceHalfEdges[i]

                key = @hehash.form_edge_key face[i - 1], face[i]
                @hehash.hash_edge key, faceHalfEdges[i]
            end

            @hefs << halfEdgeFace
        end
    end

    # Here we iteratively orient all of the faces in our mesh. The recursive solution overflows the stack!
    # What we do is suppose the first face is oriented, and then orient its adjacent faces.
    # Then we orient the faces that were just oriented! In this way, the stack always gets smaller!
    def orient
        @hefs[0].oriented = true
        stack = [ @hefs[0] ]
        until stack.empty?
            face = stack.pop
            orientedFaces = face.orient_adj_faces
            orientedFaces.each { |face| stack.push face }
        end
    end

    # The mesh acts as a surface. It's either closed or it has a boundary.
    def is_closed?
        @numBoundaryEdges == 0
    end

    # Clumps together boundary vertices that are in the same boundary component.
    # The strategy here is to just test for adjacency between remaining unchosen
    # boundary vertices, and all of the vertices in a component.
    def boundary_components
        if @numBoundaryVertices < @numBoundaryEdges then
            abort "The number of boundary vertices is less than the number of boundary edges.\n"\
            "This could mean that you have a non-manifold boundary vertex in your mesh. Picture a bow-tie."
        elsif @numBoundaryVertices > @numBoundaryEdges then
            abort "Something went really wrong..."
        end

        boundaryVertices = @hevs.select { |v| v.is_boundary_vertex? }
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

    # Oh yeah.
    def print_info
        puts "Here is some information about the surface:"
        puts ""
        puts "Number of vertices............. V = #{@numVertices}"
        puts "Number of edges................ E = #{@numEdges}"
        puts "Number of faces................ F = #{@numFaces}"
        puts ""
        if self.is_closed? then
            puts "Surface is closed. No boundaries!"
        else
            puts "Surface is not closed and has boundaries."
            puts ""
            puts "Number of boundaries........... b = #{self.boundary_components.size}"
            puts "- boundary vertices............ #{@numBoundaryVertices}"
            puts "- boundary edges............... #{@numBoundaryEdges}"
        end
        puts ""
        puts "Euler characteristic........... χ = #{@characteristic}"
        puts "Genus.......................... g = #{@genus}"
        puts "Curvature of surface........... κ = #{@curvature}"
        puts "Check Gauss-Bonnet..... |κ - 2πχ| = #{(2 * Math::PI * @characteristic - @curvature).abs}"
    end

end

