@testset verbose = true "MeshGraph" begin
    include("add_vertex.jl")
    include("add_edge.jl")
    include("add_interior.jl")
    include("add_hanging.jl")
    include("iterables.jl")
    include("vertex_map.jl")
    include("custom_field.jl")
    include("update_boundaries.jl")
    include("rectangle_graph.jl")
end
