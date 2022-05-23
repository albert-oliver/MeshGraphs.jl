@testset "vertex_map" begin

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
        add_vertex!(g, [0, 0, 0])       # 1
        add_vertex!(g, [2, 0, 0])       # 2
        add_vertex!(g, [1, 1, 0])       # 3
        add_interior!(g, 1, 2, 3)       # 4
        add_vertex!(g, [0, 2, 0])       # 5
        add_interior!(g, 1, 3, 5)       # 6
        add_vertex!(g, [2, 2, 0])       # 7
        add_interior!(g, 2, 7, 3)       # 8
        add_interior!(g, 3, 7, 5)       # 9
        return g
    end

    g = get_graph()
    @test vertex_map(g) == Dict(1 => 1, 2 => 2, 3 => 3, 5 => 4, 7 => 5)
end
