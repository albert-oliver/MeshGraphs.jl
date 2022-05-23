@testset "add_vertex!" begin
    struct TestSpec <: AbstractSpec end
    TestGraph() = MeshGraph(TestSpec())

    @testset "Graph properties" begin

        @testset "Add xyz" begin
            MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
            g = TestGraph()
            add_vertex!(g, [1, 2, 3])
            @test nv(g) == 1
            @test vertex_count(g) == 1
            @test interior_count(g) == 0
            @test MeshGraphs.hanging_count(g) == 0
        end

        @testset "Add uv" begin
            MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
            g = TestGraph()
            add_vertex!(g, [1, 2, 3])
            @test nv(g) == 1
            @test vertex_count(g) == 1
            @test interior_count(g) == 0
            @test MeshGraphs.hanging_count(g) == 0
        end
    end

    @testset "Type" begin
        g = TestGraph()
        add_vertex!(g, [1, 2, 3])
        @test is_vertex(g, 1) == true
        @test is_interior(g, 1) == false
        @test MeshGraphs.is_hanging(g, 1) == false
        @test get_type(g, 1) == VERTEX
    end

    @testset "Elevation" begin
        g = TestGraph()
        add_vertex!(g, [1, 2, 3])
        set_elevation!(g, 1, 10)
        @test get_elevation(g, 1) == 10
    end

    @testset "Default convert" begin
        @testset "Add xyz" begin
            MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
            g = TestGraph()
            add_vertex!(g, [1, 2, 3])
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [1, 2]
            @test uve(g, 1) == [1, 2, 3]
            @test get_elevation(g, 1) == 3
        end

        @testset "Add uv" begin
            MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
            g = TestGraph()
            add_vertex!(g, [1, 2, 3])
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [1, 2]
            @test uve(g, 1) == [1, 2, 3]
            @test get_elevation(g, 1) == 3
        end
    end

    @testset "Custom convert" begin

        @testset "Add xyz" begin
            MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_XYZ
            MeshGraphs.convert(
                g::MeshGraph{TestSpec},
                coords::AbstractVector{<:Real},
            ) = [4, 5, 6]
            g = TestGraph()
            add_vertex!(g, [1, 2, 3])
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [4, 5]
            @test uve(g, 1) == [4, 5, 6]
            @test get_elevation(g, 1) == 6
        end

        @testset "Add uv" begin
            MeshGraphs.add_vertex_strategy(g::MeshGraph{TestSpec}) = USE_UVE
            MeshGraphs.convert(
                g::MeshGraph{TestSpec},
                coords::AbstractVector{<:Real},
            ) = [1, 2, 3]
            g = TestGraph()
            add_vertex!(g, [4, 5, 6])
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [4, 5]
            @test uve(g, 1) == [4, 5, 6]
            @test get_elevation(g, 1) == 6
        end
    end
end
