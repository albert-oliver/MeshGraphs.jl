@testset "add_edge!" begin
    @testset "has_edge" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_vertex!(g, [0, 1, 0])
        add_edge!(g, 1, 2)
        @test has_edge(g, 1, 2) == true
        @test has_edge(g, 2, 3) == false
        @test has_edge(g, 3, 1) == false
    end

    @testset "boundary" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_vertex!(g, [0, 1, 0])
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3; boundary=true)
        add_edge!(g, 3, 1)
        @test is_on_boundary(g, 1, 2) == false
        @test is_on_boundary(g, 2, 3) == true
        @test is_on_boundary(g, 3, 1) == false
        set_boundary!(g, 1, 2)
        @test is_on_boundary(g, 1, 2) == true
        unset_boundary!(g, 1, 2)
        @test is_on_boundary(g, 1, 2) == false
    end

    @testset "edge length" begin
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])
        add_vertex!(g, [1, 0, 0])
        add_edge!(g, 1, 2)
        edge_length(g, 1, 2) == 1
    end
end
