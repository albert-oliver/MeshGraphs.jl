using LinearAlgebra
using Statistics

include("rivara/p1.jl")
include("rivara/p2.jl")
include("rivara/p3.jl")
include("rivara/p4.jl")
include("rivara/p5.jl")
include("rivara/p6.jl")

"""
    run_for_all_triangles!(g, production; log=false)

Run function `production(g, i)` on all interiors `i` of graph `g`

# Keyword arguments
- `log::Bool`
- `use_uv::Bool`
- `distance_fun::Function`
- `new_coords_fun::Function`
- `converter_fun::Function`

"""
function run_for_all_triangles!(
    g::AbstractMeshGraph,
    production::Function;
    log = false,
)::Bool
    ran = false
    for v in interiors(g)
        ex = production(g, v)
        if ex && log
            println("Executed: ", String(Symbol(fun)), " on ", v)
        end
        ran |= ex
    end
    return ran
end

"""
    refine!(g; log=false)

Refine graph `g` by breaking all triangles marked `refine`
([`set_reifne!`](@ref)) and possibly additional ones so that always longest
edge of traingle will be broken. Rivara's longest-edge refinement algorithm
adapted for graph-grammars is used.

# Keyword arguments
- `log::Bool`: whether to log what transformation was executed on which vertex

# Control
Execution can be controlled by providing custom type for graph. For details see
[`MeshGraph`](@ref)

# Implementation
Execute all transformations (P1-P6) on all interiors of graph `g`. Stop when no
more transformations can be executed.
"""
function refine!(g::AbstractMeshGraph; log=false)
    while true
        ran = false
        ran |= run_for_all_triangles!(g, transform_p1!; log = log)
        ran |= run_for_all_triangles!(g, transform_p2!; log = log)
        ran |= run_for_all_triangles!(g, transform_p3!; log = log)
        ran |= run_for_all_triangles!(g, transform_p4!; log = log)
        ran |= run_for_all_triangles!(g, transform_p5!; log = log)
        ran |= run_for_all_triangles!(g, transform_p6!; log = log)
        if !ran
            break
        end
    end
end

"""
    refine_xyz!(g; distance_fun, new_coords_fun, xyz_to_uve, log)

Refine graph `g` by breaking all triangles marked `refine`
([`set_reifne!`](@ref)) and possibly additional ones so that always longest
edge of traingle will be broken. Rivara's longest-edge refinement algorithm
adapted for graph-grammars is used. New vertices will be added using `xyz`
coordinates.

# Keyword arguments
- `log::Bool`: whether to log what transformation was executed on which vertex
- `distance_fun::Function`
- `new_coords_fun::Function`
- `xyz_to_uve::Function`

# Functions details

    distance_fun(g, v1, v2)

Calculate distance between verticves `v1` and `v2` in graph `g`. Longest edge
according to that distance will always be broken. Defaults to Euclidean distance.

    new_coords_fun(g, v1, v2)

Calculate coordinates of vertex created when breaking edge based on neighbors
(two vertices previously connected with now broken edge). Return `[x, y, z]`
of new vertex. Defaults to average of `v1` and `v2`, `xyz` coordinates.

    xyz_to_uve(coords)

See [`add_vertex_xyz`](@ref)

See also: [`refine_uve!`](@ref)
"""
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

"""
    refine_uve!(g; distance_fun, new_coords_fun, uve_to_xyz, log)

Refine graph `g` by breaking all triangles marked `refine`
([`set_reifne!`](@ref)) and possibly additional ones so that always longest
edge of traingle will be broken. Rivara's longest-edge refinement algorithm
adapted for graph-grammars is used. New vertices will be added using `uv`
coordinates and `elevation` ([`uve`](@ref)).

# Keyword arguments
- `log::Bool`: whether to log what transformation was executed on which vertex
- `distance_fun::Function`
- `new_coords_fun::Function`
- `uve_to_xyz::Function`

# Functions details

    distance_fun(g, v1, v2)

Calculate distance between verticves `v1` and `v2` in graph `g`. Longest edge
according to that distance will always be broken. Defaults to Euclidean
distance of `uv` coordinates (without `elevation`).

    new_coords_fun(g, v1, v2)

Calculate coordinates of vertex created when breaking edge based on neighbors
(two vertices previously connected with now broken edge). Return
`[u, v, elevation]` of new vertex. Defaults to average of `v1` and `v2`, `uve`
coordinates.

    uve_to_xyz(coords)

See [`add_vertex_uve`](@ref)

See also: [`refine_xyz!`](@ref)
"""
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
