module SparseGrids

import Base.show
export CurtisClenshaw,
	   NoBoundary,
	   Maximum,
	   FullLinear,
	   FullQuad,
	   RadialSqrtCC,
	   interp,
	   getW,
	   getWinv,
	   getQ,
	   grow!,
	   shrink!

include("curtisclenshaw.jl")
include("noboundary.jl")
include("maximum.jl")
include("fulllinear.jl")
include("fullquad.jl")
include("radialsqrtcc.jl")

getWinvC(G::CurtisClenshaw.Grid) = CurtisClenshaw.getWinvC(G)
getQ(xi::Array{Float64,2},G::CurtisClenshaw.Grid,) = CurtisClenshaw.getQ(xi,G)

# getWinvC(G::NoBoundary.Grid) = NoBoundary.getWinvC(G)
# getQ(xi::Array{Float64,2},G::NoBoundary.Grid) = NoBoundary.getQ(xi,G)
# getWinvC(G::Maximum.Grid) = Maximum.getWinvC(G)
# getQ(xi::Array{Float64,2},G::Maximum.Grid) = Maximum.getQ(xi,G)

for g in (CurtisClenshaw,)#(CurtisClenshaw,Maximum,NoBoundary)
	@eval interp(xi::Array{Float64,2},G::$g.Grid,A::Array{Float64,1}) 	= $g.interp(xi,G,A)
	@eval getW(G::$g.Grid,A::Array{Float64}) 							= $g.getW(G,A)
	@eval getWinv(G::$g.Grid) 											= $g.getWinv(G)
	@eval grow!(G::$g.Grid,id,bounds::Vector{Int}=15*ones(Int,G.d))		= $g.grow!(G,id,bounds)
	@eval shrink!(G::$g.Grid,id::Vector{Int}) 							= $g.shrink!(G,id)
	@eval show(io::IO,G::$g.Grid) 										= println(io,typeof(G)," {",G.d,",",G.q,"}[",G.n,"]")
end

interp(xi::Array{Float64,2},G::FullLinear.Grid,A::Array{Float64,1}) 	= FullLinear.interp(xi,G,A)
interp(xi::Array{Float64,2},G::FullQuad.Grid,A::Array{Float64,1}) 	= FullQuad.interp(xi,G,A)
interp(xi::Array{Float64,2},G::RadialSqrtCC.Grid,A::Array{Float64,1}) 	= RadialSqrtCC.interp(xi,G,A)


end
