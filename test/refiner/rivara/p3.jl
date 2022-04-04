@testset "P3" begin
    kwargs = get_default_xyz_kwargs()

    @testset "Should run" begin
        for g in get_graphs_for_production(:p3)
            @test MeshGraphs.transform_p3!(g, nv(g); kwargs...) == true
        end
    end

    @testset "Should not run" begin
        for g in get_graphs_except_production(:p3)
            @test MeshGraphs.transform_p3!(g, nv(g); kwargs...) == false
        end
    end
end
