struct SimpleSpec <: AbstractSpec end

"""
    SimpleGraph()

Simple graph type. Alias for `MeshGraph{SimpleSpec}`.Specialization
(`SimpleSpec`) is type with no fields. All specialization-connected
function are defaut.
    
See: [`add_vertex_strategy`](@ref), [`convert`](@ref),
[`distance`](@ref), [`new_vertex_coords`](@ref).
"""
const SimpleGraph = MeshGraph{SimpleSpec}

SimpleGraph() = MeshGraph(SimpleSpec())
