using StaticArrays

import CDDLib
import QHull
import VoronoiDelaunay
import MiniQhull

LIBRARIES = [("qhull", MiniQhull.delaunay), ("cddlib", CDDLib.Library(:float))]

using HyperVoronoiDelaunay

import BenchmarkTools

include("rand.jl")

ns = [2^n for n in 5:10]
max_coords = SVector(1.0, 1.0, 1.0)
min_coords = -max_coords
ps = [random_points(n, min_coords, max_coords) for n in ns]

table = []

for (name, lib) in LIBRARIES
    bs = []
    for p in ps
        push!(bs, BenchmarkTools.@benchmark delaunay($p, $lib, NonPeriodic()))
    end
    push!(table, (name, bs))
end

include("table.jl")
prettyprint(table, ns)
