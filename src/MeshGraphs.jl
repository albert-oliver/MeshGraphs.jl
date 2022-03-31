module MeshGraphs

export
    MeshGraph,
    VERTEX, INTERIOR,

    # Adding / removing
    add_vertex_xyz!,
    add_vertex_uv!,
    add_interior!,
    add_edge!,

    # Counts
    all_vertex_count,
    nv,
    vertex_count,
    hanging_count,
    interior_count,

    # Iteratable
    vertices_with_type,
    vertices_except_type,
    normal_vertices,
    hanging_nodes,
    interiors,
    neighbors,
    neighbors_with_type,
    neighbors_except_type,
    vertex_neighbors,
    hanging_neighbors,
    interior_neighbors,
    interior_connectivity,
    is_ordinary_edge,
    edges,
    all_edges,

    # Vertex properties
    xyz,
    uv,
    get_type,
    is_vertex,
    is_interior,
    get_elevation,
    set_elevation!,
    should_refine,
    set_refine!,

    # Edge properties
    is_on_boundary,
    set_boundary!,
    unset_boundary!,
    edge_length,

    # Other
    vertex_map

include("meshgraph.jl")

end # module
