@testset verbose = true "add_vertex!" begin

    @testset "Graph properties" begin

        @testset "Add xyz" begin
            g = MeshGraph()
            add_vertex_xyz!(g, [1, 2, 3])
            @test nv(g) == 1
            @test vertex_count(g) == 1
            @test interior_count(g) == 0
            @test MeshGraphs.hanging_count(g) == 0
        end

        @testset "Add uv" begin
            g = MeshGraph()
            add_vertex_uv!(g, [1, 2])
            @test nv(g) == 1
            @test vertex_count(g) == 1
            @test interior_count(g) == 0
            @test MeshGraphs.hanging_count(g) == 0
        end
    end

    @testset "Default converter" begin
        @testset "Add xyz" begin
            g = MeshGraph()
            add_vertex_xyz!(g, [1, 2, 3])
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [1, 2]
            @test get_elevation(g, 1) == 3
        end

        @testset "Add uv" begin
            g = MeshGraph()
            add_vertex_uv!(g, [1, 2])
            @test xyz(g, 1) == [1, 2, 0]
            @test uv(g, 1) == [1, 2]
            @test get_elevation(g, 1) == 0
        end
    end

    @testset "Custom converter" begin
        @testset "Add xyz" begin
            g = MeshGraph()
            xyz_to_elev_uv(coords) = 42, [15, 17]
            add_vertex_xyz!(g, [1, 2, 3]; xyz_to_elev_uv=xyz_to_elev_uv)
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [15, 17]
            @test get_elevation(g, 1) == 42
        end

        @testset "Add uv" begin
            g = MeshGraph()
            uv_to_elev_xyz(coords) = 42, [4, 5, 6]
            add_vertex_uv!(g, [1, 2]; uv_to_elev_xyz=uv_to_elev_xyz)
            @test xyz(g, 1) == [4, 5, 6]
            @test uv(g, 1) == [1, 2]
            @test get_elevation(g, 1) == 42
        end

        @testset "Wrong converter" begin
            g = MeshGraph()
            converter(coords) = [15, 17]
            @test_throws TypeError add_vertex_xyz!(g, [1, 2, 3]; xyz_to_elev_uv=converter)
            @test_throws TypeError add_vertex_uv!(g, [1, 2]; uv_to_elev_xyz=converter)
        end
    end

end
