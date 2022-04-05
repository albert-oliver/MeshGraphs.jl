@testset "P3" begin
    @testset "Should run" begin
        for g in get_graphs_for_production(:p3)
            @test MeshGraphs.transform_p3!(g, nv(g)) == true
        end
    end

    @testset "Should not run" begin
        for g in get_graphs_except_production(:p3)
            @test MeshGraphs.transform_p3!(g, nv(g)) == false
        end
    end
end
