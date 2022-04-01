
function xyz_to_uve(coords)
    u,v,e = coords
    if v >= 4
        v +=6
    end
    return [u, v, e]
end

function get_graph()
    g = MeshGraph()

    add_vertex_xyz!(g, [0.0, 0.0, 0.0]; xyz_to_uve=xyz_to_uve)
    add_vertex_xyz!(g, [0.0, 4.0, 0.0]; xyz_to_uve=xyz_to_uve)
    add_vertex_xyz!(g, [5.0, 3.0, 0.0]; xyz_to_uve=xyz_to_uve)

    add_interior!(g, 1, 2, 3; refine=true)

    add_edge!(g, 1, 2)
    add_edge!(g, 1, 3)
    add_edge!(g, 2, 3; boundary=true)

    return g
end

@testset "refine custom values" begin

    @testset "Longest edge in xyz" begin
        g = get_graph()
        refine_xyz!(g)
        @test interior_count(g) == 2
        @test !has_edge(g, 1, 3)
    end

    @testset "Longest edge in uve" begin
        g = get_graph()
        refine_uve!(g)
        @test interior_count(g) == 2
        @test !has_edge(g, 1, 2)
    end

    @testset "Custom distance in xyz" begin
        g = get_graph()
        distance(g, v1, v2) = abs(xyz(g, v1)[1] - xyz(g, v2)[1])
        refine_uve!(g; distance_fun=distance)
        @test interior_count(g) == 2
        @test !has_edge(g, 2, 3)
    end

    @testset "Custom distance in uve" begin
        g = get_graph()
        distance(g, v1, v2) = abs(uve(g, v1)[2] - uve(g, v2)[2])
        refine_uve!(g; distance_fun=distance)
        @test interior_count(g) == 2
        @test !has_edge(g, 1, 2)
    end

    @testset "Custom coordinates in xyz" begin
        g = get_graph()
        refine_xyz!(g; new_coords_fun=((g, v1, v2) -> [1, 4, 0]))
        @test interior_count(g) == 2
        coords = [xyz(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end

    @testset "Custom coordinates in uve" begin
        g = get_graph()
        refine_uve!(g; new_coords_fun=((g, v1, v2) -> [1, 4, 0]))
        @test interior_count(g) == 2
        coords = [uve(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end

    @testset "Custom converter in xyz" begin
        g = get_graph()
        refine_xyz!(g; xyz_to_uve=((coords) -> [1, 4, 0]))
        @test interior_count(g) == 2
        coords = [uve(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end

    @testset "Custom converter in uve" begin
        g = get_graph()
        refine_uve!(g; uve_to_xyz=((coords) -> [1, 4, 0]))
        @test interior_count(g) == 2
        coords = [xyz(g, v) for v in MeshGraphs.hanging_nodes(g)][1]
        @test [1, 4, 0] == coords
    end
end
