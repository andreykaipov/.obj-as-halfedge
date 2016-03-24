#
# @author Andrey Kaipov
#
# This class is a subclass of a Hash, meant for hashing half-edges specifically.
# We use to identify half-edges that are opposite to one another.
#

class HalfEdgeHash < Hash

    # Here x can be thought of as the source and y as the target of a half-edge.
    # By sorting the pair of vertices and using a hash, we are able to detect
    # a half-edge's opposite half-edge.
    def form_edge_key x, y
        return [ [x,y].min, [x,y].max ]
    end

    # Since the half-edge's source and target are sorted, if a half-edge exists
    # in the hash, that means we've already added its opposite.
    def hash_edge key, halfEdge

        if (self.has_key? key) && (self.has_key? key.reverse) then
            abort "Geometry is non-manifold bro.\n"\
                  "The edge along the vertices #{key.map{|v| v+1}} touches more than two faces!"
        elsif self.has_key? key then
            halfEdge.oppHalfEdge = self[key]
            self[key].oppHalfEdge = halfEdge

            # Flip key
            key.reverse!
        end

        self[key] = halfEdge

    end

end
