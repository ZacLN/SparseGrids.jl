for i = 1:length(GridSpecs)
    eval(:(function jl_getW(G::NGrid{$(GridSpecs[i][2])},A::Array{Float64})
        Aold = zeros(size(A))
        w = zeros(size(A))
        N = size(G.grid,1)
        D = size(G.grid,2)
        nA = size(A,2)
        for l = 0:maximum(G.L)
            for i=G.level_loc[l+1]:G.level_loc[l+2]-1
                for a = 1:nA
                    w[i,a] = A[i,a]-Aold[i,a]
                end
            end
            for i = G.level_loc[l+2]:N
                for ii=G.level_loc[l+1]:G.level_loc[l+2]-1
                    temp2=1.0
                    for d=1:D
                        temp2*=$(GridSpecs[i][3])(G.grid[i,d],G.grid[ii,d],G.level_M[ii,d])
                        temp2==0 && break
                    end
                    for a = 1:nA
                        Aold[i,a] += temp2*w[ii,a]
                    end
                end
            end
        end
        return w
    end))

    eval(:(function jl_interpslow(xi::Array{Float64},G::NGrid{$(GridSpecs[i][2])},A::Vector{Float64})
        w = getW(G,A)
        x = nXtoU(xi,G.bounds)
        nx = size(x,1)
        y = zeros(nx)
        N = size(G.grid,1)
        D = size(G.grid,2)
        for i = 1:nx
            for ii = 1:N
                temp2 = 1.0
                for d = 1:D
                    temp2 *= $(GridSpecs[i][3])(x[i,d],G.grid[ii,d],G.level_M[ii,d])
                    temp2==0.0 ? break : nothing
                end
                y[i]+= temp2*w[ii]
            end
        end
        return y
    end))

    eval(:(function jl_interp(xi::Array{Float64},G::NGrid{$(GridSpecs[i][2])},A::Array{Float64})
        w = getW(G,A)
        x = nXtoU(xi,G.bounds)
        nx = size(x,1)
        y = zeros(nx,size(A,2))
        N = size(G.grid,1)
        D = size(G.grid,2)
        nA = size(A,2)
        for i = 1:nx
            ii = Int32(1)
            while ii<=N
                temp2 = 1.0
                for d = 1:D
                    temp2 *= $(GridSpecs[i][3])(x[i,d],G.grid[ii,d],G.level_M[ii,d])
                    temp2==0.0 ? break : nothing
                end
                for a = 1:nA
                    y[i,a] += temp2*w[ii,a]
                end
                temp2==0.0 ? ii+=Int32(1) : ii=G.nextid[ii]
            end
        end
        return y
    end))
end

    # function jl_interp{T<:GridType}(x1::Array{Float64},G::NGrid{T,GaussianRadialBF},A::Array{Float64})
    # 	x = nXtoU(x1,G.bounds)
    # 	Gm = eye(length(G))
    #     for i = 2:length(G)
    #         for j = 1:i-1
    # 			Gm[i,j]=exp(-(norm(G.grid[i,:]-G.grid[j,:])).^2)
    #             Gm[j,i]=Gm[i,j]
    #         end
    #     end
    # 	w =  Gm\A
    #     g = Array(Float64,size(x,1),length(G))
    #     for i = 1:size(x,1)
    #         for j = 1:length(G)
    # 			g[i,j]=exp(-(norm(x[i,:]-G.grid[j,:])).^2)
    #         end
    #     end
    #     return g*w
    # end


function c_getW{D}(G::NGrid{D,Linear},A::Vector{Float64})
    Aold 	= zeros(length(G))
    dA 		= zeros(length(G))
    w 		= zeros(length(G))
    ccall((:_Z6w_cc_liiiPdS_PsPiS_S_S_,lsparse),
        Void,
        (Int32,Int32,Int32,
        Ptr{Float64},Ptr{Float64},Ptr{Int16},Ptr{Float64},
        Ptr{Float64},Ptr{Float64},Ptr{Float64}),
        length(G),size(G.grid,2),maximum(G.L),
        pointer(G.grid),pointer(A),pointer(G.level_M),pointer(G.level_loc),
        pointer(Aold),pointer(dA),pointer(w))
    return w
end

function c_getW{D}(G::NGrid{D,Linear},A::Array{Float64,2})
    Aold 	= zeros(size(A))
    w 		= zeros(size(A))
    ccall((:_Z10w_cc_l_arrPdiiiiPsPiS_S_S_,lsparse),
        Void,
        (Ptr{Float64},Int32,Int32,Int32,Int32,
         Ptr{Int16},Ptr{Float64},Ptr{Float64},
         Ptr{Float64},Ptr{Float64}),
        pointer(G.grid),length(G),size(G.grid,2),maximum(G.L),size(A,2),
        pointer(G.level_M),pointer(G.level_loc),pointer(A),
        pointer(Aold),pointer(w))
    return w
end


function c_interp{D}(xi::Array{Float64},G::NGrid{D,Linear},A::Vector{Float64})
    x 		= nXtoU(xi,G.bounds)
    y 		= zeros(size(xi,1))
    w 		= c_getW(G,A)
    ccall((:_Z11interp_cc_liiiiPdPsS_S_S_Pi,lsparse),
        Void,
        (Int32,Int32,Int32,Int32,Ptr{Float64},Ptr{Int16},Ptr{Float64},Ptr{Float64},Ptr{Float64},Ptr{Float64}),
        length(G.L),maximum(G.L),size(G.grid,1),size(x,1),pointer(G.grid),pointer(G.level_M),pointer(w),pointer(x),pointer(y),pointer(G.nextid))
    return y
end

function c_interp{D}(xi::Array{Float64},G::NGrid{D,Linear},A::Array{Float64,2})
    x 		= nXtoU(xi,G.bounds)
    y 		= zeros(size(x,1),size(A,2))
    w 		= c_getW(G,A)
    ccall((:_Z15interp_cc_l_arriiiiiPdPsS_S_S_Pi,lsparse),
        Void,
        (Int32,Int32,Int32,Int32,Int32,Ptr{Float64},Ptr{Int16},Ptr{Float64},Ptr{Float64},Ptr{Float64},Ptr{Float64}),
        length(G.L),maximum(G.L),size(G.grid,1),size(x,1),size(A,2),pointer(G.grid),pointer(G.level_M),pointer(w),pointer(x),pointer(y),pointer(G.nextid))
    return y
end


function c_getW{D}(G::NGrid{D,Quadratic},A::Vector{Float64})
    Aold 	= zeros(length(G))
    dA 		= zeros(length(G))
    w 		= zeros(length(G))
    ccall((:_Z6w_cc_qPdiiiPsPiS_S_S_S_,lsparse),
        Void,
        (Ptr{Float64},Int32,Int32,Int32,
         Ptr{Int16},Ptr{Float64},Ptr{Float64},
         Ptr{Float64},Ptr{Float64},Ptr{Float64}),
        pointer(G.grid),length(G),size(G.grid,2),maximum(G.L),
        pointer(G.level_M),pointer(G.level_loc),pointer(A),
        pointer(Aold),pointer(dA),pointer(w))
    return w
end

function c_getW{D}(G::NGrid{D,Quadratic},A::Array{Float64,2})
    Aold 	= zeros(size(A))
    w 		= zeros(size(A))
    ccall((:_Z10w_cc_q_arrPdiiiiPsPiS_S_S_,lsparse),
        Void,
        (Ptr{Float64},Int32,Int32,Int32,Int32,
         Ptr{Int16},Ptr{Float64},Ptr{Float64},
         Ptr{Float64},Ptr{Float64}),
        pointer(G.grid),length(G),size(G.grid,2),maximum(G.L),size(A,2),
        pointer(G.level_M),pointer(G.level_loc),pointer(A),
        pointer(Aold),pointer(w))
    return w
end

function c_interp{D}(xi::Array{Float64},G::NGrid{D,Quadratic},A::Vector{Float64})
    x 		= nXtoU(xi,G.bounds)
    y 		= zeros(size(xi,1))
    w 		= c_getW(G,A)
    ccall((:_Z11interp_cc_qiiiiPdPsS_S_S_Pi,lsparse),
        Void,
        (Int32,Int32,Int32,Int32,Ptr{Float64},Ptr{Int16},Ptr{Float64},Ptr{Float64},Ptr{Float64},Ptr{Float64}),
        length(G.L),maximum(G.L),size(G.grid,1),size(x,1),pointer(G.grid),pointer(G.level_M),pointer(w),pointer(x),pointer(y),pointer(G.nextid))
    return y
end

function c_interp{D}(xi::Array{Float64},G::NGrid{D,Quadratic},A::Array{Float64,2})
    x 		= nXtoU(xi,G.bounds)
    y 		= zeros(size(x,1),size(A,2))
    w 		= c_getW(G,A)
    ccall((:_Z15interp_cc_q_arriiiiiPdPsS_S_S_Pi,lsparse),
        Void,
        (Int32,Int32,Int32,Int32,Int32,Ptr{Float64},Ptr{Int16},Ptr{Float64},Ptr{Float64},Ptr{Float64},Ptr{Float64}),
        length(G.L),maximum(G.L),size(G.grid,1),size(x,1),size(A,2),pointer(G.grid),pointer(G.level_M),pointer(w),pointer(x),pointer(y),pointer(G.nextid))
    return y
end