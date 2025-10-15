
using Statistics # for std

abstract type Likelihood{T} end

# likelihoods have to implement these parameters
function evaluate_nll(::Likelihood) error("evaluate_nll not implemented for this likelihood") end
function copy(::Likelihood) error("copy not implemented for this likelihood") end
function randomize_parameters!(lik::Likelihood) lik end # if the likelihood has parameters to optimize
function varnumber(lik::Likelihood) size(lik.X, 2) end
function numparam(::Likelihood) 0 end # number of parameters to optimize in the likelihood
function extractparam(::Likelihood{T}) T[] end # extract parameters as a vector
function updateparam!(::Likelihood{T}, ::AbstractVector{T}) where T end # update parameters from a vector

# independent Gaussian noise
# sigma is either 
# - a value of type T:  which means that we use identical errors ~ N(0, sigma_err)
# - a vector of type T: which means that we have different uncertainties on each observation
struct GaussianLikelihood{T} <: Likelihood{T} 
    const X::Matrix{T}
    const y::Vector{T}
    const sigma_y::T
    sigma_err::Union{T,Vector{T}}
    const optimize_sigma::Bool

    GaussianLikelihood(X::Matrix{T}, y::Vector{T}, sigma_err=nothing) where {T} = 
        new{T}(X, y, std(y), something(sigma_err, zero(T)), isnothing(sigma_err))
end

# TODO: might define the () operator for convenience
# (lik::GaussianLikelihood)(prog, param, buffers) = evaluate_nll(lik, prog, param, buffers)

function evaluate_nll(lik::GaussianLikelihood, prog, param, buffers)
    if like.optimize_sigma
        sigma_err = param[1]
        ypred = predict!(buffers, prog, lik.X, @view param[2:end])
        evaluate_nll(lik, lik.y, ypred, sigma_err)
    else
        ypred = predict!(buffers, prog, lik.X, param)
        evaluate_nll(lik, lik.y, ypred, lik.sigma_err)
    end
end

function evaluate_nll(lik::GaussianLikelihood, y, ypred, sigma_err::AbstractArray)
    T = eltype(ypred)
    @assert axes(ypred) == axes(y) == axes(sigma_err)
    nll = zero(T)
    @inbounds for i in eachindex(lik.y)
        nll += (ypred[i] - y[i])^2 / sigma_err[i]^2 + log(T(2 * pi) * sigma_err[i]^2)
    end

    (isnan(nll) || isinf(nll)) && return floatmax(T)
    T(1/2) * nll
end

function evaluate_nll(lik::GaussianLikelihood, y, ypred, sigma_err::TS) where TS<:AbstractFloat
    T = eltype(ypred)
    @assert axes(ypred) == axes(y) == axes(sigma_err)
    n = length(y)
    ssr = zero(T)
    @inbounds for i in eachindex(lik.y)
        ssr += (ypred[i] - y[i])^2
    end

    (isnan(ssr) || isinf(ssr)) && return floatmax(T)
    T(1/2) * (n * log(T(2 * pi) * sigma_err^2) + ssr / sigma_err^2)
end

function randomize_parameters!(lik::GaussianLikelihood{T}) where {T}
    if lik.optimize_sigma
        lik.sigma_err = (rand(T) * T(0.9) + T(0.1)) * lik.sigma_y # random value between 0.1*std and 1.0*std
    end
    lik
end

function copy(lik::GaussianLikelihood{T}) where {T}
    if lik.optimize_sigma
        GaussianLikelihood{T}(lik.X, lik.y, lik.sigma_y, lik.sigma_err, true)
    else
        lik # no need to copy because it is immutable
    end
end

function extractparam(lik::GaussianLikelihood{T}) where {T}
    lik.optimize_sigma ? [lik.sigma_err] : T[]
end

function updateparam!(lik::GaussianLikelihood{T}, param) where {T}
    if lik.optimize_sigma
        @assert length(param) == 1
        lik.sigma_err = param[1]
    else
        @assert length(param) == 0
    end
end