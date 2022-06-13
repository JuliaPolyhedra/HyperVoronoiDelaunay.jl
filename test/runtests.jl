using Test

using StaticArrays

import CDDLib
import QHull
import VoronoiDelaunay
import MiniQhull
import CGAL

using HyperVoronoiDelaunay

function _test_grid(n, lib)
    points = [SVector{2,Float64}(x, y) for x in -n:n for y in -n:n]
    return delaunay(points, lib, NonPeriodic())
end

function test_grid_0(lib)
    simplices = _test_grid(0, lib)
    @show size(simplices)
end

function test_grid_1(lib)
    simplices = _test_grid(1, lib)
    @test size(simplices) == (3, 8)
end

# Test failing with VoronoiDelaunay
# See https://github.com/JuliaGeometry/VoronoiDelaunay.jl/issues/55
function test_issue_55(lib)
    points = [
        SVector(0.0, 0.0),
        SVector(-0.8, -0.4),
        SVector( 0.8, -0.2),
        SVector( 0.0,  0.6),
    ]
    simplices = delaunay(points, lib, NonPeriodic())
    @test size(simplices) == (3, 3)
end

function hascol(A, cols)
    for col in cols
        sort!(col)
        for i in 1:size(A, 2)
            if col == sort(A[:, i])
                return true
            end
        end
    end
    return false
end

function test_periodic(algo)
    points = [
        SVector( 1/4,  1/2),
        SVector(-1/2, -1/2),
        SVector( 1/2, -1/2),
    ]
    d = delaunay(points, algo, Periodic(SVector(2.0, 2.0)))
    @test size(d) == (3, 6)
    @test hascol(d, [[13, 14, 15]])
    @test hascol(d, [[4, 14, 15], [13, 23, 24]])
    @test hascol(d, [[13, 15, 17], [10, 12, 14]])
    @test hascol(d, [[4, 15, 17], [1, 12, 14], [13, 24, 26]])
    @test hascol(d, [[10, 13, 23], [13, 16, 26], [1, 4, 14]])
    @test hascol(d, [[10, 13, 14], [13, 16, 17]])
end

LIBRARIES = [MiniQhull.delaunay, QHull.Library(), CDDLib.Library(:float), VoronoiDelaunay.DelaunayTessellation2D, CGAL.DelaunayTriangulation2]

@testset "Test issue 55 $lib" for lib in LIBRARIES
    if lib != VoronoiDelaunay.DelaunayTessellation2D
        test_issue_55(lib)
    end
end

@testset "Grid $lib" for lib in LIBRARIES
    @testset "0" begin
        if lib != VoronoiDelaunay.DelaunayTessellation2D && !isa(lib, QHull.Library) && lib != MiniQhull.delaunay
            test_grid_0(lib)
        end
    end
    @testset "1" begin
        test_grid_1(lib)
    end
end

@testset "periodic" for lib in LIBRARIES
    test_periodic(lib)
end
