import MetaGraphs; const MG = MetaGraphs
import Graphs; const Gr = Graphs
using LinearAlgebra
using Statistics

# -----------------------------------------------------------------------------
# ------ MeshGraph type definition -------------------------------------------
# -----------------------------------------------------------------------------

const VERTEX = 1
const HANGING = 2
const INTERIOR = 3

abstract type AbstractMeshGraph end

"""
Graph specialization subtype it type to create graphs with custom fields.
For details see: [`MeshGraph`](@ref)
"""
abstract type AbstractSpec end

@enum AddVertexStrategy USE_UVE USE_XYZ

"""
    mutable struct MeshGraph{T <: AbstractSpec} <: AbstractMeshGraph

Paramteric type that holds `MeshGraph` subtype of abstract `AbstractMeshGraph`.
`spec::T` field holds graph specialization and can be used to create custom
types, see below.

MeshGraph is a hypergraph representing triangle mesh and has two types of
vertices:
- `VERTEX` - normal vertex of graph
- `HANGING` - whether vertex is hanging node - used during refinement, final graph will not have those
- `INTERIOR` - vertex representing inside of triangle

Vertices are indexed by integers starting at 1.

# Properties of vertex by its type
- `VERTEX`
    - `xyz` - carstesian coordinates of vertex
    - `elevation`- elevation of point above sea level (or below when negative)
    - `uv` - mapping of vertex to flat surface (e.g. latitude, longitude)
- `HANGING`
    - all properties of `VERTEX` plus
    - `v1`, `v2` - hanging node lies between vertices `v1` and `v2`
- `INTERIOR`:
    - `refine::Bool`: whether this traingle should be refined

# Edge properties
- `boundary::Bool` - whether this edge lies on boundary of mesh

# Simple usage
1. Create `SimpleGraph` graph
2. Mark trainagles that needs to be refined
3. Use [`refine!`](@ref) to break all the marked triangles
4. Go to (2.)

# Refiner properties
Properties of refiner that can be adjusted:
- Which coordinates are used during refinement: [`uve`](@ref) or [`xyz`](@ref)
- How to convert from [`uve`](@ref) to [`xyz`](@ref) (or the other way around)
- How to calculate coordinates of new vertex based on its neighbors
- How to calculate distance between two vertices - longest edge will be broken

All of those can be controlled by implementing metohds for following functions:
- [`add_vertex_strategy`](@ref)
- [`convert`](@ref)
- [`distance`](@ref)
- [`new_vertex_coords`](@ref)

# Custom types
To easiest way to create custom graph type using `MeshGraph` is the following:

- Create custom graph specialization as subytpe of [`AbstractSpec`](@ref)
```
struct MySpec <: AbstractSpec
    my_field::Integer
end
```

- Create alias for `MeshGraph` with your specialization as parameter
```
const MyGraph = MeshGraph{MySpec}
```

- Create custom constructor for your type
```
MyGraph(my_field) = MyGraph(MySpec(my_field))
```

- Implement all the function, whose behaviour you want to adjust:

- Using which coordinates new vertices will be added
```
MeshGraphs.add_vertex_strategy(g::MyGraph) = USE_UVE
```

- How to convert from `uve` to `xyz` (in our case, if we had used `USE_XYZ`, it would be reversed)
```
MeshGraphs.convert(g::MyGraph, coords::AbstractVector{<:Real}) =
    [coords[1], coords[2], spec(g).my_field]
#
# Here we always set `z` and to custom field of out graph (`my_field`)
```

- How to calculate distance used in refinement
```
function MeshGraphs.distance(g::MyGraph, v1::Integer, v2::Integer)
    coords1 = xyz(g, v1)[1:2]
    coords2 = xyz(g, v2)[1:2]
    return norm(coords1 - coords2)
end
# Here we calculate Euclidean distance igonoring `z` coordiante
```

- Have fun

# Note
- In order to create method for `MeshGraphs` functions you have to explicitly
write that in front of function name
- All types should be **exactly** as in original definition (except for `g`)

See also: [`refine_xyz!`](@ref), [`refine_uve!`](@ref)
"""
mutable struct MeshGraph{T <: AbstractSpec} <: AbstractMeshGraph
    spec::T
    graph::MG.MetaGraph
    vertex_count::Integer
    interior_count::Integer
    hanging_count::Integer

    MeshGraph(spec::T) where T <: AbstractSpec = new{T}(spec, MG.MetaGraph(), 0, 0, 0)
end

function Base.show(io::IO, g::AbstractMeshGraph)
    vs = g.vertex_count
    ins = g.interior_count
    es = length(edges(g))
    type = typeof(g)
    print(
        io,
        "$(type) with ($(vs) vertices), ($(ins) interiors) and ($(es) edges)",
    )
end

# -----------------------------------------------------------------------------
# ------ To implement ---------------------------------------------------------
# -----------------------------------------------------------------------------


"""
    add_vertex_strategy(g)

What coordinates are used when new vertex is added - [`uve`](@ref) or
[`xyz`](@ref). Return enum [`AddVertexStrategy`](@ref) - either `USE_XYZ` or
`USE_UVE`.

# Note
Shifts behaviour of [`add_vertex!`](@ref) and [`refine!`](@ref).

Method taking parameterized `MeshGraph` can be created to adjust it to your
needs.
"""
function add_vertex_strategy end

"""
    convert(g, coords)

Convert 3-element vector coords` from `uve` to `xyz` (or reverse).

- If [`add_vertex_strategy`](@ref) returns `USE_UVE` new vertex will be created
using `uve` coordinates and then converted to `xyz` using this function.
- If `USE_XYZ` is returned, it will go the other way around.

Defaults to identity.

# Note
Shifts behaviour of [`add_vertex!`](@ref) and [`refine!`](@ref)

Method taking parameterized `MeshGraph` can be created to adjust it to your
needs.
"""
function convert end

"""
    distance(g, v1, v2)

Calculate distance between verticves `v1` and `v2` in graph `g`. Longest edge
according to that distance will always be broken. Defaults to Euclidean
distance of `xyz` or `uve` coordinates
(depending on [`add_vertex_strategy`](@ref)).

# Note
Shifts behaviour of [`refine!`](@ref)

Method taking parameterized `MeshGraph` can be created to adjust it to your
needs.
"""
function distance end

"""
    new_vertex_coords(g, v1, v2)

Calculate coordinates of vertex created when breaking edge based on neighbors
(two vertices previously connected with now broken edge). Return
voords of new vertex (as 3-elemnt Vector).
Defaults to average of `v1` and `v2`, coordinates.

# Note
Shifts behaviour of [`refine!`](@ref)

Method taking parameterized `MeshGraph` can be created to adjust it to your
needs.
"""
function new_vertex_coords end

# -----------------------------------------------------------------------------
# ------ Default implementation------------------------------------------------
# -----------------------------------------------------------------------------

function add_vertex_strategy(g::AbstractMeshGraph)::AddVertexStrategy
    return USE_UVE
end

function convert(g::AbstractMeshGraph, coords::AbstractVector{<:Real})::AbstractVector{<:Real}
     return coords
end

function distance(g::AbstractMeshGraph, v1::Integer, v2::Integer)::Real
    return norm(xyz(g, v1) - xyz(g, v2))
end

function new_vertex_coords(g::AbstractMeshGraph, v1::Integer, v2::Integer)::AbstractVector{<:Real}
    if  add_vertex_strategy(g) == USE_UVE
        return mean([xyz(g, v1), xyz(g, v2)])
    else
        return mean([uve(g, v1), uve(g, v2)])
    end
end

# -----------------------------------------------------------------------------
# ------ Functions for adding and removing vertices and edges -----------------
# -----------------------------------------------------------------------------

"""
    add_vertex!(g, coords)

Add new vertex to graph `g`. Coords used (`xyz` or `uve`) depend on
[`add_vertex_strategy`](@ref). Conversion from one to another is done using
[`convert`](@ref).
"""
function add_vertex!(
    g::AbstractMeshGraph,
    coords::AbstractVector{<:Real}
)::Integer
    Gr.add_vertex!(g.graph)
    MG.set_prop!(g.graph, nv(g), :type, VERTEX)
    converted_coords =
        convert(g, coords)::AbstractVector{<:Real}
    use_uv = add_vertex_strategy(g) == USE_UVE
    xyz_coords, uv_coords =
        use_uv ? (converted_coords, coords) : (coords, converted_coords)
    MG.set_prop!(g.graph, nv(g), :uv, uv_coords[1:2])
    MG.set_prop!(g.graph, nv(g), :elevation, uv_coords[3])
    MG.set_prop!(g.graph, nv(g), :xyz, xyz_coords)
    g.vertex_count += 1
    return nv(g)
end

"""
    add_hanging!(g, v1, v2, coords)

Add hanging node between vertices `v1` and `v2`. Return its `id`. Other arguments
are similar to [`add_vertex!`](@ref).

# Note
Only add new vertex with type `hanging`. **No** other changes will be made
(specifically no edges will be added or removed).

See also: [`add_vertex!`](@ref)
"""
function add_hanging!(
    g::AbstractMeshGraph,
    coords::AbstractVector{<:Real},
    v1::Integer,
    v2::Integer,
)
    add_vertex!(g, coords)
    set_hanging!(g, nv(g), v1, v2)
    nv(g)
end

"Add interior without edges connecting vertices `v1`, `v2`, `v3`"
function add_pure_interior!(
    g::AbstractMeshGraph,
    v1::Integer,
    v2::Integer,
    v3::Integer;
    refine::Bool = false,
)
    Gr.add_vertex!(g.graph)
    MG.set_prop!(g.graph, nv(g), :type, INTERIOR)
    MG.set_prop!(g.graph, nv(g), :refine, refine)
    Gr.add_edge!(g.graph, nv(g), v1)
    Gr.add_edge!(g.graph, nv(g), v2)
    Gr.add_edge!(g.graph, nv(g), v3)
    g.interior_count += 1
    return nv(g)
end

"""
    add_interior!(g, v1, v2, v3; refine=false)
    add_interior!(g, vs; refine=false)

Add interior to graph `g` that represents traingle with vertices `v1`, `v2` and
`v3` (or vector `vs = [v1, v2, v3]`). Return its `id`.

# Note
This **will** create edges between those vertices, as well as edges
between new `INTERIOR` vertex and each of the three.
"""
function add_interior! end

function add_interior!(
    g::AbstractMeshGraph,
    v1::Integer,
    v2::Integer,
    v3::Integer;
    refine::Bool = false,
)
    v = add_pure_interior!(g, v1, v2, v3; refine=refine)
    add_edge!(g, v1, v2)
    add_edge!(g, v2, v3)
    add_edge!(g, v3, v1)
    return v
end

function add_interior!(
    g::AbstractMeshGraph,
    vs::AbstractVector{<:Real};
    refine::Bool = false,
)
    add_interior!(g, vs[1], vs[2], vs[3]; refine=refine)
end

"Add edge between vertices `v1` and `v2`. Set `boundary` flag if delivered."
function add_edge!(
    g::AbstractMeshGraph,
    v1::Integer,
    v2::Integer;
    boundary::Bool = false,
)
    result = Gr.add_edge!(g.graph, v1, v2)
    if result
        MG.set_prop!(g.graph, v1, v2, :boundary, boundary)
    end
    return nothing
end

"Remove vertex `v` of any type from graph."
function rem_vertex!(g::AbstractMeshGraph, v::Integer)
    if is_vertex(g, v)
        g.vertex_count -= 1
    elseif is_hanging(g, v)
        g.hanging_count -= 1
    else
        g.interior_count -= 1
    end
    Gr.rem_vertex!(g.graph, v)
end

"Remove edge from `v1` to `v2` from graph."
rem_edge!(g::AbstractMeshGraph, v1::Integer, v2::Integer) =
    Gr.rem_edge!(g.graph, v1, v2)

# -----------------------------------------------------------------------------
# ------ Functions counting elements fo graph  --------------------------------
# -----------------------------------------------------------------------------

"Return graph specialization"
spec(g::AbstractMeshGraph)::AbstractSpec = g.spec

"Number of **all** vertices in graph `g`. Alias: [`nv`](@ref)"
all_vertex_count(g::AbstractMeshGraph) = Gr.nv(g.graph)

"Number of **all** vertices in graph `g`. Alias of [`vertex_count`](@ref)"
const nv = all_vertex_count

"Number of normal vertices in graph `g`"
vertex_count(g::AbstractMeshGraph) = g.vertex_count

"Number of hanging nodes in graph `g`"
hanging_count(g::AbstractMeshGraph) = g.hanging_count

"Number of interiors in graph `g`"
interior_count(g::AbstractMeshGraph) = g.interior_count

# -----------------------------------------------------------------------------
# ------ Iterators over vertices ----------------------------------------------
# -----------------------------------------------------------------------------

"Return vector of all vertices with type `type`"
function vertices_with_type(g::AbstractMeshGraph, type::Integer)
    filter_fun(g, v) = MG.get_prop(g, v, :type) == type
    MG.filter_vertices(g.graph, filter_fun)
end

"Return vector of all vertices with type different from `type`"
function vertices_except_type(g::AbstractMeshGraph, type::Integer)
    filter_fun(g, v) = MG.get_prop(g, v, :type) != type
    MG.filter_vertices(g.graph, filter_fun)
end

"Return all vertices with type `VERTEX`"
normal_vertices(g::AbstractMeshGraph) = vertices_with_type(g, VERTEX)

"Return all vertices with type `HANGING`"
hanging_nodes(g::AbstractMeshGraph) = vertices_with_type(g, HANGING)

"Return all vertices with type `INTERIOR`"
interiors(g::AbstractMeshGraph) = vertices_with_type(g, INTERIOR)

"Return neighbors with all types of vertex `v`"
neighbors(g::AbstractMeshGraph, v::Integer) = Gr.neighbors(g.graph, v)

"Return neighbors with type `type` of vertex `v`"
function neighbors_with_type(g::AbstractMeshGraph, v::Integer, type::Integer)
    filter(u -> MG.get_prop(g.graph, u, :type) == type, neighbors(g, v))
end

"Return neighbors with type different than `type` of vertex `v`"
function neighbors_except_type(g::AbstractMeshGraph, v::Integer, type::Integer)
    filter(u -> MG.get_prop(g.graph, u, :type) != type, neighbors(g, v))
end

"Return neighbors with type `vertex` of vertex `v`"
vertex_neighbors(g::AbstractMeshGraph, v::Integer) = neighbors_with_type(g, v, VERTEX)

"Return neighbors with type `hanging` of vertex `v`"
hanging_neighbors(g::AbstractMeshGraph, v::Integer) =
    neighbors_with_type(g, v, HANGING)

"Return neighbors with type `interior` of vertex `v`"
interior_neighbors(g::AbstractMeshGraph, v::Integer) =
    neighbors_with_type(g, v, INTERIOR)

"Return three vertices that make triangle represented by interior `i`"
interior_connectivity(g::AbstractMeshGraph, i::Integer) = neighbors(g, i)

"Check if edge between `v1` `v2` is ordinary, that is if it doesn't connect
`INTERIOR` to its vertices."
is_ordinary_edge(g::AbstractMeshGraph, v1::Integer, v2::Integer) =
    !is_interior(g, v1) && !is_interior(g, v2)

"Return *all* edges in graph `g` (including possibly edges between interiors
and) its vertices. To get ordinary edges use [`edges`](@ref)."
all_edges(g::AbstractMeshGraph) = map(e -> [Gr.src(e), Gr.dst(e)], Gr.edges(g.graph))

"Return oridanry edges in graph `g`. To get all edges use [`all_edges`](@ref)."
function edges(g::AbstractMeshGraph)
    filter(e -> is_ordinary_edge(g, e[1], e[2]), all_edges(g))
end

# -----------------------------------------------------------------------------
# ------ Functions handling vertex properties  --------------------------------
# -----------------------------------------------------------------------------

"Change type of vertex `v` to `hanging` from `vertex` and set its 'parents' to
`v1` and `v2`"
function set_hanging!(g::AbstractMeshGraph, v::Integer, v1::Integer, v2::Integer)
    if !is_hanging(g, v)
        g.hanging_count += 1
        g.vertex_count -= 1
    end
    MG.set_prop!(g.graph, v, :type, HANGING)
    MG.set_prop!(g.graph, v, :v1, v1)
    MG.set_prop!(g.graph, v, :v2, v2)
end

"Change type of vertex to `vertex` from `hanging`"
function unset_hanging!(g::AbstractMeshGraph, v::Integer)
    if !is_hanging(g, v)
        return nothing
    end
    MG.set_prop!(g.graph, v, :type, VERTEX)
    MG.rem_prop!(g.graph, v, :v1)
    MG.rem_prop!(g.graph, v, :v2)
    g.hanging_count -= 1
    g.vertex_count += 1
end

"Return vector with `xyz` coordinates of vertex `v`"
xyz(g::AbstractMeshGraph, v::Integer)::Vector{<:Real} =
    MG.get_prop(g.graph, v, :xyz)

"Return vector with `uv` coordinates of vertex `v`"
uv(g::AbstractMeshGraph, v::Integer)::Vector{<:Real} =
    MG.get_prop(g.graph, v, :uv)

"Return vector `[u, v, elevation]`"
uve(g::AbstractMeshGraph, v::Integer)::Vector{<:Real} =
    vcat(uv(g, v), get_elevation(g, v))

get_type(g::AbstractMeshGraph, v::Integer)::Integer =
    MG.get_prop(g.graph, v, :type)

is_hanging(g::AbstractMeshGraph, v::Integer) =
    MG.get_prop(g.graph, v, :type) == HANGING

is_vertex(g::AbstractMeshGraph, v::Integer) =
    MG.get_prop(g.graph, v, :type) == VERTEX

is_interior(g::AbstractMeshGraph, v::Integer) =
    MG.get_prop(g.graph, v, :type) == INTERIOR

get_elevation(g::AbstractMeshGraph, v::Integer)::Real =
    MG.get_prop(g.graph, v, :elevation)

function set_elevation!(g::AbstractMeshGraph, v::Integer, elevation::Real)
    MG.set_prop!(g.graph, v, :elevation, elevation)
end

should_refine(g::AbstractMeshGraph, i::Integer)::Bool =
    MG.get_prop(g.graph, i, :refine)

set_refine!(g::AbstractMeshGraph, i::Integer) =
    MG.set_prop!(g.graph, i, :refine, true)

unset_refine!(g::AbstractMeshGraph, i::Integer) =
    MG.set_prop!(g.graph, i, :refine, false)

# -----------------------------------------------------------------------------
# ------ Functions handling edge properties -----------------------------------
# -----------------------------------------------------------------------------

"Is edge between `v1` and `v2` on boundary"
is_on_boundary(g::AbstractMeshGraph, v1::Integer, v2::Integer) =
    MG.get_prop(g.graph, v1, v2, :boundary)

set_boundary!(g::AbstractMeshGraph, v1::Integer, v2::Integer) =
    MG.set_prop!(g.graph, v1, v2, :boundary, true)

unset_boundary!(g::AbstractMeshGraph, v1::Integer, v2::Integer) =
    MG.set_prop!(g.graph, v1, v2, :boundary, false)

"Return length of edge as euclidean distance between cartesian coordiantes of
its vertices"
edge_length(g::AbstractMeshGraph, v1::Integer, v2::Integer)::Real =
    norm(xyz(g, v1) - xyz(g, v2))

has_edge(g::AbstractMeshGraph, v1::Integer, v2::Integer)::Bool =
    Gr.has_edge(g.graph, v1, v2)

# -----------------------------------------------------------------------------
# ------ Other functions ------------------------------------------------------
# -----------------------------------------------------------------------------

"Whether graph `g` has any hanging nodes"
has_hanging_nodes(g::AbstractMeshGraph) = hanging_count(g) != 0

"Get hanging node between normal vertices `v1` and `v2` in graph `g`"
function get_hanging_node_between(g::AbstractMeshGraph, v1::Integer, v2::Integer)
    if Gr.has_edge(g.graph, v1, v2)
        return nothing
    end
    hnodes1 = filter(v -> is_hanging(g, v), neighbors(g, v1))
    hnodes2 = filter(v -> is_hanging(g, v), neighbors(g, v2))
    hnodes_all = intersect(hnodes1, hnodes2)

    for h in hnodes_all
        h_is_between = [MG.get_prop(g.graph, h, :v1), MG.get_prop(g.graph, h, :v2)]
        if v1 in h_is_between && v2 in h_is_between
            return h
        end
    end

    return nothing
end

"""
    vertex_map(g)

Return dictionary that maps id's of all vertices with type `vertex` or `hanging`
to number starting at 1.

# Note
Removing vertices from graph **will** make previously generated mapping
deprecated.
"""
vertex_map(g::AbstractMeshGraph) =
    Dict(v => i for (i, v) in enumerate(vertices_except_type(g, INTERIOR)))
