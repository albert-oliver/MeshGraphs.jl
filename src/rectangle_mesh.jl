function rectangle_graph(
    spec::AbstractSpec,
    x_min,
    x_max,
    y_min,
    y_max,
    n_elem_x,
    n_elem_y,
)
    coords, conec = rectangle_triangular_mesh(
        x_min,
        x_max,
        y_min,
        y_max,
        n_elem_x,
        n_elem_y,
    )

    return MeshGraph(coords, conec, spec)
end

rectangle_graph(x_min, x_max, y_min, y_max, n_elem_x, n_elem_y) =
    rectangle_graph(
        SimpleSpec(),
        x_min,
        x_max,
        y_min,
        y_max,
        n_elem_x,
        n_elem_y,
    )


function rectangle_triangular_mesh(
    x_min,
    x_max,
    y_min,
    y_max,
    n_elem_x,
    n_elem_y;
    p = 1,
)

    coords, row_size, col_size =
        get_coords(x_min, x_max, y_min, y_max, n_elem_x, n_elem_y, p)
    conec = get_conec(n_elem_x, n_elem_y, p, row_size)

    return coords, conec
end

function get_coords(x_min, x_max, y_min, y_max, n_elem_x, n_elem_y, p)
    x = range(x_min, x_max, length = (p * n_elem_x) + 1)
    y = range(y_min, y_max, length = (p * n_elem_y) + 1)

    Y = y' .* ones(size(x))
    X = ones(size(y))' .* x
    coords = [X[:]'; Y[:]']
    row_size = (p * n_elem_x) + 1
    col_size = (p * n_elem_y) + 1
    return [coords, row_size, col_size]
end

function get_conec(n_elem_x, n_elem_y, p, row_size)
    h = get_local_order(p, row_size)

    conec = Matrix{Int}(undef, (p + 1) * (p + 2) ÷ 2, 2 * n_elem_y * n_elem_x)

    for i = 1:n_elem_y
        for j = 1:n_elem_x
            n_base = (i - 1) * p * row_size + (j - 1) * p + 1
            n_base2 = n_base + p + p * row_size
            conec[:, (i-1)*2*n_elem_x+2*(j-1)+1] = n_base .+ h
            conec[:, (i-1)*2*n_elem_x+2*(j-1)+2] = n_base2 .- h
        end
    end
    return conec
end

function get_vertices_conecs(base_node, p, row_size)
    return [base_node, base_node + p, base_node + p * row_size]
end

function get_edges_conecs(base_node, p, row_size)
    return [
        base_node+1:base_node+p-1,
        base_node+p+(row_size-1):(row_size-1):base_node+p+(p-1)*(row_size-1),
        base_node+(p-1)*row_size:-row_size:base_node+row_size,
    ]
end

function get_local_order(p, row_size)
    base_node = 0
    h = Vector{Int}()
    while p > 0
        append!(h, get_vertices_conecs(base_node, p, row_size))
        if p > 1
            append!(h, get_edges_conecs(base_node, p, row_size))
        end

        base_node = base_node + 1 + row_size
        p = p - 3
        if p == 0
            append!(h, base_node)
            p = p - 1
        end
    end
    return h
end
