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
