@testset "P1" begin
    @testset "Should run" begin
        for g in get_graphs_for_production(:p1)
            @test MeshGraphs.transform_p1!(g, nv(g)) == true
        end
    end

    @testset "Should not run" begin
        for g in get_graphs_except_production(:p1)
            @test MeshGraphs.transform_p1!(g, nv(g)) == false
        end
    end

    @testset "Right triangle" begin
        vertices = [1, 2, 3]
        edges = [
            1 2 3
            2 3 1
        ]
        coords = [
            0.0 1.0 0.0
            0.0 0.0 1.0
            0.0 0.0 0.0
        ]
        interior = [1, 2, 3]
        hanging = []

        @testset "Vertex permutation $(perm)" for perm in shifted_arrays(vertices)
            i_perm = interior
            @testset "No boundaries" begin
                boundaries = [false, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                    refine = true,
                )
                @test MeshGraphs.transform_p1!(g, nv(g))
                test_counts(g, 3, 2, 1, 5)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], HANGING)
            end
            @testset "Boundary not longest edge" begin
                boundaries = [true, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                    refine = true,
                )
                @test MeshGraphs.transform_p1!(g, nv(g))
                test_counts(g, 3, 2, 1, 5)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], HANGING)
            end
            @testset "Boundary longest edge" begin
                boundaries = [false, true, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                    refine = true,
                )
                @test MeshGraphs.transform_p1!(g, nv(g))
                test_counts(g, 4, 2, 0, 5)
                test_vertex_is_type(g, [0.5, 0.5, 0.0], VERTEX)
            end
        end
    end

    @testset "Isosceles triangle" begin
        vertices = [1, 2, 3]
        edges = [
            1 2 3
            2 3 1
        ]
        coords = [
            0.0 2.0 1.0
            0.0 0.0 4.0
            0.0 0.0 0.0
        ]
        interior = [1, 2, 3]
        hanging = []

        @testset "Vertex permutation $(perm)" for perm in shifted_arrays(vertices)
            i_perm = interior
            @testset "Boundary not longest edge" begin
                boundaries = [true, false, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                    refine = true,
                )
                @test MeshGraphs.transform_p1!(g, nv(g))
                test_counts(g, 3, 2, 1, 5)
                @test !has_vertex_with_coords(g, [1.0, 0.0, 0.0])
            end
            @testset "Boundary longest edge" begin
                boundaries = [false, true, false]
                g = generate_graph(
                    perm,
                    edges,
                    i_perm,
                    coords,
                    hanging,
                    boundaries;
                    refine = true,
                )
                @test MeshGraphs.transform_p1!(g, nv(g))
                test_counts(g, 4, 2, 0, 5)
                test_vertex_is_type(g, [1.5, 2.0, 0.0], VERTEX)
            end
        end
    end
end
