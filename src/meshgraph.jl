import MetaGraphs; const MG = MetaGraphs
import Graphs; const Gr = Graphs

# -----------------------------------------------------------------------------
# ------ MeshGraph type definition -------------------------------------------
# -----------------------------------------------------------------------------

const VERTEX = 1
const HANGING = 2
const INTERIOR = 3

abstract type AbstractMeshGraph end

"""
Type that holds `MeshGraph` subtype of abstract `AbstractMeshGraph`.

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
1. Create initial graph
2. Mark trainagles that needs to be refined
3. Use [`refine_xyz!`](@ref) / [`refine_uve!`](@ref) function to break all the marked triangles
4. Go to (2.)

# Refiner properties
Properties of refiner that can be adjusted:
- Which coordinates are used during refinement: `uv` or `xyz`
- How to convert from `uv` and to `elevation` and `xyz`
- How to convert from `xyz` to `elevation` and `uv`
- How to calculate distance between two vertices - longest edge will be broken

To choose coordinates of new vertex one has to use:
- [`add_vertex_xyz!`] and [`refine_using_xyz!`] - for `xyz`
- [`add_vertex_uve!`] and [`refine_using_uv!`] - for `xyz`

Conversion is done using functions passed as an argument to functions above. For
details see their documentation.

# Custom types
To easiest way to create custom graph type using `MeshGraph` is the following:

- Create custom struct with custom fields and `MeshGraph` as one of them
```
struct Mygraph
    g::MeshGraph
    my_field::Integer
end
```

- Choose the way refiner will adds new vertices - using `uv` or `xyz`. We will choocs `uv` here.

- Implement functions to shift refiner to your needs, so the tow following:

- Coordinate converter
```
uv_to_elev_xyz(coords) = 42, [coords[1], coords[2], 42]
#                        /\\              /\\
#                    elevation       xyz coords
# Here we always set `elevation` and `z` to 42
```

- And distance function
```
function refine_distance(g, v1, v2)
    coords1 = xyz(g, v1)[1:2]
    coords2 = xyz(g, v2)[1:2]
    return norm(coords1 - coords2)
end
# Here we calculate Euclidean distance igonoring `z` coordiante
```

- Implement custom `add_vertex!`
```
add_vertex!(g::MyGraph, coords) =
    add_vertex_uve!(g, coords; uv_to_elev_xyz=uv_to_elev_xyz)
```

- Implement custom `refine!`
```
refine!(g::MyGraph) =
    refine_uve!(g, uv_to_elev_xyz=uv_to_elev_xyz, refine_distance=refine_distance)
```

- Have fun

# Note
When creating custom type is might be useful to use `@forward` from
`ReusePatterns.jl`:
```
@forward((MyGraph, :g), MeshGraph)
```

So that all functions for `MeshGraph` are also available for `MyGraph`, instead
accessing field all the time.
"""
mutable struct MeshGraph <: AbstractMeshGraph
    graph::MG.MetaGraph
    vertex_count::Integer
    interior_count::Integer
    hanging_count::Integer

    MeshGraph() = new(MG.MetaGraph(), 0, 0, 0)
end

function show(io::IO, g::MeshGraph)
    vs = g.vertex_count
    ins = g.interior_count
    es = length(edges(g))
    print(
        io,
        "MeshGraph with ($(vs) vertices), ($(ins) interiors) and ($(es) edges)",
    )
end

# -----------------------------------------------------------------------------
# ------ Functions for adding and removing vertices and edges -----------------
# -----------------------------------------------------------------------------

"""
    add_vertex_uve!(g, coords; uve_to_xyz)

Add new vertex with `[u, v, elevation]` coords `coords` to graph `g`. Calculate
`xyz`. Return its `id`.

# Arguments:
- `g::AbstractMeshGraph`: Graph where the vertex will be added
- `coords::AbstractVector{<:Real}`: `[u, v, elevation]` coordinates of new vertex
- `uv_to_elev_xyz::Function`

Where:
    uve_to_xyz(coords)

Calculate `xyz` based on `uv` coordinates and `elevation` (`coords`).
Return `(elevation::Real, xyz::Vector)`. Defaults to:
- `x = u`
- `y = v`
- `z = elevation`

See also [`add_vertex_xyz!`](@ref)
"""
add_vertex_uve!(
    g::AbstractMeshGraph,
    coords::AbstractVector{<:Real};
    uve_to_xyz::Function = identity,
)::Integer = add_vertex!(g, coords, true, uve_to_xyz)

"""
    add_vertex_xyz!(g, coords; xyz_to_uve)

Add new vertex with `xyz` coords `coords` to graph `g`. Calculate `uv` and
`elevation`. Return its `id`.

# Arguments:
- `g::AbstractMeshGraph`: Graph where the vertex will be added
- `coords::AbstractVector{<:Real}`: `xyz` coordinates of new vertex
- `xyz_to_uve::Function`

Where:
    xyz_to_uve(coords)

Calculate `elevation` and `uv` based on `xyz` coordinates (`coords`).
Return `[u, v, elevation]` vector. Defaults to:
- `u = x`
- `v = y`
- `elevation = z`

See also [`add_vertex_uve!`](@ref)
"""
add_vertex_xyz!(
    g::AbstractMeshGraph,
    coords::AbstractVector{<:Real};
    xyz_to_uve::Function = identity,
)::Integer = add_vertex!(g, coords, false, xyz_to_uve)

"""
    add_vertex!(g, coords, use_uv, convert_fun)

Add new vertex with to graph `g`.

If flag `use_uv` is set:
- Add vertex with `xyz` coordinates `coords`
- Calculate `elevation` and `uv` using `convert_fun` function
Else:
- Add vertex with `uv` coordinates `coords`
- Calculate `elevation` and `xyz` using `convert_fun` function

For details see [`add_vertex_uve!`](@ref), [`add_vertex_xyz!`](@ref)
"""
function add_vertex!(
    g::AbstractMeshGraph,
    coords::AbstractVector{<:Real},
    use_uv::Bool,
    convert_fun::Function,
)::Integer
    Gr.add_vertex!(g.graph)
    MG.set_prop!(g.graph, nv(g), :type, VERTEX)
    converted_coords =
        convert_fun(coords)::AbstractVector{<:Real}
    xyz_coords, uv_coords =
        use_uv ? (converted_coords, coords) : (coords, converted_coords)
    MG.set_prop!(g.graph, nv(g), :uv, uv_coords[1:2])
    MG.set_prop!(g.graph, nv(g), :elevation, uv_coords[3])
    MG.set_prop!(g.graph, nv(g), :xyz, xyz_coords)
    g.vertex_count += 1
    return nv(g)
end

"""
    add_hanging!(g, v1, v2, coords, convert_fun)

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
    use_uv::Bool,
    convert_fun::Function,
)
    add_vertex!(g, coords, use_uv, convert_fun)
    set_hanging!(g, nv(g), v1, v2)
    nv(g)
end

function add_hanging_xyz!(g::AbstractMeshGraph,
    coords::AbstractVector{<:Real},
    v1::Integer,
    v2::Integer;
    xyz_to_uve::Function = identity,
)
    add_hanging!(g, coords, v1, v2, false, xyz_to_uve)
end


function add_hanging_uve!(g::AbstractMeshGraph,
    coords::AbstractVector{<:Real},
    v1::Integer,
    v2::Integer;
    uve_to_xyz::Function = identity,
)
    add_hanging!(g, coords, v1, v2, true, uve_to_xyz)
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

function add_interior!(
    g::AbstractMeshGraph,
    vs::AbstractVector{<:Real};
    refine::Bool = false,
)
    add_interior!(vs[v1], vs[v2], vs[v3]; refine=refine)
end

"Add edge between vertices `v1` and `v2`. Set `boundary` flag if delivered."
function add_edge!(
    g::AbstractMeshGraph,
    v1::Integer,
    v2::Integer;
    boundary::Bool = false,
)
    Gr.add_edge!(g.graph, v1, v2)
    MG.set_prop!(g.graph, v1, v2, :boundary, boundary)
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

"Number of **all** vertices in graph `g`. Alias: [`nv`](@ref)"
all_vertex_count(g::AbstractMeshGraph) = Gr.nv(g.graph)

"Number of **all** vertices in graph `g`. Alias of [`vertex_count`](@ref)"
nv = all_vertex_count

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
interiors_vertices(g::AbstractMeshGraph, i::Integer) = neighbors(g, i)

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
    update_xyz!(g, v)
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
    MG.set_prop!(g.graph, v1, v2, :boundary, true)

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
