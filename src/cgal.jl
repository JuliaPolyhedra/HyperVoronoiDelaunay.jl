import CGAL
_cgal_point(a, b) = CGAL.Point2(a, b)
_cgal_point(a, b, c) = CGAL.Point3(a, b, c)
function cgal_delaunay(points::Vector{SVector{N,T}}, algo) where {N,T}
    cgal_points = [_cgal_point(point...) for point in points]
    # FIXME is there an easier way to get the index and not the coordinate from CGAL ?
    index = Dict(point => index for (index, point) in enumerate(points))
    t = algo(cgal_points)
    fs = CGAL.faces(t)
    simplices = Matrix{Int}(undef, N+1, length(fs))
    for (i, f) in enumerate(fs)
        for j in 1:(N+1)
            cgal_v = CGAL.point(CGAL.vertex(f, j))
            v = SVector{N,T}(CGAL.x(cgal_v), CGAL.y(cgal_v))
            simplices[j, i] = index[v]
        end
    end
    return simplices
end
function delaunay(points::Vector{SVector{2,T}}, algo::Type{CGAL.DelaunayTriangulation2}, ::NonPeriodic) where {T}
    return cgal_delaunay(points, algo)
end
function delaunay(points::Vector{SVector{3,T}}, algo::Type{CGAL.DelaunayTriangulation3}, ::NonPeriodic) where {T}
    return cgal_delaunay(points, algo)
end
