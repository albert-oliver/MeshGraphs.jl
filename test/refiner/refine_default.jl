@testset "refine default valus" begin

    """
    Return graph as below with interiors. Interior of top triangle is set to be
    refinded.

    ```text
       v
      / \\
     v---v--v
     |  /|\\ |
     | / | v
     |/  |/
     v---v
    ```
    """
    function get_graph()
        g = SimpleGraph()

        # vertices
        add_vertex!(g, [2.0, 11.0, 0.0]) # 1
        add_vertex!(g, [0.0, 9.0, 0.0])  # 2
        add_vertex!(g, [0.0, 2.0, 0.0])  # 3
        add_vertex!(g, [4.5, 0.0, 0.0])  # 4
        add_vertex!(g, [8.5, 3.0, 0.0])  # 5
        add_vertex!(g, [9.0, 7.5, 0.0])  # 6
        add_vertex!(g, [4.5, 10.0, 0.0]) # 7

        # interiors
        add_interior!(g, 1, 2, 7; refine=true)
        add_interior!(g, 2, 3, 7)
        add_interior!(g, 3, 4, 7)
        add_interior!(g, 4, 5, 7)
        add_interior!(g, 5, 6, 7)

        #edges
        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 4)
        add_edge!(g, 4, 5)
        add_edge!(g, 5, 6)
        add_edge!(g, 6, 7)
        add_edge!(g, 7, 1)
        add_edge!(g, 7, 2)
        add_edge!(g, 7, 3)
        add_edge!(g, 7, 4)
        add_edge!(g, 7, 5)

        return g
    end

    g = get_graph()
    refine!(g)
    @test vertex_count(g) == 10
    @test interior_count(g) == 11
    @test MeshGraphs.hanging_count(g) == 0
end
