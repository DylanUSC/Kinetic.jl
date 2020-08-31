# ============================================================
# Mathematical Methods
# ============================================================

export linspace, heaviside, fortsign
export central_diff, central_diff!, upwind_diff, upwind_diff!


"""
Python linspace function

"""
linspace(start::Real, stop::Real, n::Int) = collect(range(start, stop = stop, length = n))


"""
Heaviside step function

"""
heaviside(x::Real) = ifelse(x >= 0, 1.0, 0.0)


"""
Fortran sign() function

"""
fortsign(x::Real, y::Real) = abs(x) * sign(y)


"""
Central difference

"""
function central_diff(
    y::AbstractArray{<:Any,1},
    x::AbstractArray{<:Any,1},
)

    dy = zeros(eltype(y), axes(y))

    idx = eachindex(y) |> collect
    i0 = idx[1]
    i1 = idx[end]

    dy[i0] = (y[i0+1] - y[i0]) / (x[i0+1] - x[i0])
    dy[i1] = (y[i1] - y[i1-1]) / (x[i1] - x[i1-1])
    for i = i0+1:i1-1
        dy[i] = (y[i+1] - y[i-1]) / (x[i+1] - x[i-1] + 1e-7)
    end

    return dy

end


function central_diff(y::AbstractArray{<:Any,1}, dx::Any)
    x = ones(eltype(y), axes(y)) .* dx
    dy = central_diff(y, x)

    return dy
end


function central_diff!(
    dy::AbstractArray{<:Any,1},
    y::AbstractArray{<:Any,1},
    x::AbstractArray{<:Any,1},
)

    @assert axes(dy) == axes(y) == axes(x)

    idx = eachindex(y) |> collect
    i0 = idx[1]
    i1 = idx[end]

    dy[i0] = (y[i0+1] - y[i0]) / (x[i0+1] - x[i0])
    dy[i1] = (y[i1] - y[i1-1]) / (x[i1] - x[i1-1])
    for i = i0+1:i1-1
        dy[i] = (y[i+1] - y[i-1]) / (x[i+1] - x[i-1] + 1e-7)
    end

end


function central_diff!(
    dy::AbstractArray{<:Any,1},
    y::AbstractArray{<:Any,1},
    dx::Any,
)
    x = ones(eltype(y), axes(y)) .* dx
    central_diff!(dy, y, x)
end


"""
Upwind difference

"""
function upwind_diff(
    y::AbstractArray{<:Any,1},
    x::AbstractArray{<:Any,1};
    stream = :right::Symbol,
)

    dy = zeros(eltype(y), axes(y))

    idx = eachindex(y) |> collect
    i0 = idx[1]
    i1 = idx[end]

    if stream == :right
        dy[i0] = 0.0
        for i = i0+1:i1
            dy[i] = (y[i] - y[i-1]) / (x[i] - x[i-1] + 1e-7)
        end
    elseif stream == :left
        dy[i1] = 0.0
        for i = i0:i1-1
            dy[i] = (y[i+1] - y[i]) / (x[i+1] - x[i] + 1e-7)
        end
    else
        throw("streaming direction should be :left or :right")
    end

    return dy

end


function upwind_diff(y::AbstractArray{<:Any,1}, dx::Any; stream = :right::Symbol)
    x = ones(eltype(y), axes(y)) .* dx
    dy = upwind_diff(y, x, stream = stream)

    return dy
end


function upwind_diff!(
    dy::AbstractArray{<:Any,1},
    y::AbstractArray{<:Any,1},
    x::AbstractArray{<:Any,1};
    stream = :right::Symbol,
)

    @assert axes(dy) == axes(y) == axes(x)

    idx = eachindex(y) |> collect
    i0 = idx[1]
    i1 = idx[end]

    if stream == :right
        dy[i0] = 0.0
        for i = i0+1:i1
            dy[i] = (y[i] - y[i-1]) / (x[i] - x[i-1] + 1e-7)
        end
    elseif stream == :left
        dy[i1] = 0.0
        for i = i0:i1-1
            dy[i] = (y[i+1] - y[i]) / (x[i+1] - x[i] + 1e-7)
        end
    else
        throw("streaming direction should be :left or :right")
    end

    return dy

end


function upwind_diff!(
    dy::AbstractArray{<:Any,1},
    y::AbstractArray{<:Any,1},
    dx::Any;
    stream = :right::Symbol,
)
    x = ones(eltype(y), axes(y)) .* dx
    upwind_diff!(dy, y, x, stream = stream)
end


"""
Gauss Legendre integral for fast spectral method `lgwt(N::Int, a::Real, b::Real)`
* @param[in]: number of quadrature points N, integral range [a, b]
* @param[out]: quadrature points x & weights w

"""
function lgwt(N::Int, a::Real, b::Real)

    x = zeros(N)
    w = zeros(N)

    N1 = N
    N2 = N + 1

    y = zeros(N1)
    y0 = zeros(N1)
    Lp = zeros(N1)
    L = zeros(N1, N2)

    # initial guess
    for i = 1:N1
        y[i] =
            cos((2.0 * (i - 1.0) + 1.0) * 4.0 * atan(1.0) / (2.0 * (N - 1.0) + 2.0)) +
            0.27 / N1 *
            sin(4.0 * atan(1.0) * (-1.0 + i * 2.0 / (N1 - 1.0)) * (N - 1.0) / N2)
        y0[i] = 2.0
    end

    # compute the zeros of the N+1 legendre Polynomial
    # using the recursion relation and the Newton method
    while maximum(abs.(y .- y0)) > 0.0000000000001
        L[:, 1] .= 1.0
        L[:, 2] .= y
        for k = 2:N1
            @. L[:, k+1] = ((2.0 * k - 1.0) * y * L[:, k] - (k - 1) * L[:, k-1]) / k
        end
        @. Lp = N2 * (L[:, N1] - y * L[:, N2]) / (1.0 - y^2)
        @. y0 = y
        @. y = y0 - L[:, N2] / Lp
    end

    # linear map from [-1 1] to [a,b]
    @. x = (a * (1.0 - y) + b * (1.0 + y)) / 2.0
    @. w = N2^2 * (b - a) / ((1.0 - y^2) * Lp^2) / N1^2

    return x, w

end
