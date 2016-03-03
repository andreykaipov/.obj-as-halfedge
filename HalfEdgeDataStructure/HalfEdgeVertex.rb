class HalfEdgeVertex

    attr_accessor :x, :y, :z, :outHalfEdge, :curvature

    def initialize x, y, z, outHalfEdge = nil, curvature = nil
        @x = x
        @y = y
        @z = z
        @outHalfEdge = outHalfEdge
        @curvature = curvature
    end
    
end
