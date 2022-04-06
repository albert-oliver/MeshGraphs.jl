using Printf

function export_inp(g, filename)
    open(filename, "w") do io
        v_id = 1
        t_map = Dict()
        fun_map = Dict()
        counter = 0
        list_nv = collect(vertices_except_type(g, INTERIOR))
        list_interiors = collect(interiors(g))
        write(io, @sprintf("%d %d 4 1 0\n", length(list_nv), length(list_interiors)))
        for v in list_nv
            x, y, z = xyz(g, v)
            counter = counter + 1
            write(io, @sprintf("%d %f %f %f\n", counter, x, y, z))
            t_map[v] = v_id
            v_id += 1
        end

        counter = 0

        for i in list_interiors
            v1, v2, v3 = interior_connectivity(g, i)
            counter = counter + 1
            write(io, @sprintf("%d 0 tri %d %d %d\n", counter, t_map[v1], t_map[v2], t_map[v3]))
        end

        counter = 0
        write(io, "2 1 3\nvertex_id,nunits\nuve,degree\n")
        for i in list_nv
            counter += 1
            u,v,e = uve(g, i)
            write(io, "$counter $i $u $v $e\n")
        end

        counter = 0
        write(io, "1 1\ninterior_id,nunits\n")
        for i in list_interiors
            counter += 1
            write(io, "$counter $i\n")
        end

    end
end
