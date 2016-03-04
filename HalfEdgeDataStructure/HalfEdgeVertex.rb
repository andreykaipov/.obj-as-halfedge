require "matrix"

class HalfEdgeVertex

    attr_accessor :x, :y, :z, :outHalfEdge, :curvature

    def initialize x, y, z, outHalfEdge = nil, curvature = nil
        @x = x
        @y = y
        @z = z
        @outHalfEdge = outHalfEdge
        @curvature = curvature
    end

    # Returns an array of the neighboring vertices of this vertex
    def neighboring_vertices
        halfedge = self.outHalfEdge.nextHalfEdge
        firstVertex = halfedge.endVertex
        neighbors = []
        loop do
            neighbors << halfedge.endVertex
            halfedge = halfedge.nextHalfEdge.oppHalfEdge.nextHalfEdge
            break if halfedge.endVertex == firstVertex
        end
        return neighbors
    end

    # Finds the vector in 3D-space from self to the argument.
    # The coordinates are specified in the user provided obj file.
    def vectorTo target
        # These are vectors from the origin to our points in space.
        p1 = Vector[ self.x, self.y, self.z ]
        p2 = Vector[ target.x, target.y, target.z ]

        # Now compute the difference.
        p1p2 = p2 - p1

        return p1p2
    end

    # Get the vectors from self to the neighboring vertices.
    # Compute the angles between adjacent vectors.
    # Sum them up, and subtract from 2pi. (Only for non-boundary vertices).
    def compute_curvature
        vectorsTo = self.neighboring_vertices.map{ |vertex| self.vectorTo vertex }
        # vectorsTo.map! { |v| v == Vector[0,0,0] ? Vector[1.0e-20,1.0e-20,1.0e-20] : v }
        angles = vectorsTo.map.with_index(0) { |vec, i| vectorsTo[i - 1].angle_with vectorsTo[i] }
        sumOfAngles = angles.reduce(0, :+)
        curvature = 2 * Math::PI - sumOfAngles

        return curvature
    end

end
