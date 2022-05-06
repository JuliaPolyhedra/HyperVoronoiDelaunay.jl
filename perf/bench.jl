LIBRARIES = [MiniQhull.delaunay, QHull.Library(), CDDLib.Library(:float), VoronoiDelaunay.DelaunayTessellation2D]

using StaticArrays

import CDDLib
import QHull
import VoronoiDelaunay
import MiniQhull

using HyperVoronoiDelaunay

include("rand.jl")

ns = [16, 32]
max_coords = SVector(1.0, 1.0, 1.0)
min_coords = -max_coords
ps = [random_points(n, min_coords, max_coords) for n in ns]

table = []

for p in ps
    bs = []
    for lib in LIBRARIES
        push!(bs, nothing) # @benchmark delaunay(p, lib, NonPeriodic()))
    end
    push!(table, (lib, bs))
end

include("table.jl")
prettyprint(table, ns)
