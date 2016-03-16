#
# @author Andrey Kaipov
#
# This class represents a vertex of our half-edge mesh.
# It holds the coordinates of the vertex, and a pointer to one outgoing half-edge,
# and some other helpful attributes. Like with faces, while the operations on
# vertices are very important, they're very easy to initialize once we create
# our half-edges!
#

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
            return true if halfedge.is_boundary_edge?
            halfedge = halfedge.oppHalfEdge.nextHalfEdge
            break if halfedge == self.outHalfEdge
        end
        return false
    end

    # Here we swipe from the outgoing halfedge to a boundary halfedge,
    # and then swipe all the way to the other boundary halfedge.
    # The style in which we sweep first is important - take note!
    def __boundary__neighboring_vertices
        neighbors = []
        halfedge = self.outHalfEdge
        # Sweep to the boundary.
        loop do
            break if halfedge.is_boundary_edge?
            halfedge = halfedge.oppHalfEdge.nextHalfEdge
        end
        neighbors << halfedge.endVertex
        # Sweep to the other boundary.
        loop do
            # This until-loop is a workaround to not having previous pointers.
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

    # We split this case up for boundary and non-boundary vertices.
    # Can we just have one method for both? ... I can't think of one!
    def adjacent_to? target
        if self.is_boundary_vertex? then
            return self.__boundary__adjacent_to? target
        else
            return self.__nonboundary__adjacent_to? target
        end
    end

    # Just ask if target is in the neighboring vertices?
    # Also take care of trivial case.
    def __boundary__adjacent_to? target
        # A vertex is trivially adjacent to itself.
        if self == target then
            return true
        else
            self.__boundary__neighboring_vertices.member? target
        end
    end

    def __nonboundary__adjacent_to? target
        if self == target then
            return true
        else
            self.__nonboundary__neighboring_vertices.member? target
        end
    end

    # This method is for boundary vertices.
    def adjacent_via_boundary_edge_to? target

        neighbors = []
        halfedge = self.outHalfEdge
        prev = nil

        # Sweep to the boundary.
        loop do
            break if halfedge.is_boundary_edge?
            halfedge = halfedge.oppHalfEdge.nextHalfEdge
        end
        # Now we're at the boundary.
        return true if halfedge.endVertex == target

        # Sweep to the other boundary.
        loop do
            # This until-loop is a workaround to not having previous pointers.
            until halfedge.endVertex == self do
                prev = halfedge.dup
                halfedge = halfedge.nextHalfEdge
            end
            neighbors << prev.endVertex
            break if halfedge.is_boundary_edge?
            halfedge = halfedge.oppHalfEdge
        end

        # Now we're at the other boundary.
        return true if prev.endVertex == target

        return false # otherwise

    end


    # Finds the vector in 3D-space from self to the target argument.
    # If self is point p1, and target is point p2, then our desired vector is p2 - p1.
    def vector_to target
        return Vector[ target.x - self.x, target.y - self.y, target.z - self.z ]
    end


    def compute_curvature
        if self.is_boundary_vertex? then
            self.__boundary__compute_curvature
        else
            self.__nonboundary__compute_curvature
        end
    end


    def __boundary__compute_curvature
        vectors = self.__boundary__neighboring_vertices.map { |vertex| self.vector_to vertex }
        angles = []
        (vectors.size - 1).times do |i|
            angles[i] = Math::acos vectors[i].normalize.inner_product vectors[i + 1].normalize
        end
        sumOfAngles = angles.reduce(0, :+)
        @curvature = Math::PI - sumOfAngles
    end

    # Get the vectors from self to the neighboring vertices.
    # Compute the angles between adjacent vectors.
    # Sum them up, and subtract from 2pi. (Only for non-boundary vertices).
    def __nonboundary__compute_curvature
        # puts "self is #{self.x} #{self.y} #{self.z}"
        # neighboring_vertices.each do |v|
        #     puts "neighbor is #{v.x} #{v.y} #{v.z}"
        # end
        vectors = self.__nonboundary__neighboring_vertices.map{ |vertex| self.vector_to vertex }
        # If the above vectors array has a zero vector,
        # then that means there are pseudo-unique vertices in the obj file.
        angles = vectors.map.with_index(0) do |_, i|
            if vectors.member? Vector[0.0, 0.0, 0.0] then
                return 0
            else
                Math::acos vectors[i - 1].normalize.inner_product vectors[i].normalize
            end
        end
        sumOfAngles = angles.reduce(0, :+)
        @curvature = 2 * Math::PI - sumOfAngles
    end
end
