module MeshGraphs

export
    MeshGraph,
    FlatGraph,
    SphereGraph,
    VERTEX, HANGING, INTERIOR,

    # Adding / removing
    add_vertex!,
    add_hanging!,
    add_interior!,
    add_edge!,
    rem_vertex!,
    rem_edge!,

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
    interiors_vertices,
    is_ordinary_edge,
    edges,
    all_edges,

    # Vertex properties
    set_hanging!,
    unset_hanging!,
    get_cartesian,
    xyz,
    uv,
    get_type,
    is_hanging,
    is_vertex,
    is_interior,
    get_elevation,
    set_elevation!,
    get_value,
    set_value!,
    get_value_cartesian,
    get_all_values,
    set_all_values!,
    should_refine,
    set_refine!,
    unset_refine!,

    # Edge properties
    is_on_boundary,
    set_boundary!,
    unset_boundary!,
    edge_length,
    has_edge,

    # Other
    has_hanging_nodes,
    get_hanging_node_between,
    vertex_map,
    scale_graph,

    # SphereGraph only
    get_spherical,
    lat,
    lon

include("meshgraph.jl")

end # module
