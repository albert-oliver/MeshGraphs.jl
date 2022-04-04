function check_p1 end

"""
    transform_p1!(g, center; use_uv, distance_fun, new_coords_fun, converter_fun)

Run transformation P1 on triangle represented by interior `center`.

```text
     v                v
    / \\              /|\\
   /   \\     =>     / | \\
  /     \\          /  |  \\
 v-------v        v---h---v
```

Conditions:
- Trinalge is marked to be refined (`:refined` property is set to `true`)
- Breaks *longest edge*, if either is true:
    - It is on the boundary (`:boundary` property is set to `true`), **OR**
    - It's vertices are not hanging nodes **AND** other two egdes are not same
    length and on the boundary
"""
function transform_p1!(
    g::MeshGraph,
    center::Integer;
    use_uv::Bool,
    distance_fun::Function,
    new_coords_fun::Function,
    converter_fun::Function,
)::Bool
    mapping = check_p1(g, center, distance_fun)
    if isnothing(mapping)
        return false
    end

    h, v1, v2 = mapping
    B1 = is_on_boundary(g, v1, v2)

    rem_edge!(g, v1, v2)

    new_coords = new_coords_fun(g, v1, v2)
    v4 = add_vertex!(g, new_coords, use_uv, converter_fun)
    if !B1
        set_hanging!(g, v4, v1, v2)
    end

    add_edge!(g, v4, v1; boundary = B1)
    add_edge!(g, v4, v2; boundary = B1)
    add_edge!(g, v4, h; boundary = false)

    add_interior!(g, v1, h, v4)
    add_interior!(g, v2, h, v4)

    rem_vertex!(g, center)

    return true
end


function check_p1(g::MeshGraph, center::Integer, distance_fun::Function)
    if !is_interior(g, center)
        return nothing
    elseif !should_refine(g, center)
        return nothing
    end

    vs = interior_connectivity(g, center)

    vA = vs[1]
    vB = vs[2]
    vC = vs[3]
    hA = get_hanging_node_between(g, vB, vC)
    hB = get_hanging_node_between(g, vA, vC)
    hC = get_hanging_node_between(g, vA, vB)

    if count(x -> isnothing(x), [hA, hB, hC]) != 3 # Return if we have a hanging node
        return nothing
    end

    if !has_edge(g, vs[1], vs[2]) ||
       !has_edge(g, vs[1], vs[3]) ||
       !has_edge(g, vs[2], vs[3])
        return nothing
    end

    la = distance_fun(g, vs[1], vs[2])
    lb = distance_fun(g, vs[2], vs[3])
    lc = distance_fun(g, vs[3], vs[1])
    longest = maximum([la, lb, lc])

    if longest == la
        v1 = vs[1]
        v2 = vs[2]
        h = vs[3]
    elseif longest == lb
        v1 = vs[2]
        v2 = vs[3]
        h = vs[1]
    else
        v1 = vs[1]
        v2 = vs[3]
        h = vs[2]
    end

    B1 = is_on_boundary(g, v1, v2)
    B2 = is_on_boundary(g, v2, h)
    B3 = is_on_boundary(g, h, v1)
    L1 = distance_fun(g, v1, v2)
    L2 = distance_fun(g, h, v1)
    L3 = distance_fun(g, h, v2)
    HN1 = is_hanging(g, v1)
    HN2 = is_hanging(g, v2)

    if (L1 >= L2) && (L1 >= L3) && (B1 ||
        (!B1 && (!HN1 && !HN2) && !((B2 && L2 == L1) || (B3 && L3==L1))) )
        return h, v1, v2
    end
    return nothing
end
