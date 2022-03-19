import MetaGraphs; const MG = MetaGraphs
import Graphs; const Gr = Graphs

# -----------------------------------------------------------------------------
# ------ MeshGraph type definition -------------------------------------------
# -----------------------------------------------------------------------------

const VERTEX = 1
const HANGING = 2
const INTERIOR = 3

"""
Abstract type that holds MeshGraph.

In this case MeshGraph represents triangle mesh and is a graph with three
types of vertices:
- `VERTEX` - normal vertex of graph
- `HANGING` - hanging node on edge between two normal vertices, made when breaking triangle on one side of edge
- `INTERIOR` - vertex representing inside of trinagle

Vertices are indexed by integers starting at 1.

Two concrete subtypes of `MeshGraph` are `FlatGraph` and `SphereGraph`.

# Properties of vertex by its type
- `VERTEX`
    - `xyz` - carstesian coordinates of vertex
    - `elevation`- elevation of point above sea level (or below when negative)
    - `uv` - mapping of vertex to flat surface (e.g. latitude, longitude)
    - `value` - custom property of vertex - for instance water
- `HANGING` vertices have same properties as normal vertices, plus:
    - `v1`, `v2`: vertices between which hanging node lies
- `INTERIOR`:
    - `refine::Bool`: whether this traingle should be refined
# Edge properties
- `boundary::Bool` - whether this edge lies on boundary of mesh

See also: [`FlatGraph`](@ref), [`SphereGraph`](@ref)
"""
abstract type MeshGraph end

# -----------------------------------------------------------------------------
# ------ Functions for updating coordinates -----------------------------------
# -----------------------------------------------------------------------------

"Recalculate `xyz` of vertex `v` using `uv` and `elevation`."
function update_xyz! end

"Recalculate `uv` and `elevation` of vertex `v` using `xyz`."
function update_uv_elev! end

validate_xyz(
    g::MeshGraph,
    coords::AbstractVector{<:Real},
)::AbstractVector{<:Real} = coords[1:3]

validate_uv(
    g::MeshGraph,
    coords::AbstractVector{<:Real},
)::AbstractVector{<:Real} = coords[1:2]

validate_elevation(g::MeshGraph, elevation::Real)::Real = elevation

# -----------------------------------------------------------------------------
# ------ Functions for adding and removing vertices and edges -----------------
# -----------------------------------------------------------------------------

"""
    add_vertex!(g, coords; value=0)
    add_vertex!(g, coords, elevation; value=0)

Add new vertex to graph `g`. Return its `id`.

- when `elevation` is not delivered add vertex with coordinates:
    - `x = coords[1]`
    - `y = coords[2]`
    - `z = coords[3]`
    - and calculate `uv` and `elevation`
- when `elevation` is delivered:
    - `u = coords[1]`
    - `v = coords[2]`
    - `elevation = elevation`
    - and calculate `xyz`

## Limitations
### SphereGraph
- `u = lon` can be any real number, is moved to range (-180, 180]
- `v = lay` has to be in range [-90, 90]
"""
function add_vertex! end

function add_vertex!(
    g::MeshGraph,
    coords::AbstractVector{<:Real};
    value::Real = 0.0,
)::Integer
    coords = validate_xyz(g, coords)
    Gr.add_vertex!(g.graph)
    MG.set_prop!(g.graph, nv(g), :type, VERTEX)
    MG.set_prop!(g.graph, nv(g), :value, value)
    MG.set_prop!(g.graph, nv(g), :xyz, coords)
    update_uv_elev!(g, nv(g))
    g.vertex_count += 1
    return nv(g)
end

function add_vertex!(
    g::MeshGraph,
    coords::AbstractVector{<:Real},
    elevation::Real;
    value::Real = 0.0,
)::Integer
    coords = validate_uv(g, coords)
    elevation = validate_elevation(g, elevation)
    Gr.add_vertex!(g.graph)
    MG.set_prop!(g.graph, nv(g), :type, VERTEX)
    MG.set_prop!(g.graph, nv(g), :value, value)
    MG.set_prop!(g.graph, nv(g), :uv, coords)
    MG.set_prop!(g.graph, nv(g), :elevation, elevation)
    update_xyz!(g, nv(g))
    g.vertex_count += 1
    return nv(g)
end

"""
    add_hanging!(g, v1, v2, elevation; value=0)
    add_hanging!(g, v1, v2, coords, elevation; value=0)

Add hanging node between vertices `v1` and `v2`. Return its `id`. Other arguments
are similar to [`add_vertex!`](@ref).

# Note
Only add new vertex with type `hanging`. **No** other changes will be made
(specifically no edges will be added or removed).

See also: [`add_vertex!`](@ref)
"""
function add_hanging! end

function add_hanging!(
    g::MeshGraph,
    v1::Integer,
    v2::Integer,
    coords::AbstractVector{<:Real};
    value::Real = 0.0,
)
    add_vertex!(g, coords; value = value)
    set_hanging!(g, nv(g), v1, v2)
    nv(g)
end

function add_hanging!(
    g::MeshGraph,
    v1::Integer,
    v2::Integer,
    coords::AbstractVector{<:Real},
    elevation::Real;
    value = 0.0,
)
    add_vertex!(g, coords, elevation; value = value)
    set_hanging!(g, nv(g), v1, v2)
    nv(g)
end

"""
    add_interior!(g, v1, v2, v3; refine=false)
    add_interior!(g, vs; refine=false)

Add interior to graph `g` that represents traingle with vertices `v1`, `v2` and
`v3` (or vector `vs = [v1, v2, v3]`). Return its `id`.

# Note
This will **not** create any edges between those vertices. However it will
create edges between new `INTERIOR` vertex and each of the three.
"""
function add_interior! end

function add_interior!(
    g::MeshGraph,
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

function add_interior!(
    g::MeshGraph,
    vs::AbstractVector{<:Real};
    refine::Bool = false,
)
    add_interior!(vs[v1], vs[v2], vs[v3]; refine=refine)
end

"Add edge between vertices `v1` and `v2`."
function add_edge!(
    g::MeshGraph,
    v1::Integer,
    v2::Integer;
    boundary::Bool = false,
)
    Gr.add_edge!(g.graph, v1, v2)
    MG.set_prop!(g.graph, v1, v2, :boundary, boundary)
end

"Remove vertex `v` of any type from graph."
function rem_vertex!(g::MeshGraph, v::Integer)
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
rem_edge!(g::MeshGraph, v1::Integer, v2::Integer) =
    Gr.rem_edge!(g.graph, v1, v2)

# -----------------------------------------------------------------------------
# ------ Functions counting elements fo graph  --------------------------------
# -----------------------------------------------------------------------------

"Number of **all** vertices in graph `g`. Alias: [`nv`](@ref)"
all_vertex_count(g::MeshGraph) = Gr.nv(g.graph)

"Number of **all** vertices in graph `g`. Alias of [`vertex_count`](@ref)"
nv = all_vertex_count

"Number of normal vertices in graph `g`"
vertex_count(g::MeshGraph) = g.vertex_count

"Number of hanging nodes in graph `g`"
hanging_count(g::MeshGraph) = g.hanging_count

"Number of interiors in graph `g`"
interior_count(g::MeshGraph) = g.interior_count

# -----------------------------------------------------------------------------
# ------ Iterators over vertices ----------------------------------------------
# -----------------------------------------------------------------------------

"Return vector of all vertices with type `type`"
function vertices_with_type(g::MeshGraph, type::Integer)
    filter_fun(g, v) = MG.get_prop(g, v, :type) == type
    MG.filter_vertices(g.graph, filter_fun)
end

"Return vector of all vertices with type different from `type`"
function vertices_except_type(g::MeshGraph, type::Integer)
    filter_fun(g, v) = MG.get_prop(g, v, :type) != type
    MG.filter_vertices(g.graph, filter_fun)
end

"Return all vertices with type `VERTEX`"
normal_vertices(g::MeshGraph) = vertices_with_type(g, VERTEX)

"Return all vertices with type `HANGING`"
hanging_nodes(g::MeshGraph) = vertices_with_type(g, HANGING)

"Return all vertices with type `INTERIOR`"
interiors(g::MeshGraph) = vertices_with_type(g, INTERIOR)

"Return neighbors with all types of vertex `v`"
neighbors(g::MeshGraph, v::Integer) = Gr.neighbors(g.graph, v)

"Return neighbors with type `type` of vertex `v`"
function neighbors_with_type(g::MeshGraph, v::Integer, type::Integer)
    filter(u -> MG.get_prop(g.graph, u, :type) == type, neighbors(g, v))
end

"Return neighbors with type different than `type` of vertex `v`"
function neighbors_except_type(g::MeshGraph, v::Integer, type::Integer)
    filter(u -> MG.get_prop(g.graph, u, :type) != type, neighbors(g, v))
end

"Return neighbors with type `vertex` of vertex `v`"
vertex_neighbors(g::MeshGraph, v::Integer) = neighbors_with_type(g, v, VERTEX)

"Return neighbors with type `hanging` of vertex `v`"
hanging_neighbors(g::MeshGraph, v::Integer) =
    neighbors_with_type(g, v, HANGING)

"Return neighbors with type `interior` of vertex `v`"
interior_neighbors(g::MeshGraph, v::Integer) =
    neighbors_with_type(g, v, INTERIOR)

"Return three vertices that make triangle represented by interior `i`"
interiors_vertices(g::MeshGraph, i::Integer) = neighbors(g, i)

"Check if edge between `v1` `v2` is ordinary, that is if it doesn't connect
`INTERIOR` to its vertices."
is_ordinary_edge(g::MeshGraph, v1::Integer, v2::Integer) =
    !is_interior(g, v1) && !is_interior(g, v2)

"Return *all* edges in graph `g` (including possibly edges between interiors
and) its vertices. To get ordinary edges use [`edges`](@ref)."
all_edges(g::MeshGraph) = map(e -> [Gr.src(e), Gr.dst(e)], Gr.edges(g.graph))

"Return oridanry edges in graph `g`. To get all edges use [`all_edges`](@ref)."
function edges(g::MeshGraph)
    filter(e -> is_ordinary_edge(g, e[1], e[2]), all_edges(g))
end

# -----------------------------------------------------------------------------
# ------ Functions handling vertex properties  --------------------------------
# -----------------------------------------------------------------------------

"Change type of vertex `v` to `hanging` from `vertex` and set its 'parents' to
`v1` and `v2`"
function set_hanging!(g::MeshGraph, v::Integer, v1::Integer, v2::Integer)
    if !is_hanging(g, v)
        g.hanging_count += 1
        g.vertex_count -= 1
    end
    MG.set_prop!(g.graph, v, :type, HANGING)
    MG.set_prop!(g.graph, v, :v1, v1)
    MG.set_prop!(g.graph, v, :v2, v2)
end

"Change type of vertex to `vertex` from `hanging`"
function unset_hanging!(g::MeshGraph, v::Integer)
    if !is_hanging(g, v)
        return nothing
    end
    MG.set_prop!(g.graph, v, :type, VERTEX)
    MG.rem_prop!(g.graph, v, :v1)
    MG.rem_prop!(g.graph, v, :v2)
    g.hanging_count -= 1
    g.vertex_count += 1
end

# -----------------------------------------------------------------------------
# ------ Used in mosed functions below ----------------------------------------
# -----------------------------------------------------------------------------

"Return vector with `xyz` coordinates of vertex `v`."
xyz(g::MeshGraph, v::Integer)::Vector{<:Real} = MG.get_prop(g.graph, v, :xyz)

"Return vector with `uv` coordinates of vertex `v`."
uv(g::MeshGraph, v::Integer)::Vector{<:Real} = MG.get_prop(g.graph, v, :uv)

get_type(g::MeshGraph, v::Integer)::Integer = MG.get_prop(g.graph, v, :type)
is_hanging(g::MeshGraph, v::Integer) =
    MG.get_prop(g.graph, v, :type) == HANGING
is_vertex(g::MeshGraph, v::Integer) = MG.get_prop(g.graph, v, :type) == VERTEX
is_interior(g::MeshGraph, v::Integer) =
    MG.get_prop(g.graph, v, :type) == INTERIOR
get_elevation(g::MeshGraph, v::Integer)::Real =
    MG.get_prop(g.graph, v, :elevation)
function set_elevation!(g::MeshGraph, v::Integer, elevation::Real)
    MG.set_prop!(g.graph, v, :elevation, elevation)
    update_xyz!(g, v)
end
get_value(g::MeshGraph, v::Integer)::Real = MG.get_prop(g.graph, v, :value)
set_value!(g::MeshGraph, v::Integer, value::Real) =
    MG.set_prop!(g.graph, v, :value, value)

"Return cartesian coordinates of the point that sits `value` above vertex."
function get_value_cartesian end

"""
    get_all_values(g)

Return vector with values coresponding to `value` property of all vertices
with type `vertex` in graph `g`. Vertices are sorted inascending order based on
their `id`. Mapping between vertex `id` and proper index can be retrieved
using [`vertex_map`](@ref).

See also: [`set_all_values!`](@ref), [`vertex_map`](@ref)
"""
function get_all_values(g::MeshGraph)
    [MG.get_prop(g.graph, v, :value) for v in normal_vertices(g)]
end

"""
    set_all_values!(g, values)

Set `value` property for all vertexes with type `vertex` in graph `g`. Vertex
with smallest `id` will receive value `values[1]`, next one `values[2]` and so
on.

See also: [`set_all_values!`](@ref), [`vertex_map`](@ref)
"""
function set_all_values!(g::MeshGraph, values::AbstractVector{<:Real})
    for (i, v) in enumerate(normal_vertices(g))
        MG.set_prop!(g.graph, v, :value, values[i])
    end
end

should_refine(g::MeshGraph, i::Integer)::Bool =
    MG.get_prop(g.graph, i, :refine)
set_refine!(g::MeshGraph, i::Integer) = MG.set_prop!(g.graph, i, :refine, true)
unset_refine!(g::MeshGraph, i::Integer) =
    MG.set_prop!(g.graph, i, :refine, false)

# -----------------------------------------------------------------------------
# ------ Functions handling edge properties -----------------------------------
# -----------------------------------------------------------------------------

"Is edge between `v1` and `v2` on boundary"
is_on_boundary(g::MeshGraph, v1::Integer, v2::Integer) =
    MG.get_prop(g.graph, v1, v2, :boundary)

set_boundary!(g::MeshGraph, v1::Integer, v2::Integer) =
    MG.set_prop!(g.graph, v1, v2, :boundary, true)
unset_boundary!(g::MeshGraph, v1::Integer, v2::Integer) =
    MG.set_prop!(g.graph, v1, v2, :boundary, true)

"Return length of edge as euclidean distance between cartesian coordiantes of
its vertices"
edge_length(g::MeshGraph, v1::Integer, v2::Integer)::Real =
    norm(xyz(g, v1) - xyz(g, v2))

has_edge(g::MeshGraph, v1::Integer, v2::Integer)::Bool =
    Gr.has_edge(g.graph, v1, v2)

# -----------------------------------------------------------------------------
# ------ Other functions ------------------------------------------------------
# -----------------------------------------------------------------------------

"Whether graph `g` has any hanging nodes"
has_hanging_nodes(g::MeshGraph) = hanging_count(g) != 0

"Get hanging node between normal vertices `v1` and `v2` in graph `g`"
function get_hanging_node_between(g::MeshGraph, v1::Integer, v2::Integer)
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
vertex_map(g::MeshGraph) =
    Dict(v => i for (i, v) in enumerate(vertices_except_type(g, INTERIOR)))

"Scales all coordinates of graph `g` by `scale`. In case of `SphereGraph` also
scales `radius`"
function scale_graph end

include("flatgraph.jl")
include("spheregraph.jl")
