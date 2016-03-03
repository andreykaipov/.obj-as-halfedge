class HalfEdgesHash

    def initialize
        @hash = Hash.new()
    end

    # Here x can be thought of as the source and y as the target of a half-edge.
    # By sorting the pair of vertices and using a hash, we are able to detect
    # a half-edge's opposite half-edge.
    def get_edge_key x, y
        return [ [x,y].min, [x,y].max ]
    end

    # Since the half-edge's source and target are sorted, if a half-edge exists
    # in the hash, that means we've already added its opposite.
    def hash_edge key, halfEdge

        if (@hash.has_key? key) && (@hash.has_key? key.reverse) then
            abort "Geometry is non-manifold bro.\n"\
                  "The edge along the vertices #{key.map{|v| v+1}} touches more than two faces!"
        elsif @hash.has_key? key then
            halfEdge.oppHalfEdge = @hash[key]
            @hash[key].oppHalfEdge = halfEdge

            # Flip key
            key.reverse!
        end

        @hash[key] = halfEdge

    end

    def size
        return @hash.size
    end

end