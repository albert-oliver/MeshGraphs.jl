function check_p2 end

"""
    transform_p2!(g, center, use_uv, new_coords_fun, converter_fun)

Run transgormation P2 on triangle represented by interior `center`.

One edge with hanging node that is the longest edge.

```text
     v                v
    / \\              /|\\
   /   \\     =>     / | \\
  /     \\          /  |  \\
 v---h---v        v---h---v
```

Conditions:
- Breaks triangle if hanging node is on the longes edge
"""
function transform_p2!(
    g::MeshGraph,
    center::Integer;
    use_uv::Bool,
    distance_fun::Function,
    new_coords_fun::Function,
    converter_fun::Function,
)::Bool
    mapping = check_p2(g, center, distance_fun)
    if isnothing(mapping)
        return false
    end

    v1, v2, v3, h = mapping

    unset_hanging!(g, h)

    add_edge!(g, h, v3)

    # TODO view of center to add_interior to split points
    add_interior!(g, v1, v3, h)
    add_interior!(g, v2, v3, h)

    rem_vertex!(g, center)

    return true
end


function check_p2(g::MeshGraph, center::Integer, distance_fun::Function)
    if !is_interior(g, center)
        return nothing
    end

    vs = interior_connectivity(g, center)

    vA = vs[1]
    vB = vs[2]
    vC = vs[3]
    hA = get_hanging_node_between(g, vB, vC)
    hB = get_hanging_node_between(g, vA, vC)
    hC = get_hanging_node_between(g, vA, vB)

    if count(x -> isnothing(x), [hA, hB, hC]) != 2 # Return if we don't have one hanging node
        return nothing
    end

    v1 = nothing
    v2 = nothing
    v3 = nothing
    h = nothing

    if !isnothing(hA)
        v1 = vB
        v2 = vC
        v3 = vA
        h = hA
    elseif !isnothing(hB)
        v1 = vA
        v2 = vC
        v3 = vB
        h = hB
    else
        v1 = vA
        v2 = vB
        v3 = vC
        h = hC
    end

    if !has_edge(g, v1, v3) ||
       !has_edge(g, v2, v3)
        return nothing
    end

    L12 = distance_fun(g, v1, v2)
    L3 = distance_fun(g, v2, v3)
    L4 = distance_fun(g, v1, v3)

    if L12 >= L3 && L12 >= L4
        return v1, v2, v3, h
    end
    return nothing
end
