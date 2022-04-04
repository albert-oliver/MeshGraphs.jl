using MeshGraphs
using Test
using Statistics
using LinearAlgebra

@testset verbose=true "MeshGraphs" begin
    include("meshgraph/meshgraph.jl")
    include("refiner/refiner.jl")
end
