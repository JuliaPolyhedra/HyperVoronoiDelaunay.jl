module HyperVoronoiDelaunay

export Periodic, NonPeriodic, delaunay

using LinearAlgebra
using StaticArrays

import Polyhedra
import VoronoiDelaunay
import MiniQhull

struct NonPeriodic end
struct Periodic{N,T}
    period::SVector{N,T}
end

function delaunay(points::Vector{SVector{N,T}}, algo::Polyhedra.Library, ::NonPeriodic) where {N,T}
    lifted = [SVector(p..., norm(p)^2) for p in points]
    p = Polyhedra.polyhedron(Polyhedra.vrep(lifted), algo)
    _simplices = Vector{Int}[]
    function add_Δ(vr, vv, vertices_idx, idxmap)
        @assert length(vertices_idx) == N + 1
        push!(_simplices, map(1:(N+1)) do j
            vi = vertices_idx[j]
            v = get(vr, vi)
            if v == vv[vi.value]
                i = vi.value
            else
                i = findfirst(isequal(v), vv)
            end
            idxmap[i]
        end)
    end
    for hi in Polyhedra.Indices{T,Polyhedra.halfspacetype(p)}(p)
        h = get(p, hi)
        if Polyhedra._neg(h.a[end])
            vertices_idx = Polyhedra.incidentpointindices(p, hi)
            @assert length(vertices_idx) >= N + 1
            if length(vertices_idx) == N + 1
                add_Δ(p, lifted, vertices_idx, eachindex(lifted))
            else
                idx = map(vertices_idx) do vi
                    @assert get(p, vi) == lifted[vi.value]
                    vi.value
                end
                vv = points[idx]
                vr = Polyhedra.polyhedron(Polyhedra.vrep(vv), algo)
                for Δ in Polyhedra.triangulation_indices(vr)
                    add_Δ(vr, vv, Δ, idx)
                end
            end
        end
    end
    simplices = Matrix{Int}(undef, N+1, length(_simplices))
    for (i, Δ) in enumerate(_simplices)
        simplices[:, i] = Δ
    end
    return simplices
end

function delaunay(points::Vector{SVector{2,T}}, algo::Type{<:VoronoiDelaunay.DelaunayTessellation2D}, ::NonPeriodic) where {T}
    tess = VoronoiDelaunay.DelaunayTessellation(length(points))
    # VoronoiDelaunay currently needs the points to be between 1 + ε and 2 - 2ε
    a = reduce((a, b) -> min.(a, b), points, init=SVector(Inf, Inf))
    b = reduce((a, b) -> max.(a, b), points, init=SVector(-Inf, -Inf))
    width = b .- a
    scaled = map(points) do p
        # Multipltiply by 1.0001 to be sure to be in [1 + ε, 2 - 2ε]
        x = (p .- a) ./ (width * (1 + 1e-4)) .+ (1 + 1e-6)
        for c in x
            if !(1 + eps(Float64) < c < 2 - 2eps(Float64))
                error("Point $p was mapped to $c for which the coordonate $x is not in the interval [$(1 + eps(Float64)), $(2 - 2eps(Float64)))]")
            end
        end
        return VoronoiDelaunay.Point2D(x...)
    end
    # Should construct before as `tess` modifies `scaled`.
    back = Dict(p => i for (i, p) in enumerate(scaled))
    push!(tess, scaled)
    Δs = VoronoiDelaunay.DelaunayTriangle{VoronoiDelaunay.GeometricalPredicates.Point2D}[]
    # Cannot collect as it does not implement length nor IteratorSize
    for Δ in tess
        push!(Δs, Δ)
    end
    simplices = Matrix{Int}(undef, 3, length(Δs))
    for (i, Δ) in enumerate(Δs)
        simplices[1, i] = back[VoronoiDelaunay.geta(Δ)]
        simplices[2, i] = back[VoronoiDelaunay.getb(Δ)]
        simplices[3, i] = back[VoronoiDelaunay.getc(Δ)]
    end
    return simplices
end

function delaunay(points::Vector{SVector{N,T}}, algo::typeof(MiniQhull.delaunay), ::NonPeriodic) where {N,T}
    return MiniQhull.delaunay(points)
end

import CGAL
function delaunay(points::Vector{SVector{N,T}}, algo::Type{CGAL.DelaunayTriangulation2}, ::NonPeriodic) where {N,T}
    cgal_points = [CGAL.Point2(point...) for point in points]
    # FIXME is there an easier way to get the index and not the coordinate from CGAL ?
    index = Dict(point => index for (index, point) in enumerate(cgal_points))
    t = CGAL.DelaunayTriangulation2(cgal_points)
    fs = CGAL.faces(t)
    simplices = Matrix{Int}(undef, N+1, length(fs))
    for (i, f) in enumerate(fs)
        for j in 1:(N+1)
            simplices[i, j] = index[CGAL.point(CGAL.vertex(f, j))]
        end
    end
    return simplices
end

function shift_point(point::SVector{N,T}, shift::NTuple{N,Int}, period::SVector{N,T}) where {N,T}
    return point .+ shift .* period
end

function all_shift(points::Vector{SVector{N,T}}, p::SVector{N,T}) where {N,T}
    n = length(points)
    ps = Vector{SVector{N,T}}(undef, 3^N * length(points))
    for shift in Iterators.product(ntuple(_ -> -1:1, Val(N))...)
        ps[shift_range(shift, n)] = shift_point.(points, Ref(shift), Ref(p))
    end
    return ps
end

shift_offset(shift::NTuple{0,Int}) = 0
function shift_offset(shift::NTuple{N,Int}) where {N}
    return 1 + first(shift) + 3shift_offset(Base.tail(shift))
end
shift_range(shift, len) = len * shift_offset(shift) .+ (1:len)

id_shift(id, ::Tuple{}) = tuple()
function id_shift(id, t::Tuple)
    return ((id % 3) - 1), id_shift(div(id, 3), Base.tail(t))...
end
function id_shift(id, n, l::Val)
    return id_shift(div(id - 1, n), ntuple(_ -> nothing, l))
end

function delaunay(points::Vector{SVector{N,T}}, algo, p::Periodic{N,T}) where {N,T}
    pp = all_shift(points, p.period)
    simplices = delaunay(all_shift(points, p.period), algo, NonPeriodic())
    selected = Dict{Tuple{Vector{eltype(simplices)},Vector{NTuple{N,Int}}},Int}()
#    function score(simplex)
#        count(id_shift.(simplex, length(points), Val(N))) do shift
#            @assert all(i -> -1 <= i <= 1, shift)
#            all(iszero, shift)
#        end
#    end
    for j in 1:size(simplices, 2)
        s = simplices[:, j]
        sort!(s)
        id = mod1.(s, length(points))
        id_shifts = id_shift.(s, length(points), Val(N))
        if !any(shift -> all(iszero, shift), id_shifts)
            continue
        end
        root = id_shifts[1]
        id_shifts = map(id_shifts) do shift
            shift .- root
        end
        key = (id, id_shifts)
        if !haskey(selected, key)
            selected[key] = j
        end
    end
    return simplices[:, collect(values(selected))]
end

end # module
