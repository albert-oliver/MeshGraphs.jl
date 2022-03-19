import Graphs; const Gr = Graphs
import MetaGraphs; const MG = MetaGraphs
using LinearAlgebra

# -----------------------------------------------------------------------------
# ------ SphereGraph type definition and constructors -------------------------
# -----------------------------------------------------------------------------

"""
`SphereGraph` is a `MeshGraph` whose vertices are on sphere with radius
`radius`.

Can represent Earth's surface where elevation above (or below) sea level is
set using `elevation` property.

# Note
- `uv` are in degress, where:
    - `u = lon` is in range `(-180, 180]`
    - `v = lat` is in range `[-90, 90]`
- Notice reverse order: `[u, v] = [lon, lat]`

See also: [`MeshGraph`](@ref)
"""
mutable struct SphereGraph <: MeshGraph
    graph::MG.MetaGraph
    radius::Real
    vertex_count::Integer
    interior_count::Integer
    hanging_count::Integer
end

"""
    SphereGraph(radius)

Construct a `SphereGraph` with radius `radius`.
"""
function SphereGraph(radius::Real)::SphereGraph
    graph = MG.MetaGraph()
    SphereGraph(graph, radius, 0, 0, 0)
end

"""
    SphereGraph()

Construct a `SphereGraph` with `radius=6371000` - Earth's radius.
"""
SphereGraph() = SphereGraph(6371000)::SphereGraph

function show(io::IO, g::SphereGraph)
    vs = g.vertex_count
    ins = g.interior_count
    hs = g.hanging_count
    es = length(edges(g))
    r = g.radius
    print(
        io,
        "SphereGraph with ($(vs) vertices), ($(ins) interiors), ($(hs) hanging nodes), ($(es) edges) and (radius $(r))",
    )
end

# -----------------------------------------------------------------------------
# ------ Functions specific for SphereGraph -----------------------------------
# -----------------------------------------------------------------------------

function cartesian_to_spherical(coords::AbstractVector{<:Real})
    x, y, z = coords
    r = norm(coords[1:3])
    lat = r !=0 ? -acosd(z / r) + 90.0 : 0
    lon = atand(y, x)
    [r, lat, lon]
end

function spherical_to_cartesian(coords::AbstractVector{<:Real})
    r, lat, lon = coords
    r .* [cosd(lon) * cosd(lat), sind(lon) * cosd(lat), sind(lat)]
end

lat(g::SphereGraph, v::Integer) = uv(g, v)[2]
lon(g::SphereGraph, v::Integer) = uv(g, v)[1]

"Return vector `[r, lat, lon]` with spherical coordinates of vertex `v`."
function get_spherical(g::SphereGraph, v::Integer)::Vector{<:Real}
    coords = reverse(uv(g, v))
    elevation = get_elevation(g, v)
    spherical = vcat([g.radius + elevation], coords)
    return spherical
end

# -----------------------------------------------------------------------------
# ------ Methods for MeshGraph functions -------------------------------------
# -----------------------------------------------------------------------------

function update_xyz!(g::SphereGraph, v::Integer)
    spherical = get_spherical(g, v)
    coords = spherical_to_cartesian(spherical)
    MG.set_prop!(g.graph, v, :xyz, coords)
end

function update_uv_elev!(g::SphereGraph, v::Integer)
    coords = xyz(g, v)
    spherical = cartesian_to_spherical(coords)
    MG.set_prop!(g.graph, v, :elevation, spherical[1] - g.radius)
    MG.set_prop!(g.graph, v, :uv, spherical[3:-1:2])
end

function validate_uv(g::SphereGraph, coords::AbstractVector{<:Real})
    lon = -(mod((-coords[1] + 180), 360) - 180) # moves lon to range (-180, 180]
    lat = coords[2]
    if lat < -90 || lat > 90
        throw(DomainError(lat, "Latitude has to be in range [-90, 90]"))
    end
    return [lon, lat]
end

function get_value_cartesian(g::SphereGraph, v::Integer)
    coords = get_spherical(g, v)
    coords[1] += get_value(g, v)
    return spherical_to_cartesian(coords)
end

function scale_graph(g::SphereGraph, scale::Real)
    for v in normal_vertices(g)
        new_xyz = xyz(g, v) * scale
        g.radius = g.radius * scale
        MG.set_prop!(g.graph, v, :xyz, new_xyz)
        recalculate_spherical!(g)
    end
end
