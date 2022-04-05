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
end
