using Printf

function export_inp(g, filename)
    open(filename, "w") do io
        v_id = 1
        t_map = Dict()
        fun_map = Dict()
        counter = 0
        list_nv = collect(normal_vertices(g))
        list_hv = collect(MeshGraphs.hanging_nodes(g))
        list_interiors = collect(interiors(g))
        write(io, @sprintf("%d %d 0 0 0\n", length(list_nv) + length(list_hv), length(list_interiors)))
        for v in list_nv
            x, y, z = xyz(g, v)
            counter = counter + 1
            write(io, @sprintf("%d %f %f %f\n", counter, x, y, z))
            t_map[v] = v_id
            v_id += 1
        end

        # TODO remove
        for v in list_hv
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
    end
end
