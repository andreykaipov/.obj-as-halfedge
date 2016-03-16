#
# @author Andrey Kaipov
#
# This class represents a face in our half-edge mesh.
# It knows whether it's oriented or not, and it knows one bordering half-edge.
# While the operations on faces are very important, they're very easy to initialize!
#

class HalfEdgeFace

    attr_accessor :adjHalfEdge, :oriented

    def initialize adjHalfEdge = nil, oriented = nil
        @adjHalfEdge = adjHalfEdge
        @oriented = oriented
    end

    def oriented?
        !!@oriented
    end

    def number_of_sides
        return self.adj_half_edges.size
    end

    # adj_half_edges[0] corresponds to the adjHalfEdge
    def adj_half_edges
        adj_half_edges = []
        current = self.adjHalfEdge
        loop do
            adj_half_edges << current
            current = current.nextHalfEdge
            break if current == self.adjHalfEdge
        end
        return adj_half_edges
    end


    def adj_vertices
        return self.adj_half_edges.map(&:endVertex)
    end

    # Orients all adjacent faces of a face.
    # Returns the faces that were oriented properly.
    def orient_adj_faces

        orientedFaces = []

        self.adj_half_edges.each do |he|

            if he.is_boundary_edge? then
                # puts "boundary edge"
                # A boundary edge only touches one face. There's no adjFace for this half-edge.
            elsif he.oppFace.oriented? then

                if he.has_bad_opposite? then
                    abort "Mesh is unorientable."
                end

            elsif he.has_bad_opposite? then
                puts "Orienting the face on the vertices:"

                oppAdjHalfEdges = he.oppFace.adj_half_edges
                oppAdjVertices = he.oppFace.adj_vertices

                unless oppAdjVertices.size == oppAdjVertices.uniq.size then
                    abort "no"
                end

                # Reorient the opposite face by reversing the links.
                oppAdjHalfEdges.each_with_index do |oppHE, j|
                    puts "(#{oppHE.endVertex.x}, #{oppHE.endVertex.y}, #{oppHE.endVertex.z})"
                    oppHE.endVertex = oppAdjVertices[j - 1]
                    oppHE.nextHalfEdge = oppAdjHalfEdges[j - 1]

                    oppAdjVertices[j].outHalfEdge = oppHE
                end

                he.oppFace.oriented = true
                orientedFaces << he.oppFace

                # Check that the face loops back around.
                unless he.oppFace.adj_half_edges[0] == he.oppFace.adj_half_edges[-1].nextHalfEdge then
                    abort "bro"
                end
            else
                # In this case, the face has the correct orientation. Just mark it oriented.
                he.oppFace.oriented = true
                orientedFaces << he.oppFace

                # Check that the face loops back around.
                unless he.oppFace.adj_half_edges[0] == he.oppFace.adj_half_edges[-1].nextHalfEdge then
                    abort "bro ???"
                end
            end

        end

        return orientedFaces

    end

end
