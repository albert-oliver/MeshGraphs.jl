function MeshGraph(coords::AbstractMatrix{<:Real}, conec::AbstractMatrix{<:Integer}, spec::AbstractSpec)
    g = MeshGraph(spec)

    for uv in eachcol(coords)
        add_vertex!(g, vcat(uv, 0))
    end

    if any(conec .== 0)
        conec = conec .+ 1
    end

    for vs in eachcol(conec)
        add_interior!(g, vs)
        add_edge!(g, vs[1], vs[2])
        add_edge!(g, vs[2], vs[3])
        add_edge!(g, vs[3], vs[1])
    end

    update_boundaries!(g)
    return g
end

function update_boundaries!(g::AbstractMeshGraph)
    for (v1, v2) in edges(g)
        interiors1 = interior_neighbors(g, v1)
        interiors2 = interior_neighbors(g, v2)
        interiors = intersect(interiors1, interiors2)
        if length(interiors) == 1
            set_boundary!(g, v1, v2)
        end
    end
end
