include("production_graphs.jl")

function get_default_xyz_kwargs()
    Dict(
        :use_uv => false,
        :distance_fun => ((g, v1, v2) -> norm(xyz(g, v1) - xyz(g, v2))),
        :new_coords_fun => ((g, v1, v2) -> mean([xyz(g, v1), xyz(g, v2)])),
        :converter_fun => identity,
    )
end

@testset "Rivara" begin
    include("p1.jl")
    include("p2.jl")
    include("p3.jl")
    include("p4.jl")
    include("p5.jl")
    include("p6.jl")
    include("p6.jl")
end
