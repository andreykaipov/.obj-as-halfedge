#
# @author Andrey Kaipov
#
# ARGV[0] is the source .obj file to be triangulated.
# ARGV[1] is the triangulated .obj file with a name of your choice.
#
# Further, this script removes vertex texture coordinates, vertex normals,
# and parameter space vertices. See https://en.wikipedia.org/wiki/Wavefront_.obj_file#File_format.
# We compute our own face normals and vertex normals.
#
# Example:

def triangulate infile_name

    vertex_count = 0
    face_count = 0

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