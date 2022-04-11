@testset "Custom field" begin
    struct FieldSpec <: AbstractSpec
        test_field::Real
    end
    FieldGraph(test_field) = MeshGraph(FieldSpec(test_field))

    @testset "Create graph with custom field" begin
        g = FieldGraph(42)
        @test spec(g).test_field == 42
    end

    @testset "Custom field in convert" begin
        g = FieldGraph(42)
        MeshGraphs.add_vertex_strategy(g::MeshGraph{FieldSpec}) = USE_UVE
        MeshGraphs.convert(g::MeshGraph{FieldSpec}, coords::AbstractVector{<:Real}) =
            [coords[1], coords[2], spec(g).test_field]

        g = FieldGraph(42)
        add_vertex!(g, [1, 2, 3])
        @test uve(g, 1) == [1, 2, 3]
        @test xyz(g, 1) == [1, 2, 42]
    end
end
