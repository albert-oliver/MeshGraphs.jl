@testset "add_hanging!" begin
    @testset "Graph properties" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [2, 0, 0])
        MeshGraphs.add_hanging!(g, [1, 0, 0], 1, 2)
        @test nv(g) == 3
        @test vertex_count(g) == 2
        @test interior_count(g) == 0
        @test MeshGraphs.hanging_count(g) == 1
    end

    @testset "Type" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [2, 0, 0])
        MeshGraphs.add_hanging!(g, [1, 0, 0], 1, 2)
        @test is_vertex(g, 3) == false
        @test is_interior(g, 3) == false
        @test MeshGraphs.is_hanging(g, 3) == true
        @test get_type(g, 3) == HANGING
    end

    @testset "set_hanging" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [2, 0, 0])
        add_vertex!(g, [1, 0, 0])
        MeshGraphs.set_hanging!(g, 3, 1, 2)
        @test MeshGraphs.is_hanging(g, 3) == true
    end

    @testset "get_hanging_node_between" begin
        @testset "Single hanging node" begin
            g = SimpleGraph()
            add_vertex!(g, [0, 0, 0])
            add_vertex!(g, [2, 0, 0])
            add_vertex!(g, [1, 1, 0])
            MeshGraphs.add_hanging!(g, [1, 0, 0], 1, 2)
            MeshGraphs.add_pure_interior!(g, 1, 2, 3)
            add_edge!(g, 1, 4)
            add_edge!(g, 4, 2)
            add_edge!(g, 2, 3)
            add_edge!(g, 3, 1)
            @test MeshGraphs.get_hanging_node_between(g, 1, 2) == 4
        end
        @testset "No hanging node" begin
            g = SimpleGraph()
            add_vertex!(g, [0, 0, 0])
            add_vertex!(g, [2, 0, 0])
            add_vertex!(g, [1, 1, 0])
            MeshGraphs.add_interior!(g, 1, 2, 3)
            @test isnothing(MeshGraphs.get_hanging_node_between(g, 1, 2))
        end
        @testset "Two hanging nodes" begin
            g = SimpleGraph()
            add_vertex!(g, [0, 0, 0])                       # 1
            add_vertex!(g, [2, 0, 0])                       # 2
            add_vertex!(g, [0, 1, 0])                       # 3
            add_vertex!(g, [2, 1, 0])                       # 4
            add_vertex!(g, [1, 2, 0])                       # 5
            MeshGraphs.add_hanging!(g, [1, 0, 0], 1, 2)     # 6
            MeshGraphs.add_hanging!(g, [1, 1, 0], 3, 4)     # 7
            MeshGraphs.add_pure_interior!(g, 1, 2, 7)       # 8
            MeshGraphs.add_pure_interior!(g, 3, 4, 5)       # 9
            add_edge!(g, 1, 6)
            add_edge!(g, 6, 2)
            add_edge!(g, 2, 7)
            add_edge!(g, 7, 1)
            add_edge!(g, 3, 7)
            add_edge!(g, 7, 4)
            add_edge!(g, 4, 5)
            add_edge!(g, 5, 3)
            @test MeshGraphs.get_hanging_node_between(g, 1, 2) == 6
        end
    end
end
