#
# @author Andrey Kaipov
#
# This class represents a half-edge.
# This is the fundamental piece of a half-edge mesh as it links together faces and vertices.
# Any kind of traversal around the mesh we do heavily involves these guys.
#

class HalfEdge

    attr_accessor :endVertex, :adjFace, :oppHalfEdge, :nextHalfEdge

    def initialize endVertex = nil, adjFace = nil, oppHalfEdge = nil, nextHalfEdge = nil
        @endVertex = endVertex
        @adjFace = adjFace
        @oppHalfEdge = oppHalfEdge
        @nextHalfEdge = nextHalfEdge
    end

    # If this edge has no opposite half-edge, it is a boundary.
    def is_boundary_edge?
        self.oppHalfEdge.nil?
    end

    # A half-edge's opposite half-edge's vertex should be different than its own vertex.
    # For use in orienting the faces.
    def has_good_opposite?
        self.endVertex != self.oppHalfEdge.endVertex
    end

    def has_bad_opposite?
        not self.has_good_opposite?
    end

    # Gets the face adjacent to this half-edges opposite half-edge.
    def oppFace
        self.oppHalfEdge.adjFace
    end

end
