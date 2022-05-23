@testset "Iterables" begin

    """
    v-----v-----v
    |\\    |    /|
    | \\   |   / |
    |  h  |  h  |
    | / \\ | / \\ |
    |/   \\|/   \\|
    v-----v-----v
    """
    function get_graph()
        g = SimpleGraph()
        add_vertex!(g, [0, 0, 0])        # 1
        add_vertex!(g, [2, 0, 0])        # 2
        add_vertex!(g, [4, 0, 0])        # 3
        add_vertex!(g, [1, 1, 0])        # 4    hanging
        add_vertex!(g, [3, 1, 0])        # 5    hanging
        add_vertex!(g, [0, 2, 0])        # 6
        add_vertex!(g, [2, 2, 0])        # 7
        add_vertex!(g, [4, 2, 0])        # 8
        MeshGraphs.set_hanging!(g, 4, 2, 6)
        MeshGraphs.set_hanging!(g, 5, 2, 8)

        MeshGraphs.add_pure_interior!(g, 1, 2, 4)  # 9
        MeshGraphs.add_pure_interior!(g, 1, 4, 6)  # 10
        MeshGraphs.add_pure_interior!(g, 2, 7, 6)  # 11
        MeshGraphs.add_pure_interior!(g, 3, 5, 8)  # 12
        MeshGraphs.add_pure_interior!(g, 2, 3, 5)  # 13
        MeshGraphs.add_pure_interior!(g, 2, 8, 7)  # 14

        add_edge!(g, 1, 2)
        add_edge!(g, 2, 3)
        add_edge!(g, 3, 8)
        add_edge!(g, 8, 7)
        add_edge!(g, 7, 6)
        add_edge!(g, 6, 1)
        add_edge!(g, 1, 4)
        add_edge!(g, 2, 4)
        add_edge!(g, 4, 6)
        add_edge!(g, 3, 5)
        add_edge!(g, 2, 5)
        add_edge!(g, 5, 8)

        return g
    end
    @testset "Vertices" begin

        @testset "normal_vertices" begin
            g = get_graph()
            vs = [1, 2, 3, 6, 7, 8]
            @test Set(normal_vertices(g)) == Set(vs)
            @test Set(vertices_with_type(g, VERTEX)) == Set(vs)
        end

        @testset "hanging_nodes" begin
            g = get_graph()
            vs = 4:5
            @test Set(MeshGraphs.hanging_nodes(g)) == Set(vs)
            @test Set(vertices_with_type(g, HANGING)) == Set(vs)
        end

        @testset "interiors" begin
            g = get_graph()
            vs = vcat(9:14)
            @test Set(interiors(g)) == Set(vs)
            @test Set(vertices_with_type(g, INTERIOR)) == Set(vs)
        end

        @testset "Except normal_vertices" begin
            g = get_graph()
            vs = vcat(4:5, 9:14)
            @test Set(vertices_except_type(g, VERTEX)) == Set(vs)
        end

        @testset "Except interiors" begin
            g = get_graph()
            vs = 1:8
            @test Set(vertices_except_type(g, INTERIOR)) == Set(vs)
        end

        @testset "Except hanging_nodes" begin
            g = get_graph()
            vs = vcat(1:3, 6:14)
            @test Set(vertices_except_type(g, HANGING)) == Set(vs)
        end

        @testset "neighbors" begin
            g = get_graph()
            vs = [1, 4, 5, 3, 9, 11, 13, 14]
            @test Set(neighbors(g, 2)) == Set(vs)
        end

        @testset "vertex_neighbors" begin
            g = get_graph()
            vs = [1, 3]
            @test Set(vertex_neighbors(g, 2)) == Set(vs)
            @test Set(neighbors_with_type(g, 2, VERTEX)) == Set(vs)
        end

        @testset "interior_neighbors" begin
            g = get_graph()
            vs = [9, 11, 13, 14]
            @test Set(interior_neighbors(g, 2)) == Set(vs)
            @test Set(neighbors_with_type(g, 2, INTERIOR)) == Set(vs)
        end

        @testset "hanging_neighbors" begin
            g = get_graph()
            vs = [4, 5]
            @test Set(MeshGraphs.hanging_neighbors(g, 2)) == Set(vs)
            @test Set(neighbors_with_type(g, 2, HANGING)) == Set(vs)
        end
    end

    @testset "Edges" begin
        @testset "edges" begin
            g = get_graph()
            es = Set(
                [
                    Set((1, 2))
                    Set((2, 3))
                    Set((3, 8))
                    Set((8, 7))
                    Set((7, 6))
                    Set((6, 1))
                    Set((1, 4))
                    Set((2, 4))
                    Set((4, 6))
                    Set((3, 5))
                    Set((2, 5))
                    Set((5, 8))
                ],
            )
            @test Set(map(x -> Set(x), edges(g))) == es
        end

        @testset "all_edges" begin
            g = SimpleGraph()
            add_vertex!(g, [0, 0, 0])
            add_vertex!(g, [1, 0, 0])
            add_vertex!(g, [0, 1, 0])
            add_interior!(g, 1, 2, 3)
            es = Set(
                [
                    Set((1, 2))
                    Set((2, 3))
                    Set((3, 1))
                    Set((1, 4))
                    Set((2, 4))
                    Set((3, 4))
                ],
            )
            @test Set(map(x -> Set(x), all_edges(g))) == es
        end
    end
end
