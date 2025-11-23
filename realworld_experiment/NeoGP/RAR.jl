using NeoGP
using PreallocationTools: get_tmp

# Reproduce
# https://arxiv.org/pdf/2301.04368

####### Likelihood
mutable struct RARLikelihood{T} <: NeoGP.AbstractLikelihood{T} 
    const X::Matrix{T} # gbar
    const log_gbar::Vector{T}
    const e_log_gbar2::Vector{T} 
    const log_gobs::Vector{T}
    const e_log_gobs2::Vector{T}
end

function RARLikelihood(data::Matrix{T}, varnames) where {T}
    RARLikelihood{T}(data[:, 1:1], data[:, 2], data[:, 3], data[:, 4], data[:, 5])
end

(lik::RARLikelihood)(indiv::NeoGP.AbstractIndividual, param::AbstractVector, buffers::NeoGP.InterpreterBuffers) = NeoGP.negloglik(lik, indiv, param, buffers)
NeoGP.numvar(lik::RARLikelihood) = 1
NeoGP.numobs(lik::RARLikelihood) = length(lik.log_gobs)

function NeoGP.negloglik(lik::RARLikelihood{T}, indiv, param::AbstractArray{TE}, buffers::NeoGP.InterpreterBuffers) where {T <: AbstractFloat, TE <: Real}
    # jacx = zeros(TE, NeoGP.numobs(lik), NeoGP.numvar(lik)) # TODO allocation
    jacx = get_tmp(buffers.jacx_buffer, TE)
    ypred = NeoGP.predict!(indiv, lik.X, param, buffers, nothing, jacx)
    jacx .*= lik.X .* T(log(10.0)) # chain rule to get d(pred)/d(log10(gbar))
    _negloglik(lik, ypred, @view jacx[:, 1])
end

function _negloglik(lik::RARLikelihood{T}, ypred, dypred_dloggbar) where {T <: AbstractFloat}
    nll = zero(eltype(ypred))
    @inbounds for i in eachindex(ypred)
        sigma2_tot = lik.e_log_gobs2[i] + dypred_dloggbar[i]^2 * lik.e_log_gbar2[i] # as in Eq. 3 of the paper
        nll += T(0.5) * ((lik.log_gobs[i] - ypred[i])^2 / sigma2_tot + log(T(2.0 * π) * sigma2_tot))
    end
    
    nll
end



# Custom individual type for cosmic chronometers test case from ESR paper (returns sqrt of evolved function)
mutable struct RARIndividual{T} <: NeoGP.AbstractIndividual{T}
    inner::NeoGP.Individual{T}
end

NeoGP.copy_indiv(indiv::RARIndividual{T}) where T = RARIndividual{T}(NeoGP.copy_indiv(indiv.inner))
NeoGP.extractparam(::Type{T}, indiv::RARIndividual) where {T <: AbstractFloat} = NeoGP.extractparam(T, indiv.inner)
NeoGP.updateparam!(indiv::RARIndividual, param::AbstractVector) = NeoGP.updateparam!(indiv.inner, param)
NeoGP.getlossfunction(indiv::RARIndividual) = NeoGP.getlossfunction(indiv.inner)
NeoGP.getprogram(indiv::RARIndividual) = NeoGP.getprogram(indiv.inner)

function NeoGP.predict!(indiv::RARIndividual, x::AbstractMatrix{TF}, param::AbstractVector{T}, buffers::NeoGP.InterpreterBuffers, jacp::Union{Nothing,AbstractMatrix}=nothing, jacx::Union{Nothing,AbstractMatrix}=nothing) where {TF <: AbstractFloat, T <: Real}
    # the main change for this custom individual: apply sqrt to the output
    @timeit NeoGP.global_timer "predict!" begin
        # d/dx log(abs(f(x))) = f'(x) / f(x)
        fx = NeoGP.predict!(indiv.inner, x, param, buffers, jacp, jacx)

        @inbounds if jacp !== nothing || jacx !== nothing
            for i in eachindex(fx)
                dres = TF(1.0 / log(10.0)) / fx[i]
                jacp !== nothing && (jacp[i, :] .*= dres)
                jacx !== nothing && (jacx[i, :] .*= dres)
            end
        end
        
        fx .= log10.(abs.(fx))
    end
end

function NeoGP.create_random(::Type{RARIndividual{T}}, params...) where T <: NeoGP.AbstractLikelihood
    inner = NeoGP.create_random(NeoGP.Individual{T}, params...)
    RARIndividual{T}(inner)
end

function NeoGP.crossover(parent1::RARIndividual{T}, parent2::RARIndividual{T}, params...) where T <: NeoGP.AbstractLikelihood
    newinner = NeoGP.crossover(parent1.inner, parent2.inner, params...)
    RARIndividual{T}(newinner)
end

function NeoGP.mutate!(indiv::RARIndividual, params...)
    NeoGP.mutate!(indiv.inner, params...)
    indiv
end

NeoGP.individual_length(indiv::RARIndividual) = NeoGP.individual_length(indiv.inner)
NeoGP.print_indiv(indiv::RARIndividual) = NeoGP.print_indiv(indiv.inner)

# We can calculate a description length for individuals 
# The second term (function complexity) is specific to the program representation.
# The first and the third term only work for individuals with likelihoods as loss functions
NeoGP.description_length(indiv::RARIndividual, buffers::NeoGP.InterpreterBuffers) = sum(NeoGP.description_length_terms(indiv, buffers))
NeoGP.description_length(indiv::RARIndividual) = sum(NeoGP.description_length_terms(indiv)) # convenience function

# Returns the three components of description length as a tuple: (negloglik, func_complexity, param_complexity)
# This allows specialization for custom individual types
function NeoGP.description_length_terms(indiv::RARIndividual)
    T = NeoGP.parametertype(NeoGP.getlossfunction(indiv))
    likelihood = NeoGP.getlossfunction(indiv)
    prog = NeoGP.getprogram(indiv)
    buffers = NeoGP.InterpreterBuffers(T, NeoGP.numobs(likelihood), NeoGP.numvar(likelihood), length(prog))

    NeoGP.description_length_terms(indiv, buffers)
end

function NeoGP.description_length_terms(indiv::RARIndividual, buffers::NeoGP.InterpreterBuffers)
    T = NeoGP.parametertype(NeoGP.getlossfunction(indiv))
    likelihood = NeoGP.getlossfunction(indiv)
    prog = NeoGP.getprogram(indiv)

    param = NeoGP.extractparam(T, indiv)

    p_compl = NeoGP.param_compl(likelihood, indiv, param, buffers)
    f_compl = NeoGP.func_compl(prog, buffers.symfreq)
    
    (likelihood(indiv, param, buffers), T(f_compl), p_compl)
end


#############################
# ROXY MNR likelihood for RAR
#############################

# ROXY (regression with errors in x and y) likelihood for NeoGP

####### Likelihood
mutable struct RARMNRLikelihood{T} <: NeoGP.AbstractLikelihood{T} 
    const X::Matrix{T} # gbar
    const log_gbar::Vector{T}
    const e_log_gbar2::Vector{T} 
    const log_gobs::Vector{T}
    const e_log_gobs2::Vector{T}
    
    sig2::T
    mugauss::T
    wgauss2::T
end

function RARMNRLikelihood(data::Matrix{T}, varnames) where {T}
    sig2 = T(0.1)^2
    mugauss = sum(data[:, 2]) / size(data, 1) # mean of gbar as initial guess
    wgauss2 = sum(abs2, data[:, 2] .- mugauss) / size(data, 1) # variance of gbar as initial guess
    RARMNRLikelihood{T}(data[:, 1:1], data[:, 2], data[:, 3], data[:, 4], data[:, 5], sig2, mugauss, wgauss2)
end

(lik::RARMNRLikelihood)(indiv::NeoGP.AbstractIndividual, param::AbstractVector, buffers::NeoGP.InterpreterBuffers) = NeoGP.negloglik(lik, indiv, param, buffers)
NeoGP.numvar(lik::RARMNRLikelihood) = 1
NeoGP.numobs(lik::RARMNRLikelihood) = length(lik.log_gobs)

function NeoGP.copy_lossfunction(lik::RARMNRLikelihood{T}) where {T}
    RARMNRLikelihood{T}(lik.X, lik.log_gbar, lik.e_log_gbar2, lik.log_gobs, lik.e_log_gobs2, lik.sig2, lik.mugauss, lik.wgauss2)
end

NeoGP.numparam(lik::RARMNRLikelihood) = 3 # sig, mugauss, wgauss

function NeoGP.randomize_parameters!(lik::RARMNRLikelihood{T}) where {T}
    lik.sig2 = rand(T) * lik.sig2
    lik.mugauss = randn(T) * T(10.0) + lik.mugauss
    lik.wgauss2 = rand(T) * T(10.0) + lik.wgauss2
    lik
end

function NeoGP.extractparam(lik::RARMNRLikelihood{T}) where {T}
    [sqrt(lik.sig2), lik.mugauss, sqrt(lik.wgauss2)]
end

function NeoGP.updateparam!(lik::RARMNRLikelihood{T}, param::AbstractVector{T}) where {T}
    @assert length(param) == NeoGP.numparam(lik)
    lik.sig2    = param[1]^2
    lik.mugauss = param[2]
    lik.wgauss2 = param[3]^2
    
    nothing
end


function NeoGP.negloglik(lik::RARMNRLikelihood{T}, indiv, param::AbstractArray{TE}, buffers::NeoGP.InterpreterBuffers) where {T <: AbstractFloat, TE <: Real}
    # jacx = zeros(TE, NeoGP.numobs(lik), NeoGP.numvar(lik)) # TODO allocation
    jacx = get_tmp(buffers.jacx_buffer, TE)
    ypred = NeoGP.predict!(indiv, lik.X, param, buffers, nothing, jacx)
    jacx .*= lik.X .* T(log(10.0)) # chain rule to get d(pred)/d(log10(gbar))
    _negloglik(lik, ypred, @view jacx[:, 1])
end

function _negloglik(lik::RARMNRLikelihood{T}, f, df) where {T <: AbstractFloat}
   # from ROXY (https://github.com/DeaglanBartlett/roxy/tree/main)
    # Computes the negative log-likelihood under the assumption of an uncorrelated
    # Gaussian likelihood with a Gaussian prior on the true x positions.
    # 
    #= ROXY nll_mnr:
    Ai = fprime
    Bi = f - Ai * xobs
    
    s2 = yerr ** 2 + sig ** 2
    den = Ai ** 2 * w_gauss ** 2 * xerr ** 2 + s2 * (w_gauss ** 2 + xerr ** 2)
    
    neglogP = (
        N / 2 * jnp.log(2 * jnp.pi)
        + 1/2 * jnp.sum(jnp.log(den))
        + 1/2 * jnp.sum(w_gauss ** 2 * (Ai * xobs + Bi - yobs) ** 2 / den)
        + 1/2 * jnp.sum(xerr ** 2 * (Ai * mu_gauss + Bi - yobs) ** 2 / den)
        + 1/2 * jnp.sum(s2 * (xobs - mu_gauss) ** 2 / den)
    )
    =#
    
    sig2 = lik.sig2
    mugauss = lik.mugauss
    wgauss2 = lik.wgauss2

    nll = zero(eltype(f))
    @inbounds for i in eachindex(f)
        xobs = lik.log_gbar[i]
        xerr2 = lik.e_log_gbar2[i]
        yobs = lik.log_gobs[i]
        yerr2 = lik.e_log_gobs2[i]
    
        ai = df[i]
        bi = f[i] - ai * xobs[i]
        
        s2 = yerr2 + sig2

        t1 = wgauss2 * (ai * xobs    + bi - yobs)^2
        t2 = xerr2 *   (ai * mugauss + bi - yobs)^2
        t3 = s2 * (xobs - mugauss)^2
        den = (ai * ai) * (wgauss2 * xerr2) + s2 * (wgauss2 + xerr2)
        
        nll += log(den) + (t1 + (t2 + t3)) / den
    end
    
    T(0.5) * nll + T(length(f)) / T(2.0) * log(T(2.0 * π))
end