@testset "P4" begin
    @testset "Should run" begin
        for g in get_graphs_for_production(:p4)
            @test MeshGraphs.transform_p4!(g, nv(g)) == true
        end
    end

    @testset "Should not run" begin
        for g in get_graphs_except_production(:p4)
            @test MeshGraphs.transform_p4!(g, nv(g)) == false
        end
    end

    @testset "Right triangle" begin
        vertices = [1, 2, 3, 4, 5]
        edges = [
            1 2 5 3 4
            2 5 3 4 1
        ]
        coords = [
            0.0 1.0 0.0 0.0 0.5
            0.0 0.0 1.0 0.5 0.5
            0.0 0.0 0.0 0.0 0.0
        ]
        interior = [1, 2, 3]
        hanging = [
            4 5
            1 2
            3 3
        ]

        @testset "Vertex permutation $(perm)" for perm in shifted_arrays(vertices)
            i_perm = interior
            @testset "No boundaries" begin
                boundaries = [false, false, false, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                )
                @test MeshGraphs.transform_p4!(g, nv(g))
                test_counts(g, 4, 2, 1, 6)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
                test_vertex_is_type(g, [0.0, 0.5, 0.0], HANGING)
            end
            @testset "Boundary not longest edge" begin
                boundaries = [true, false, false, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                )
                @test MeshGraphs.transform_p4!(g, nv(g))
                test_counts(g, 4, 2, 1, 6)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
                test_vertex_is_type(g, [0.0, 0.5, 0.0], HANGING)
            end
            @testset "Boundary longest edge" begin
                boundaries = [false, true, true, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                )
                @test MeshGraphs.transform_p4!(g, nv(g))
                test_counts(g, 4, 2, 1, 6)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
                test_vertex_is_type(g, [0.0, 0.5, 0.0], HANGING)
            end
        end
    end

    @testset "Isosceles triangle" begin
        vertices = [1, 2, 3, 4, 5]
        edges = [
            1 4 2 5 3
            4 2 5 3 1
        ]
        coords = [
            0.0 2.0 1.0 1.0 1.5
            0.0 0.0 4.0 0.0 2.0
            0.0 0.0 0.0 0.0 0.0
        ]
        interior = [1, 2, 3]
        hanging = [
            4 5
            1 2
            2 3
        ]

        @testset "Vertex permutation $(perm)" for perm in shifted_arrays(vertices)
            i_perm = interior
            @testset "Boundary not longest edge" begin
                boundaries = [true, true, false, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                )
                @test MeshGraphs.transform_p4!(g, nv(g))
                test_counts(g, 4, 2, 1, 6)
                test_vertex_is_type(g, [1.0, 0.0, 0.0], HANGING)
                test_vertex_is_type(g, [1.5, 2.0, 0.0], VERTEX)
            end
            @testset "Boundary longest edge" begin
                boundaries = [false, false, true, true, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                )
                @test MeshGraphs.transform_p4!(g, nv(g))
                test_counts(g, 4, 2, 1, 6)
                test_vertex_is_type(g, [1.0, 0.0, 0.0], HANGING)
                test_vertex_is_type(g, [1.5, 2.0, 0.0], VERTEX)
            end
        end
    end
end
