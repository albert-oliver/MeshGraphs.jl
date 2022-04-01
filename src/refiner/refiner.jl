using LinearAlgebra
using Statistics

include("rivara/p1.jl")
include("rivara/p2.jl")
include("rivara/p3.jl")
include("rivara/p4.jl")
include("rivara/p5.jl")
include("rivara/p6.jl")

"""
    run_for_all_triangles!(g, production; log=false, kwargs...)

Run function `production(g, i)` on all interiors `i` of graph `g`
"""
function run_for_all_triangles!(
    g::AbstractMeshGraph,
    production::Function;
    log = false,
    kwargs...,
)::Bool
    ran = false
    for v in interiors(g)
        ex = production(g, v; kwargs...)
        if ex && log
            println("Executed: ", String(Symbol(fun)), " on ", v)
        end
        ran |= ex
    end
    return ran
end

"""
    run_transformations!(g; log=false, kwargs...)

Execute all transformations (P1-P6) on all interiors of graph `g`. Stop when no
more transformations can be executed.

`log` flag tells wheter to log what transformation was executed on which vertex
"""
function refine!(g::AbstractMeshGraph; log=false, kwargs...)
    while true
        ran = false
        ran |= run_for_all_triangles!(g, transform_p1!; log = log, kwargs...)
        ran |= run_for_all_triangles!(g, transform_p2!; log = log, kwargs...)
        ran |= run_for_all_triangles!(g, transform_p3!; log = log, kwargs...)
        ran |= run_for_all_triangles!(g, transform_p4!; log = log, kwargs...)
        ran |= run_for_all_triangles!(g, transform_p5!; log = log, kwargs...)
        ran |= run_for_all_triangles!(g, transform_p6!; log = log, kwargs...)
        if !ran
            return break
        end
    end
end

function refine_xyz!(
    g::AbstractMeshGraph;
    distance_fun::Function = ((g, v1, v2) -> norm(xyz(g, v1) - xyz(g, v2))),
    new_coords_fun::Function = ((g, v1, v2) -> mean([xyz(g, v1), xyz(g, v2)])),
    xyz_to_uve::Function = identity,
    log = false,
)
    refine!(
        g;
        log = log,
        use_uv = false,
        distance_fun = distance_fun,
        new_coords_fun = new_coords_fun,
        converter_fun = xyz_to_uve,
    )
end

function refine_uve!(
    g::AbstractMeshGraph;
    distance_fun::Function = ((g, v1, v2) -> norm(uv(g, v1) - uv(g, v2))),
    new_coords_fun::Function = ((g, v1, v2) -> mean([uve(g, v1), uve(g, v2)])),
    uve_to_xyz::Function = identity,
    log = false,
)
    refine!(
        g;
        log = log,
        use_uv = true,
        distance_fun = distance_fun,
        new_coords_fun = new_coords_fun,
        converter_fun = uve_to_xyz,
    )
end
