# A vertex has coordinates in 3D-space.
# A face has 3 three identifying coordinates
# A mesh is a list of vertices and a list of faces.
require "set.rb"
Vertex = Struct.new(:x, :y, :z)
Face = Struct.new(:idv1, :idv2, :idv3)
Mesh = Struct.new(:vertices, :faces)

# Parses an obj file into a mesh.
# Assumes the obh file is triangulated.
def parse_obj file_name

    # We want our vertices to be 1-indexed because obj files are too,
    # so we add a bogus Vertex value into the mesh.vertices list.
    mesh = Mesh.new([ Vertex[] ], [])

    File.open(file_name, "r") do |file|

        file.each_line do |line|

            # A line either looks like "v x y z", or like "f v1 v2 v3".
            vec3 = line.slice(2..-1).split(' ')

            if line[0] == 'v' then
                mesh.vertices << Vertex[*vec3.map(&:to_f)]
            elsif line[0] == 'f' then
                mesh.faces << Face[*vec3.map(&:to_i)]
            end

        end

    end

    return mesh

end

def triangulate infile_name

    base = File.basename( infile_name, ".*" )
    time = Time.now.to_i
    ext = File.extname( infile_name )
    triangulated_file_name = "#{base}_triangulated#{ext}"

    # if File.exist? triangulated_file_name
    #     puts "\nIt looks like you have a file named `#{triangulated_file_name}` in this directory already!"
    #     puts "How? That's very unlikely! We can't triangulate the original file `#{base}#{ext}`."
    #     exit
    # end

    output = File.open(triangulated_file_name, "w")

    File.open(infile_name, "r") do |file|
        file.each_line do |line|
            if ( line[0] == 'v' && line[1] == ' ' )
                output << line
                vertex_count += 1
            elsif ( line[0] == 'f' && line[1] == ' ' )
                vertices = line.slice(2..-1).split(' ')
                fixed_vertex = vertices[0];

                # We can fill up a polygon with (|V| - 2) triangles.
                (vertices.length - 2).times do |i|
                    output << 'f' + " " + fixed_vertex + " " + vertices[i+1] + " " + vertices[i+2]
                    output << "\n"

                    face_count += 1
                end
            end
        end
    end

    output.close

    return { :triangulated_file_name => triangulated_file_name,
             :vertex_count => vertex_count,
             :face_count => face_count }

end