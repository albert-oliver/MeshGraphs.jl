@testset "update_boundaries!" begin

    """
    v-----v-----v
    |\\   /|\\   /|
    | \\ / | \\ / |
    |  v  |  v  |
    | / \\ | / \\ |
    |/   \\|/   \\|
    v-----v-----v
    """
    function get_graph()
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])        # 1
        add_vertex!(g, [2, 0, 0])        # 2
        add_vertex!(g, [4, 0, 0])        # 3
        add_vertex!(g, [1, 1, 0])        # 4
        add_vertex!(g, [3, 1, 0])        # 5
        add_vertex!(g, [0, 2, 0])        # 6
        add_vertex!(g, [2, 2, 0])        # 7
        add_vertex!(g, [4, 2, 0])        # 8

        add_interior!(g, 1, 2, 4)  # 9
        add_interior!(g, 1, 4, 6)  # 10
        add_interior!(g, 2, 7, 4)  # 11
        add_interior!(g, 4, 7, 6)  # 12
        add_interior!(g, 3, 5, 8)  # 13
        add_interior!(g, 2, 3, 5)  # 14
        add_interior!(g, 2, 5, 7)  # 15
        add_interior!(g, 5, 8, 7)  # 16

        return g
    end

    g = get_graph()
    update_boundaries!(g)
    @test is_on_boundary(g, 1, 2)
    @test !is_on_boundary(g, 2, 4)
    @test !is_on_boundary(g, 4, 1)
    @test !is_on_boundary(g, 4, 6)
    @test is_on_boundary(g, 6, 1)
    @test !is_on_boundary(g, 7, 4)
    @test is_on_boundary(g, 6, 7)
    @test !is_on_boundary(g, 2, 7)
    @test is_on_boundary(g, 2, 3)
    @test !is_on_boundary(g, 3, 5)
    @test !is_on_boundary(g, 5, 2)
    @test !is_on_boundary(g, 7, 5)
    @test is_on_boundary(g, 7, 8)
    @test !is_on_boundary(g, 8, 5)
    @test is_on_boundary(g, 3, 8)
end
