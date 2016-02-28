class Edge
    attr_accessor :leftHalfEdge, :rightHalfEdge

    def initialize(leftHalfEdge, rightHalfEdge)
        @leftHalfEdge = leftHalfEdge
        @rightHalfEdge = rightHalfEdge
    end
end

class HalfEdge
    attr_accessor :endingVertex, :adjFace, :nextHalfEdge, :oppHalfEdge

    def initialize(endingVertex = nil, adjFace = nil, nextHalfEdge = nil, oppHalfEdge = nil)
        @endingVertex = endingVertex;
        @adjFace = adjFace;
        @nextHalfEdge = nextHalfEdge;
        @oppHalfEdge = oppHalfEdge;
    end
end

class Vertex
    attr_accessor :x, :y, :z, :outHalfEdge

    def initialize(x, y, z, outHalfEdge = nil)
        @x = x
        @y = y
        @z = z
        @outHalfEdge = outHalfEdge
    end
end

class Face
    attr_accessor :borderingHalfEdge, :oriented

    def initialize(borderingHalfEdge = nil, oriented = nil)
        @borderingHalfEdge = borderingHalfEdge
    end

    def oriented?
        !!@oriented
    end
end

class Mesh
    attr_accessor :vertices, :faces

    def initialize(vertices, faces)
        @vertices = vertices
        @faces = faces
    end
end