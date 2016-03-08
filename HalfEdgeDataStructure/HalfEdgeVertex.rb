require "matrix"

class HalfEdgeVertex

    attr_accessor :x, :y, :z, :outHalfEdge, :curvature, :boundaryVertex

    def initialize x, y, z, outHalfEdge = nil
        @x = x
        @y = y
        @z = z
        @outHalfEdge = outHalfEdge
    end

    def is_boundary_vertex?
        if self.outHalfEdge.nil? then
            abort "Woah. This program failed identifying whether or not the vertex "\
                  "(#{self.x}, #{self.y}, #{self.z}) was a boundary vertex or not."\
                  "The reason we failed is because this vertex has no outgoing halfedge."\
                  "This means that while creating the half-edge mesh, we never came"\
                  "across the aforementioned vertex in a face. That is, this vertex was"\
                  "used in a face. It's just sitting in your .obj file collecting dust."
        else
            halfedge = self.outHalfEdge
        end
        loop do
            if halfedge.is_boundary_edge? then return true
            else halfedge = halfedge.oppHalfEdge.nextHalfEdge end
            if halfedge == self.outHalfEdge then break end
            # until halfedge.endVertex == self do halfedge = halfedge.nextHalfEdge end
            # if halfedge.is_boundary_edge? then return true
            # else halfedge = halfedge.oppHalfEdge end
        end
        return false
    end

    # We split this case up for boundary and non-boundary vertices.
    # Can we just have one method for both? ... I can't think of one!
    def adjacent_to? target
        if self.is_boundary_vertex? then
            return self.__boundary__adjacent_to? target
        else
            return self.__nonboundary__adjacent_to? target
        end
    end

    # KEEP THIS HERE FOR ONE COMMIT FOR MEMORY :-)
    # In this case, since we don't know the outgoing halfedge, we will traverse
    # the halfedges in one direction, and if we hit a boundary halfedge, then
    # we will traverse them in the other direction. If this other direction also
    # hits a boundary halfedge, then the target vertex is not adjacent to self!
    def __boundary__adjacent_to? target
        # A vertex is trivially adjacent to itself.
        if self == target then return true end

        # "From one direction"
        halfedgeA = self.outHalfEdge
        loop do
            # This until-loop is a workaround to not having previous pointers.
            until halfedgeA.endVertex == self do
                prev = halfedgeA.dup
                halfedgeA = halfedgeA.nextHalfEdge
            end
            return true if prev.endVertex == target
            break if halfedgeA.is_boundary_edge?
            halfedgeA = halfedgeA.oppHalfEdge
        end
        # "From the other direction"
        halfedgeB = self.outHalfEdge
        loop do
            return true if halfedgeB.endVertex == target
            break if halfedgeB.is_boundary_edge?
            halfedgeB = halfedgeB.oppHalfEdge.nextHalfEdge
        end

        return false

        # if self == target then
        #     return true
        # else
        #     self.__boundary__neighboring_vertices.member? target
        # end
    end
    # Here we use the __boundary__adjacent_to? strategy, except we go in
    # the "other direction" first to find a bordering halfedge. Then just go
    # in the typical direction and collect all of the vertices. We do this
    # because the vertices need to be in order. Further, we HAVE TO go in the
    # "other direction" first - it won't work otherwise.
    def __boundary__neighboring_vertices
        neighbors = []
        halfedge = self.outHalfEdge
        loop do
            break if halfedge.is_boundary_edge?
            halfedge = halfedge.oppHalfEdge.nextHalfEdge
        end
        neighbors << halfedge.endVertex
        loop do
            until halfedge.endVertex == self do
                prev = halfedge.dup
                halfedge = halfedge.nextHalfEdge
            end
            neighbors << prev.endVertex
            break if halfedge.is_boundary_edge?
            halfedge = halfedge.oppHalfEdge
        end
        return neighbors
    end

    # Returns an array of the neighboring vertices of this vertex.
    # To do this we first find the outgoing halfedges and just get their vertices.
    def __nonboundary__neighboring_vertices
        outgoingHEs = []
        halfedge = self.outHalfEdge
        loop do
            outgoingHEs << halfedge
            halfedge = halfedge.oppHalfEdge.nextHalfEdge
            break if halfedge == self.outHalfEdge
        end
        return outgoingHEs.map(&:endVertex)
    end

    # Just ask if target is in the neighboring vertices?
    # Also take care of trivial case.
    def __nonboundary__adjacent_to? target
        if self == target then
            return true
        else
            self.__nonboundary__neighboring_vertices.member? target
        end
    end


    # Finds the vector in 3D-space from self to the argument.
    # The coordinates are specified in the user provided obj file.
    def vector_to target
        # These are vectors from the origin to our points in space.
        p1 = Vector[ self.x, self.y, self.z ]
        p2 = Vector[ target.x, target.y, target.z ]
        # Now compute the difference.
        p1p2 = p2 - p1
        return p1p2
    end

    def vectors_to_neighbors
        vectorsTo = self.__nonboundary__neighboring_vertices.map{ |vertex| self.vector_to vertex }
    end

    def compute_curvature
        if self.is_boundary_vertex? then
            self.__boundary__compute_curvature
        else
            self.__nonboundary__compute_curvature
        end
    end


    def __boundary__compute_curvature

    end

    # Get the vectors from self to the neighboring vertices.
    # Compute the angles between adjacent vectors.
    # Sum them up, and subtract from 2pi. (Only for non-boundary vertices).
    def __nonboundary__compute_curvature
        # puts "self is #{self.x} #{self.y} #{self.z}"
        # neighboring_vertices.each do |v|
        #     puts "neighbor is #{v.x} #{v.y} #{v.z}"
        # end
        vectors = self.vectors_to_neighbors
        angles = vectors.map.with_index(0) do |vec, i|
            if vectors.member? Vector[0.0,0.0,0.0] then
                return 0
            else
                vectors[i - 1].angle_with vectors[i]
            end
        end
        sumOfAngles = angles.reduce(0, :+)
        @curvature = 2 * Math::PI - sumOfAngles
    end
end
