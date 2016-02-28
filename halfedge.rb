load 'triangulate.rb'
load 'Mesh.rb'

if ( File.exist? ARGV[0] )
    results = triangulate ARGV[0]
else
    puts "\nThe file `#{ARGV[0]}` was not found in the current directory!"
    exit
end

half_edges = Hash.new

mesh = Mesh.new([], [])

File.open( results[:triangulated_file_name] ) do |file|

    file.each_line do |line|

        if ( line[0] == 'v' && line[1] == ' ' )

            coordinates = line.split(' ').slice(1,3).map(&:to_f)
            vertex = Vertex.new(coordinates[0], coordinates[1], coordinates[2])
            mesh.vertices.push(vertex)

        elsif ( line[0] == 'f' && line[1] == ' ' )

            face_vertices = line.slice(2..-1).split(' ').map(&:to_i)
            vertex1 = face_vertices[0]
            vertex2 = face_vertices[1]
            vertex3 = face_vertices[2]

            halfEdge1 = HalfEdge.new()
            halfEdge2 = HalfEdge.new()
            halfEdge3 = HalfEdge.new()

            ind1 = [vertex1,vertex2].min
            ind2 = [vertex1,vertex2].max
            ind3 = [vertex2,vertex3].min
            ind4 = [vertex2,vertex3].max
            ind5 = [vertex3,vertex1].min
            ind6 = [vertex3,vertex1].max

            if ( not half_edges.has_key? :"#{ind1},#{ind2}" ) then
                half_edges[:"#{ind1},#{ind2}"] = halfEdge1
            else
                # The sorted key already exists, so this halfedge must be the opposite of what's in the key
                halfEdge1.oppHalfEdge = half_edges[:"#{ind1},#{ind2}"]
                half_edges[:"#{ind1},#{ind2}"].oppHalfEdge = halfEdge1
                # Now add it to the hash at the reverse-sorted key.
                half_edges[:"#{ind2},#{ind1}"] = halfEdge1
            end

            # Repeat above.
            if ( not half_edges.has_key? :"#{ind3},#{ind4}" )
                half_edges[:"#{ind3},#{ind4}"] = halfEdge2
            else
                halfEdge2.oppHalfEdge = half_edges[:"#{ind3},#{ind4}"]
                half_edges[:"#{ind3},#{ind4}"].oppHalfEdge = halfEdge2
                half_edges[:"#{ind4},#{ind3}"] = halfEdge2
            end

            # Repeat above.
            if ( not half_edges.has_key? :"#{ind5},#{ind6}" )
                half_edges[:"#{ind5},#{ind6}"] = halfEdge3
            else
                halfEdge2.oppHalfEdge = half_edges[:"#{ind5},#{ind6}"]
                half_edges[:"#{ind5},#{ind6}"].oppHalfEdge = halfEdge3
                half_edges[:"#{ind6},#{ind5}"] = halfEdge3
            end

            # Create a face and point it's borderingHalfEdge arbitrarily to the first halfEdge
            face = Face.new()
            face.borderingHalfEdge = halfEdge1
            mesh.faces.push(face);

            # Point the halfEdges to the face.
            halfEdge1.adjFace = face
            halfEdge2.adjFace = face
            halfEdge3.adjFace = face

        end

    end

end

faces = mesh.faces

puts half_edges.key(faces[0].borderingHalfEdge)
puts half_edges.key(faces[0].borderingHalfEdge.oppHalfEdge)
puts half_edges.key(faces[0].borderingHalfEdge.oppHalfEdge.oppHalfEdge)
puts half_edges.key(faces[0].borderingHalfEdge.oppHalfEdge.oppHalfEdge.oppHalfEdge)


# Recursively orient the faces in a CCW fashion.
def orient_face face

    # Mesh
    # face.borderingHalfEdge.endingVertex = halfEdges[]
    # face.borderingHalfEdge.nextHalfEdge
    # if face.oriented? then
    #     # do nothing.
    # else
    #     orient_faceface.borderingHalfEdge

end


puts "Size of half_edges hashmap is #{half_edges.size}"
puts "Half of half_edges hashmap is #{half_edges.size/2.0}"
puts "Face from triangulated file is #{results[:face_count]}"
puts "So, edge count from triangulated file is #{3.0/2.0 * results[:face_count]}"

# Since every face touches 3 half-edges, then we have the relation HE = 3F.
if ( half_edges.size != 3 * results[:face_count] )
    puts "\nWoah! The number of parsed half-edges in the triangulated .obj file is"
    puts "not equal to the size of the constructed half-edges hash-map!"
    puts "\nThis means that there exists an edge in this mesh that is adjacent to"
    puts "more than two faces! Formally, not every edge in this .obj file is manifold."
    puts "\nThe original file #{ARGV[0]} has been triangulated, but was not converted"
    puts "to a half-edge mesh data structure."
    exit
end

# edges.each do |vertex_pair, halfedge|
#     puts "#{vertex_pair} #{halfedge.endingVertex.x} #{halfedge.endingVertex.y} #{halfedge.endingVertex.z}"
# end

# mesh.faces.each do |face|
#     if (face.borderingHalfEdge != nil )
#         puts face
#     end
# end

