#
# @author Andrey Kaipov
#
# This class represents a mesh constructed of half-edges, and is initialized from a simple list
# of vertices and a list of faces indexed onthose vertices. Once initialized, we can build it,
# orient it, find its boundaries, and compute some topological and geometrical properties of it.
#

require_relative "HalfEdge"
require_relative "HalfEdgeVertex"
require_relative "HalfEdgeFace"
require_relative "HalfEdgesHash"

class HalfEdgeMesh

    attr_reader :mesh, :hevertices, :hefaces, :hehash, :disconnectedGroups

    # Many attributes here can exist as methods, but I think it's pretty nice to initialize all of them here.
    def initialize mesh
        @mesh = mesh
        @hevertices = []
        @hefaces = []
        @hehash = HalfEdgeHash.new()
    end

    # Builds the simple mesh as a half-edge data structure.
    def build
        build_vertices
        build_faces
    end

    # Transforms our simple vertices into half-edge vertices.
    def build_vertices
        @mesh.vertices.each do |v|
            @hevertices << HalfEdgeVertex.new(v[0], v[1], v[2])
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
                faceHalfEdges[i].endVertex = @hevertices[ face[i] ]
                faceHalfEdges[i - 1].nextHalfEdge = faceHalfEdges[i]
                @hevertices[ face[i - 1] ].outHalfEdge = faceHalfEdges[i]

                key = @hehash.form_edge_key face[i - 1], face[i]
                @hehash.hash_edge key, faceHalfEdges[i]
            end

            @hefaces << halfEdgeFace
        end
    end

    # Iteratively orient all of the faces in our mesh.
    def orient
        unorientedFaces = @hefaces
        @disconnectedGroups = 0

        until unorientedFaces.empty? do
            unorientedFaces[0].oriented = true
            stack = [ unorientedFaces[0] ]
            until stack.empty?
                face = stack.pop
                orientedFaces = face.orient_adj_faces
                orientedFaces.each{ |face| stack.push face }
            end
            unorientedFaces = unorientedFaces.select{ |face| not face.oriented? }
            @disconnectedGroups += 1
        end

        return true
    end

    def all_faces_oriented
        @hefaces.each do |hef|
            if not hef.oriented? then
                return false
            end
        end
        return true;
    end

    def vertices
        if @hevertices.size != @mesh.vertices.size then
            abort "Not every vertex from the obj file was made into a half-edge-vertex."
        else
            return @hevertices.size
        end
    end

    def faces
        if @hefaces.size != @mesh.faces.size then
            abort "Not every face from the obj file was made into a half-edge-face."
        else
            return @hefaces.size
        end
    end

    def edges
        boundaryEdges = []
        nonboundaryHEs = []
        @hehash.values.each do |he|
            if he.is_boundary_edge? then
                boundaryEdges << he
            else
                nonboundaryHEs << he
            end
        end
        return boundaryEdges.size + nonboundaryHEs.size / 2
    end

    def boundary_vertices
        @hevertices.select{ |v| v.is_boundary_vertex? }.size
    end

    def boundary_edges
        @hehash.select{ |_, he| he.is_boundary_edge? }.size
    end

    # DFS on the boundary vertices.
    def boundaries
        boundaryVertices = @hevertices.select{ |v| v.is_boundary_vertex? }
        boundaryComponents = []
        until boundaryVertices.empty? do
            boundaryComponent = []
            discovered = [ boundaryVertices.shift ]
            until discovered.empty? do
                v = discovered.pop
                boundaryComponent << v
                boundaryVertices.each do |bv|
                    if v.adjacent_via_boundary_edge_to? bv then discovered << bv end
                end
                boundaryVertices = boundaryVertices - discovered
            end
            boundaryComponents << boundaryComponent
        end
        return boundaryComponents
    end

    def is_closed?
        boundary_edges == 0
    end

    def curvature
        @hevertices.map(&:compute_curvature).reduce(0, &:+)
    end

    def characteristic
        vertices - edges + faces
    end

    def genus
        1 - (characteristic + boundaries.size) / 2
    end

    def print_info
        if boundary_vertices < boundary_edges then
            abort "The number of boundary vertices is less than the number of boundary edges.\n"\
            "This could mean that you have a non-manifold boundary vertex in your mesh. Picture a bow-tie."
        elsif boundary_vertices > boundary_edges then
            abort "Lol something went really wrong."
        end

        puts "Here is some information about the surface:"
        puts ""
        puts "Number of vertices............. V = #{vertices}"
        puts "Number of edges................ E = #{edges}"
        puts "Number of faces................ F = #{faces}"
        puts ""
        if self.is_closed? then
            puts "Surface is closed. No boundaries!"
        else
            puts "Surface is not closed and has boundaries."
            puts ""
            puts "Number of boundaries........... b = #{boundaries.size}"
            puts "- boundary vertices............ #{boundary_vertices}"
            puts "- boundary edges............... #{boundary_edges}"
        end
        puts ""
        puts "Euler characteristic........... χ = #{characteristic}"
        puts "Genus.......................... g = #{genus}"
        puts "Curvature of surface........... κ = #{curvature}"
        puts "Check Gauss-Bonnet..... |κ - 2πχ| = #{(curvature - 2 * Math::PI * characteristic).abs}"
    end

end
