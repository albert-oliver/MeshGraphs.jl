@testset "P6" begin
    @testset "Should run" begin
        for g in get_graphs_for_production(:p6)
            @test MeshGraphs.transform_p6!(g, nv(g)) == true
        end
    end

    @testset "Should not run" begin
        for g in get_graphs_except_production(:p6)
            @test MeshGraphs.transform_p6!(g, nv(g)) == false
        end
    end

    @testset "Right triangle" begin
        vertices = [1, 2, 3, 4, 5, 6]
        edges = [
            1 4 2 5 3 6
            4 2 5 3 6 1
        ]
        coords = [
            0.0 1.0 0.0 0.5 0.5 0.0
            0.0 0.0 1.0 0.0 0.5 0.5
            0.0 0.0 0.0 0.0 0.0 0.0
        ]
        interior = [1, 2, 3]
        hanging = [
            4 5 6
            1 2 3
            2 3 1
        ]

        @testset "Vertex permutation $(perm)" for perm in permutations(vertices)
            i_perm = interior
            @testset "No boundaries" begin
                boundaries = [false, false, false, false, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries
                )
                @test MeshGraphs.transform_p6!(g, nv(g))
                test_counts(g, 4, 2, 2, 7)
                test_vertex_is_type(g, [0.5, 0.0, 0.0], HANGING)
                test_vertex_is_type(g, [0.0, 0.5, 0.0], HANGING)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
            end
            @testset "Boundary not longest edge" begin
                boundaries = [true, true, false, false, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries
                )
                @test MeshGraphs.transform_p6!(g, nv(g))
                test_counts(g, 4, 2, 2, 7)
                test_vertex_is_type(g, [0.5, 0.0, 0.0], HANGING)
                test_vertex_is_type(g, [0.0, 0.5, 0.0], HANGING)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
            end
            @testset "Boundary longest edge" begin
                boundaries = [false, false, true, true, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries
                )
                @test MeshGraphs.transform_p6!(g, nv(g))
                test_counts(g, 4, 2, 2, 7)
                test_vertex_is_type(g, [0.5, 0.0, 0.0], HANGING)
                test_vertex_is_type(g, [0.0, 0.5, 0.0], HANGING)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
            end
        end
    end
end
