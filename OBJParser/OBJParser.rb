# A mesh will be a list of vertices and a list of faces.
Mesh = Struct.new(:vertices, :faces)

class OBJParser

    def self.parse fileName

        mesh = Mesh.new([], [])

        File.open(fileName, "r") do |file|

            # The lines we're interested in look like "v x y z", or like "f v1 v2 v3 ..."
            file.each_line do |line|

                if line[0] == 'v' && line[1] == ' ' then
                    mesh.vertices << line.split(' ').drop(1).map(&:to_f)

                elsif line[0] == 'f' && line[1] == ' ' then
                    # Vertices are 1-indexed in obj files. We like 0-indexed.
                    face = line.split(' ').drop(1).map(&:to_i).map(&:pred)

                    face.each_with_index do |_, i|
                        if face[i - 1] == face[i] then
                            abort "Woah! That's a bad obj file.\n"\
                            "There is a half-edge whose source and target vertex are the same!\n"\
                            "Offending half-edge occurs in the face `f #{face.map{|v| v+1}.join(' ')}`.\n"\
                            "Vertex in question is `v #{mesh.vertices[face[i]][0]}" "#{mesh.vertices[face[i]][1]} #{mesh.vertices[face[i]][2]}`."
                        end
                    end

                    mesh.faces << face

                end

            end

        end

        # Before returning, find duplicate vertices with their sizes in linear time!
        fakeVertices = mesh.vertices.group_by{|v| v}.select{|k,v| v.size > 1}.map{|k,v| [k, v.size]}
        unless fakeVertices.empty?
            puts "\nYou have several pseudo-unique vertices in this mesh. Say what?\n"\
                 "The following vertices are listed uniquely in your .obj file,\n"\
                 "but have identical coordinates:\n\n"
            fakeVertices.each do |fv, multiplicity|
                puts "(#{fv[0]}, #{fv[1]}, #{fv[2]}) occurs #{multiplicity} times."
            end
            puts "\nThis is fine, but the total curvature of the surface may be a bit off"
            puts "since we'll ignore the angles formed by adjacent edges on these vertices."
        end

        return mesh

    end

end