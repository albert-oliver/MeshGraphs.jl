import Graphs; const Gr = Graphs
import MetaGraphs; const MG = MetaGraphs
import Base: show
using LinearAlgebra

# -----------------------------------------------------------------------------
# ------ FlatGraph type definition and constructors ---------------------------
# -----------------------------------------------------------------------------

"""
`FlatGraph` is a `MeshGraph` whose vertices are on flat surface but can be
moved up and down with `elevation` property.

Can represent samll part Earth's surface, where curvature is negligible.

# Verticex properties
All properties are the same as in `MeshGraph` except for the following:
- `VERTEX` type vertices:
    - `xyz` - cartesian coordinates of vertex (include elvation as `xyz[3]`)
    - `value` - custom property of vertex - for instance water

See also: [`MeshGraph`](@ref)
"""
mutable struct FlatGraph <: MeshGraph
    graph::MG.MetaGraph
    vertex_count::Integer
    interior_count::Integer
    hanging_count::Integer
    xy_to_uv::Function
    uv_to_xy::Function
end

function FlatGraph(xy_to_uv::Function, uv_to_xy::Function)
    graph = MG.MetaGraph()
    FlatGraph(graph, 0, 0, 0, xy_to_uv, uv_to_xy)
end

function FlatGraph()
    xy_to_uv = coords -> coords
    uv_to_xy = coords -> coords
    FlatGraph(identity, identity)
end

function show(io::IO, g::FlatGraph)
    vs = g.vertex_count
    ins = g.interior_count
    hs = g.hanging_count
    es = length(edges(g))
    print(
        io,
        "FlatGraph with ($(vs) vertices), ($(ins) interiors), ($(hs) hanging nodes) and ($(es) edges)",
    )
end

# -----------------------------------------------------------------------------
# ------ Methods for MeshGraph functions --------------------------------------
# -----------------------------------------------------------------------------

function update_xyz!(g::FlatGraph, v::Integer)
    uv_coords = uv(g, v)
    elevation = get_elevation(g, v)
    x, y = g.uv_to_xy(uv_coords)
    MG.set_prop!(g.graph, v, :xyz, [x, y, elevation])
end

function update_uv_elev!(g::FlatGraph, v::Integer)
    xyz_coords = xyz(g, v)
    uv_coords = g.xy_to_uv(xyz_coords[1:2])
    elevation = xyz_coords[3]
    MG.set_prop!(g.graph, v, :elevation, elevation)
    MG.set_prop!(g.graph, v, :uv, uv_coords)
end

get_value_cartesian(g::FlatGraph, v::Integer) =
    xyz(g, v) + [0, 0, get_value(g, v)]

function scale_graph(g::FlatGraph, scale::Real)
    for v in normal_vertices(g)
        new_xyz = xyz(g, v) * scale
        MG.set_prop!(g.graph, v, :xyz, new_xyz)
    end
    xy_to_uv = g.xy_to_uv
    g.xy_to_uv = coords -> xy_to_uv / scale
    uv_to_xy = g.uv_to_xy
    g.uv_to_xy = coords -> uv_to_xy * scale
end
