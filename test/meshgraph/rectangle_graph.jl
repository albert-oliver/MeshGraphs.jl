@testset "rectangle_graph" begin
    g = rectangle_graph(SimpleSpec(), 0, 6, 0, 4, 2, 2)

    @testset "Graph properties" begin
        @test nv(g) == 17
        @test vertex_count(g) == 9
        @test interior_count(g) == 8
        @test MeshGraphs.hanging_count(g) == 0
    end

    @testset "Coordinates" begin
        @test uve(g, 1) == [0, 0, 0]
        @test xyz(g, 2) == [3, 0, 0]
        @test xyz(g, 3) == [6, 0, 0]
        @test xyz(g, 4) == [0, 2, 0]
        @test xyz(g, 5) == [3, 2, 0]
        @test xyz(g, 6) == [6, 2, 0]
        @test xyz(g, 7) == [0, 4, 0]
        @test xyz(g, 8) == [3, 4, 0]
        @test xyz(g, 9) == [6, 4, 0]
    end

    @testset "Connectivity" begin
        @test Set(interior_connectivity(g, 10)) == Set([1, 2, 4])
        @test Set(interior_connectivity(g, 11)) == Set([2, 4, 5])
        @test Set(interior_connectivity(g, 12)) == Set([2, 3, 5])
        @test Set(interior_connectivity(g, 13)) == Set([5, 3, 6])
        @test Set(interior_connectivity(g, 14)) == Set([4, 5, 7])
        @test Set(interior_connectivity(g, 15)) == Set([7, 5, 8])
        @test Set(interior_connectivity(g, 16)) == Set([5, 6, 8])
        @test Set(interior_connectivity(g, 17)) == Set([8, 6, 9])
    end

    @testset "Edges" begin
        @test has_edge(g, 1, 2)
        @test has_edge(g, 2, 4)
        @test has_edge(g, 4, 1)
        @test has_edge(g, 2, 5)
        @test has_edge(g, 5, 4)
        @test has_edge(g, 2, 3)
        @test has_edge(g, 3, 5)
        @test has_edge(g, 3, 6)
        @test has_edge(g, 6, 5)
        @test has_edge(g, 5, 7)
        @test has_edge(g, 7, 4)
        @test has_edge(g, 5, 8)
        @test has_edge(g, 8, 7)
        @test has_edge(g, 6, 8)
        @test has_edge(g, 6, 9)
        @test has_edge(g, 9, 8)
    end

    @testset "Boundary" begin
        @test is_on_boundary(g, 1, 2)
        @test !is_on_boundary(g, 2, 4)
        @test is_on_boundary(g, 4, 1)
        @test !is_on_boundary(g, 2, 5)
        @test !is_on_boundary(g, 5, 4)
        @test is_on_boundary(g, 2, 3)
        @test !is_on_boundary(g, 3, 5)
        @test is_on_boundary(g, 3, 6)
        @test !is_on_boundary(g, 6, 5)
        @test !is_on_boundary(g, 5, 7)
        @test is_on_boundary(g, 7, 4)
        @test !is_on_boundary(g, 5, 8)
        @test is_on_boundary(g, 8, 7)
        @test !is_on_boundary(g, 6, 8)
        @test is_on_boundary(g, 6, 9)
        @test is_on_boundary(g, 9, 8)
    end
end
