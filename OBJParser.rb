# A mesh will be a list of vertices and a list of faces.
Mesh = Struct.new(:vertices, :faces)

class OBJParser

    def self.parse fileName

        mesh = Mesh.new([], [])

        File.open(fileName, "r") do |file|
            file.each_line do |line|
                # A line looks like "v x y z", or like "f v1 v2 v3 ..."
                if line[0] == 'v' then
                    mesh.vertices << line.slice(2..-1).split(' ').map(&:to_f)
                elsif line[0] == 'f' then
                    # Vertices are 1-indexed in obj files. We like 0-indexed.
                    mesh.faces << line.slice(2..-1).split(' ').map(&:to_i).map(&:pred)
                end
            end
        end

        return mesh

    end

end