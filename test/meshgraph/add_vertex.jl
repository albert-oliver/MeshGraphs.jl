@testset "add_vertex!" begin

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
            add_vertex_uve!(g, [1, 2, 3])
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
            add_vertex_uve!(g, [1, 2, 3])
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [1, 2]
            @test get_elevation(g, 1) == 3
        end
    end

    @testset "Custom converter" begin
        @testset "Add xyz" begin
            g = MeshGraph()
            xyz_to_uve(coords) = [4, 5, 6]
            add_vertex_xyz!(g, [1, 2, 3]; xyz_to_uve=xyz_to_uve)
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [4, 5]
            @test get_elevation(g, 1) ==6
        end

        @testset "Add uv" begin
            g = MeshGraph()
            uve_to_xyz(coords) = [1, 2, 3]
            add_vertex_uve!(g, [4, 5, 6]; uve_to_xyz=uve_to_xyz)
            @test xyz(g, 1) == [1, 2, 3]
            @test uv(g, 1) == [4, 5]
            @test get_elevation(g, 1) == 6
        end

        @testset "Wrong converter" begin
            g = MeshGraph()
            converter(coords) = 42
            @test_throws TypeError add_vertex_xyz!(g, [1, 2, 3]; xyz_to_uve=converter)
            @test_throws TypeError add_vertex_uve!(g, [1, 2, 3]; uve_to_xyz=converter)
        end
    end

end
