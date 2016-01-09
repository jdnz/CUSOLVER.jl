using CUSOLVER
using CUDArt
using Base.Test

import CUSPARSE: CudaSparseMatrixCSR

m = 10
n = 10

##################
# test_csrlsvlu! #
##################
function test_csrlsvlu!(elty)
    A = sparse(rand(elty,n,n))
    b = rand(elty,n)
    x = zeros(elty,n)
    x = CUSOLVER.csrlsvlu!(A,b,x,convert(real(elty),1e-6),convert(Cint,1),'O')
    @test x ≈ full(A)\b
end

###################
# test_csrlsqvqr! #
###################
function test_csrlsqvqr!(elty)
    A = sparse(rand(elty,n,n))
    b = rand(elty,n)
    x = zeros(elty,n)
    x = CUSOLVER.csrlsqvqr!(A,b,x,convert(real(elty),1e-4),'O')
    @test x[1] ≈ full(A)\b
end

##################
# test_csrlsvqr! #
##################
function test_csrlsvqr!(elty)
    A     = sparse(rand(elty,n,n))
    d_A   = CudaSparseMatrixCSR(A)
    b     = rand(elty,n)
    d_b   = CudaArray(b)
    x     = zeros(elty,n)
    d_x   = CudaArray(x)
    d_x   = CUSOLVER.csrlsvqr!(d_A,d_b,d_x,convert(real(elty),1e-4),convert(Cint,1),'O')
    h_x   = to_host(d_x)
    @test h_x ≈ full(A)\b
end

####################
# test_csrlsvchol! #
####################
function test_csrlsvchol!(elty)
    A     = rand(elty,n,n)
    A     = sparse(A*A') #posdef
    d_A   = CudaSparseMatrixCSR(A)
    b     = rand(elty,n)
    d_b   = CudaArray(b)
    x     = zeros(elty,n)
    d_x   = CudaArray(x)

    d_x   = CUSOLVER.csrlsvchol!(d_A,d_b,d_x,10^2*eps(real(elty)),convert(Cint,0),'O')
    h_x   = to_host(d_x)
    @test h_x ≈ full(A)\b
end

##################
# test_csreigvsi #
##################
function test_csreigvsi(elty)
    A     = sparse(rand(elty,n,n))
    d_A   = CudaSparseMatrixCSR(A)
    evs   = eigvals(full(A))
    x_0   = CudaArray(rand(elty,n))
    μ,x   = CUSOLVER.csreigvsi(d_A,convert(elty,evs[1]),x_0,convert(real(elty),1e-6),convert(Cint,1000),'O')
    @test μ ≈ evs[1]
end

################
# test_csreigs #
################
function test_csreigs(elty)
    A   = rand(real(elty),n,n)
    A   = sparse(A + A')
    num = CUSOLVER.csreigs(A,convert(elty,complex(-100,-100)),convert(elty,complex(100,100)),'O')
    @test num <= n
end

types = [Float32, Float64, Complex64, Complex128]
for elty in types
    test_csreigvsi(elty)
    test_csreigs(complex(elty))
    test_csrlsvlu!(elty)
    test_csrlsvchol!(elty)
    test_csrlsvqr!(elty)
    test_csrlsqvqr!(elty)
end
