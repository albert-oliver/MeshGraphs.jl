@testset "refine custom values" begin
    struct TestSpec <: AbstractSpec end
    TestGraph() = MeshGraph{TestSpec}(TestSpec())

    function MeshGraphs.convert(
        g::MeshGraph{TestSpec},
        coords::AbstractVector{<:Real},
    )
        u, v, e = coords
        if v >= 4
            v += 6
        end
        return [u, v, e]
    end

    function get_graph()
        g = TestGraph()

        add_vertex!(g, [0.0, 0.0, 0.0])
        add_vertex!(g, [0.0, 4.0, 0.0])
        add_vertex!(g, [5.0, 3.0, 0.0])

        add_interior!(g, 1, 2, 3; refine = true)

        add_edge!(g, 1, 2)
        add_edge!(g, 1, 3)
        add_edge!(g, 2, 3; boundary = true)

        return g
    end

    @testset "Longest edge in xyz" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
        g = get_graph()
        refine!(g)
        @test interior_count(g) == 2
        @test !has_edge(g, 1, 3)
    end

    @testset "Longest edge in uve" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
        g = get_graph()
        refine!(g)
        @test interior_count(g) == 2
        @test !has_edge(g, 1, 2)
    end

    @testset "Custom distance in xyz" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
        MeshGraphs.distance(g::MeshGraph{TestSpec}, v1::Integer, v2::Integer) =
            abs(xyz(g, v1)[1] - xyz(g, v2)[1])
        g = get_graph()
        refine!(g)
        @test interior_count(g) == 2
        @test !has_edge(g, 2, 3)
    end

    @testset "Custom distance in uve" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
        MeshGraphs.distance(g::MeshGraph{TestSpec}, v1::Integer, v2::Integer) =
            abs(uve(g, v1)[2] - uve(g, v2)[2])
        g = get_graph()
        refine!(g)
        @test interior_count(g) == 2
        @test !has_edge(g, 1, 2)
    end

    @testset "Custom coordinates in xyz" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
        MeshGraphs.new_vertex_coords(
            g::MeshGraph{TestSpec},
            v1::Integer,
            v2::Integer,
        ) = [1, 4, 0]
        g = get_graph()
        refine!(g)
        @test interior_count(g) == 2
        coords = [xyz(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end

    @testset "Custom coordinates in uve" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
        MeshGraphs.new_vertex_coords(
            g::MeshGraph{TestSpec},
            v1::Integer,
            v2::Integer,
        ) = [1, 4, 0]
        g = get_graph()
        refine!(g)
        @test interior_count(g) == 2
        coords = [uve(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end

    @testset "Custom conver in xyz" begin
        g = get_graph()
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
        MeshGraphs.convert(
            g::MeshGraph{TestSpec},
            coords::AbstractVector{<:Real},
        ) = [1, 4, 0]
        refine!(g)
        @test interior_count(g) == 2
        coords = [uve(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end

    @testset "Custom conver in uve" begin
        MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
        g = get_graph()
        MeshGraphs.convert(
            g::MeshGraph{TestSpec},
            coords::AbstractVector{<:Real},
        ) = [1, 4, 0]
        refine!(g)
        @test interior_count(g) == 2
        coords = [xyz(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end
end
