module MeshGraphs

export AbstractMeshGraph,
    MeshGraph,
    AbstractSpec,
    VERTEX,
    INTERIOR,
    HANGING,
    AddVertexStrategy,
    USE_UVE,
    USE_XYZ,

    # To implement

    add_vertex_strategy,
    convert,
    distance,
    new_vertex_coords,

    # Refiner
    refine!,

    # Adding / removing
    add_vertex!,
    add_interior!,
    add_edge!,

    # Graph properties
    spec,
    all_vertex_count,
    nv,
    vertex_count,
    interior_count,

    # Iteratable
    vertices_with_type,
    vertices_except_type,
    normal_vertices,
    interiors,
    neighbors,
    neighbors_with_type,
    neighbors_except_type,
    vertex_neighbors,
    interior_neighbors,
    interior_connectivity,
    is_ordinary_edge,
    edges,
    all_edges,

    # Vertex properties
    xyz,
    uv,
    uve,
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
    has_edge,

    # Other
    vertex_map,
    update_boundaries!,
    rectangle_graph_uve,
    export_inp,

    # SimpleGraph
    SimpleGraph,
    SimpleSpec


include("meshgraph.jl")
include("io.jl")
include("refiner/refiner.jl")
include("utils.jl")
include("rectangle_mesh.jl")
include("simplegraph.jl")

end # module
