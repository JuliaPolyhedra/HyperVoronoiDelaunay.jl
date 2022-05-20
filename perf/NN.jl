module NN

using LinearAlgebra
using StaticArrays, NearestNeighbors

struct GridTree{N,T}
    a::SVector{N,T}
    b::SVector{N,T}
    grid::Array{Int,N}
end
function index(g::GridTree, p::SVector)
    return ceil.(Int, size(g.grid) .* (p-g.a) ./ (g.b-g.a))
end

mutable struct InRadius{NN, N, T}
    inner::NN
    points::Vector{SVector{N,T}}
    r::T
end
function InRadius(::Type{GridTree}, data, r, a, b)
    length = r / √2
    n = ceil.(Int, (b .- a) ./ length)
    grid = zeros(Int, n...)
    obj = InRadius(GridTree(a, b, grid), eltype(data)[], r)
    for p in data
        push!(obj, p)
    end
    return obj
end
function InRadius(::Type{T}, data, r, a, b) where {T<:NNTree}
    return InRadius(T(data, Euclidean()), data, r)
end


function Base.in(p, r::InRadius)
    return radius(r, p) < r.r
end
Base.length(r::InRadius) = length(r.points)
Base.getindex(r::InRadius, i) = r.points[i]

widen(i::Int) = (i - 2):(i + 2)
function radius(g::InRadius{<:GridTree}, p::SVector{N,T}) where {N,T}
    i = index(g.inner, p)
    radius = typemax(T)
    for _I in Iterators.product(widen.(i)...)
        I = CartesianIndex(_I...)
        if I in CartesianIndices(g.inner.grid)
            j = g.inner.grid[I]
            if !iszero(j)
                radius = min(radius, norm(g.points[j] - p))
            end
        end
    end
    return radius
end
function Base.push!(g::InRadius{<:GridTree}, p::SVector)
    push!(g.points, p)
    g.inner.grid[index(g.inner, p)...] = length(g.points)
    return
end

function radius(t::InRadius{<:NNTree}, p::SVector)
    return norm(nn(t.inner, x) - x)
end
function Base.push!(g::InRadius{NN}, p::SVector) where {NN<:NNTree}
    push!(g.points, p)
    g.inner = NN(g.points, Euclidean())
    return
end

end
