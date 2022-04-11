using Combinatorics

include("production_graphs.jl")

function test_counts(g, v_cout, i_count, h_count, e_count)
    @test vertex_count(g) == v_cout
    @test interior_count(g) == i_count
    @test MeshGraphs.hanging_count(g) == h_count
    @test length(edges(g)) == e_count
end

function has_vertex_with_coords(g, coords)
    for v in vertices_except_type(g, INTERIOR)
        if xyz(g, v) ≈ coords
            return true
        end
    end
    return false
end

function test_vertex_is_type(g, coords, type)
    found_vertex = false
    for v in vertices_except_type(g, INTERIOR)
        if xyz(g, v) ≈ coords
            @test get_type(g, v) == type
            found_vertex = true
        end
    end
    @test found_vertex
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
