function check_p3 end

"""
    transform_p3!(g, center)

Run transgormation P3 on triangle represented by interior `center`.

One edge with hanging node that is not the longest edge.

```text
     v                v
    / \\              /|\\
   h   \\     =>     h | \\
  /     \\          /  |  \\
 v-------v        v---h---v
```

Conditions:
- Breaks *longest edge* (note that hanging node is not on it) if eiter is true:
    - It is on the boundary (`:boundary` property is set to `true`), **OR**
    - It's vertices are not hanging nodes **AND** other egde is not same
    length and on the boundary
"""
function transform_p3!(
    g::MeshGraph,
    center::Integer
)::Bool
    mapping = check_p3(g, center)
    if isnothing(mapping)
        return false
    end

    v1, v2, v3 = mapping

    B3 = is_on_boundary(g, v1, v3)

    new_coords = new_vertex_coords(g, v1, v3)
    v5 = add_vertex!(g, new_coords)
    if !B3
        set_hanging!(g, v5, v1, v3)
    end

    rem_edge!(g, v1, v3)

    add_edge!(g, v1, v5; boundary=B3)
    add_edge!(g, v3, v5, boundary=B3)
    add_edge!(g, v2, v5, boundary=false)

    add_pure_interior!(g, v1, v2, v5)
    add_pure_interior!(g, v2, v5, v3)

    rem_vertex!(g, center)

    return true
end


function check_p3(g::MeshGraph, center::Integer)
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
        h = hA
        L45 = distance(g, vB, h) + distance(g, h, vC)
        vs = [vB, vC, vA]
    elseif !isnothing(hB)
        h = hB
        L45 = distance(g, vA, h) + distance(g, h, vC)
        vs = [vA, vC, vB]
    else
        h = hC
        L45 = distance(g, vA, h) + distance(g, h, vB)
        vs = [vA, vB, vC]
    end

    check_conditions = []
    for (v1, v2, v3) in [vs[[1, 2, 3]], vs[[2, 1, 3]]]
        L2 = distance(g, v2, v3)
        L3 = distance(g, v1, v3)
        B2 = is_on_boundary(g, v2, v3)
        B3 = is_on_boundary(g, v1, v3)
        HN1 = is_hanging(g, v1)
        HN3 = is_hanging(g, v3)

        if ((L3 > L45) && (L3 >= L2)) && (B3 ||
            ( !B3 && (!HN1 && !HN3) && (!(B2 && L2 == L3))) )
            push!(check_conditions, (v1, v2, v3))
        end
    end
    if !isempty(check_conditions)
        # Here we can undraw
        return check_conditions[1]
    end
    return nothing
end
