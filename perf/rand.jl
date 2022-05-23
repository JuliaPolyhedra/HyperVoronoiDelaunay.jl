# Taken from blegat/VoroX.jl
include("NN.jl")

using LinearAlgebra

# Sample Set of Points in Region
function random_points(K::Int, a::SVector, b::SVector, algo = NN.GridTree; maxtries = 10K)
    # Inequality between volumes:
    # K * πr^2 < prod(b .- a)
    r = prod(b .- a) / √(π * K)
    r /= 2

    # Setup Grid
    set = NN.InRadius(algo, [(a + b) / 2], r, a, b)

    # Now Generate New Samples by Iterating over the Set
    tries = 0

    K -= 1
    while K > 0 && tries < maxtries
        # Sample Uniformly from Set
        n = rand(1:length(set))

        # Generate Sample Surrounding It
        len = r + r * rand(Float64)
        dir = randn(typeof(a))
        dir /= norm(dir)

        # New Sample Position, Grid Index
        p = set[n] + len * dir
        if !all(a .< p .< b)
        elseif p in set
            tries += 1
        else
            push!(set, p)
            K -= 1
        end
    end

    if K > 0
        @warn("Generated $(length(set.points)), missing $K points.")
    end

    return set.points
end
