# HyperVoronoiDelaunay

| **Build Status** |
|:----------------:|
| [![Build Status][build-img]][build-url] |
| [![Codecov branch][codecov-img]][codecov-url] |

HyperVoronoiDelaunay is to [VoronoiDelaunay](https://github.com/JuliaGeometry/VoronoiDelaunay.jl) what hyperplanes (resp. hyperspheres and hyperrectangles) are to planes (resp. spheres and rectangles).
It provides an interface for Delaunay and Voronoi tessellations in abritrary dimension.
It also support periodic tessellation.

This code was initially part of [VoroX](https://github.com/blegat/VoroX.jl).

|        |         32 |         64 |        128 |        256 |        512 |       1024 |
|--------|------------|------------|------------|------------|------------|------------|
|  qhull | 194.664 μs | 491.404 μs |   1.117 ms |   2.591 ms |   6.155 ms |  13.366 ms |
| cddlib |   2.639 ms |  12.862 ms |  63.421 ms | 316.546 ms |    1.449 s |    9.339 s |

[build-img]: https://github.com/JuliaPolyhedra/HyperVoronoiDelaunay.jl/workflows/CI/badge.svg?branch=master
[build-url]: https://github.com/JuliaPolyhedra/HyperVoronoiDelaunay.jl/actions?query=workflow%3ACI
[codecov-img]: http://codecov.io/github/JuliaPolyhedra/HyperVoronoiDelaunay.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaPolyhedra/HyperVoronoiDelaunay.jl?branch=master
