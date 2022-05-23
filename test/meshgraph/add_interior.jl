@testset "add_interior!" begin
    @testset "Graph properties" begin
        @testset "v1, v2, v3" begin
            g = SimpleGraph()
            add_vertex!(g, [0, 0, 0])
            add_vertex!(g, [1, 0, 0])
            add_vertex!(g, [0, 1, 0])
            add_interior!(g, 1, 2, 3)
            @test nv(g) == 4
            @test vertex_count(g) == 3
            @test interior_count(g) == 1
            @test MeshGraphs.hanging_count(g) == 0
        end
        @testset "vs" begin
            g = SimpleGraph()
            add_vertex!(g, [0, 0, 0])
            add_vertex!(g, [1, 0, 0])
            add_vertex!(g, [0, 1, 0])
            add_interior!(g, [1, 2, 3])
            @test nv(g) == 4
            @test vertex_count(g) == 3
            @test interior_count(g) == 1
            @test MeshGraphs.hanging_count(g) == 0
        end
    end

    @testset "Type" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_vertex!(g, [0, 1, 0])
        add_interior!(g, 1, 2, 3)
        @test is_vertex(g, 4) == false
        @test is_interior(g, 4) == true
        @test MeshGraphs.is_hanging(g, 4) == false
        @test get_type(g, 4) == INTERIOR
    end

    @testset "refine" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_vertex!(g, [0, 1, 0])
        add_vertex!(g, [-1, 0, 0])
        i1 = add_interior!(g, 1, 2, 3)
        i2 = add_interior!(g, 1, 3, 4; refine=true)

        @test should_refine(g, i1) == false
        @test should_refine(g, i2) == true
        set_refine!(g, i1)
        @test should_refine(g, i1) == true
    end

    @testset "New edges" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_vertex!(g, [0, 1, 0])
        add_interior!(g, 1, 2, 3)
        @test has_edge(g, 1, 2) == true
        @test has_edge(g, 2, 3) == true
        @test has_edge(g, 3, 4) == true
    end

    @testset "interior_connectivity" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_vertex!(g, [0, 1, 0])
        add_interior!(g, 1, 2, 3)
        @test Set(interior_connectivity(g, 4)) == Set([1, 2, 3])
    end
end
