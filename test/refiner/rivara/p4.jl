@testset "P4" begin
    kwargs = get_default_xyz_kwargs()

    @testset "Should run" begin
        for g in get_graphs_for_production(:p4)
            @test MeshGraphs.transform_p4!(g, nv(g); kwargs...) == true
        end
    end

    @testset "Should not run" begin
        for g in get_graphs_except_production(:p4)
            @test MeshGraphs.transform_p4!(g, nv(g); kwargs...) == false
        end
    end
end
