using NeoGP
using ForwardDiff

# Reproduce
# https://arxiv.org/pdf/2301.04368

####### Likelihood
mutable struct RARLikelihood{T} <: NeoGP.Likelihood{T} 
    const X::Matrix{T} # gbar
    const log_gbar::Vector{T}
    const e_log_gbar2::Vector{T} 
    const log_gobs::Vector{T}
    const e_log_gobs2::Vector{T}
end

function RARLikelihood(data::Matrix{T}, varnames) where {T}
    RARLikelihood{T}(data[:, 1:1], data[:, 2], data[:, 3], data[:, 4], data[:, 5])
end

Base.copy(lik::RARLikelihood) = lik

function NeoGP.negloglik(lik::RARLikelihood{T}, model_func::F, param::AbstractArray{TE}) where {T <: AbstractFloat, F <: Function, TE <: Real}
    ypred = model_func(param, lik.X)
    gbar = lik.X[:,1]
    @timeit NeoGP.global_timer "dypred_dgbar" dypred_dgbar = [ForwardDiff.derivative(_xi -> model_func(param, [_xi;;])[1], xi) for xi in gbar]
    dypred_dloggbar =  dypred_dgbar .* gbar .* T(log(10.0)) # chain rule to get d(pred)/d(log(gbar))
    _negloglik(lik, ypred, dypred_dloggbar) 
end


function _negloglik(lik::RARLikelihood{T}, ypred, dypred_dloggbar) where {T}
    nll = zero(eltype(ypred))
    for i in eachindex(ypred)
        sigma2_tot = lik.e_log_gobs2[i] + dypred_dloggbar[i]^2 * lik.e_log_gbar2[i] # as in Eq. 3 of the paper
        nll += T(0.5) * ((lik.log_gobs[i] - ypred[i])^2 / sigma2_tot + log(T(2.0 * π) * sigma2_tot))
    end
    return nll
end



####### Individual

# Custom individual type for RAR test case
mutable struct RARIndividual <: NeoGP.AbstractIndividual{RARLikelihood{Float32}}
    inner::NeoGP.Individual{RARLikelihood{Float32}}
end

Base.copy(indiv::RARIndividual) = RARIndividual(Base.copy(indiv.inner))

NeoGP.getlikelihood(indiv::RARIndividual) = NeoGP.getlikelihood(indiv.inner)
NeoGP.getprogram(indiv::RARIndividual) = NeoGP.getprogram(indiv.inner)

function NeoGP.create_random(::Type{RARIndividual}, params...)
    inner = NeoGP.create_random(NeoGP.Individual{NeoGP.GaussianLikelihood}, params...)
    RARIndividual(inner)
end

function NeoGP.crossover(parent1::RARIndividual, parent2::RARIndividual, params...)
    newinner = NeoGP.crossover(parent1.inner, parent2.inner, params...)
    RARIndividual(newinner)
end

function NeoGP.mutate!(indiv::RARIndividual, params...)
    NeoGP.mutate!(indiv.inner, params...)
end

function NeoGP.predict!(buffers::NeoGP.InterpreterBuffers, indiv::RARIndividual, X::AbstractMatrix, param::AbstractVector)
    log.(abs.(NeoGP.predict!(buffers, indiv.inner, X, param)))
end

