using NeoGP

# Custom individual type for cosmic chronometers test case from ESR paper (returns sqrt of evolved function)
mutable struct CCIndividual{T} <: NeoGP.AbstractIndividual{T}
    inner::NeoGP.Individual{T}
end

NeoGP.copy_indiv(indiv::CCIndividual{T}) where T = CCIndividual{T}(NeoGP.copy_indiv(indiv.inner))
NeoGP.extractparam(indiv::CCIndividual) = NeoGP.extractparam(indiv.inner)
NeoGP.updateparam!(indiv::CCIndividual, param::AbstractVector) = NeoGP.updateparam!(indiv.inner, param)
NeoGP.getlossfunction(indiv::CCIndividual) = NeoGP.getlossfunction(indiv.inner)
NeoGP.getprogram(indiv::CCIndividual) = NeoGP.getprogram(indiv.inner)

function NeoGP.predict!(indiv::CCIndividual, x::AbstractMatrix, param::AbstractVector{T}, buffers::NeoGP.InterpreterBuffers, jacp::Union{Nothing,AbstractMatrix}=nothing, jacx::Union{Nothing,AbstractMatrix}=nothing) where T <: Real
    # the main change for this custom individual: apply sqrt to the output
    @timeit NeoGP.global_timer "predict!" begin
        # d/dx sqrt(abs(f(x))) = f(x) * f'(x) / (2 abs(f(x))^(3/2))
        fx = NeoGP.predict!(indiv.inner, x, param, buffers, jacp, jacx)

        if jacp !== nothing || jacx !== nothing
            for i in eachindex(fx)
                dres = fx[i] / (T(2.0) * abs(fx[i])^(T(3/2)))
                jacp !== nothing && (jacp[i, :] .*= dres)
                jacx !== nothing && (jacx[i, :] .*= dres)
            end
        end
        
        fx .= sqrt.(abs.(fx))
    end
end

function NeoGP.create_random(::Type{CCIndividual{T}}, params...) where T <: NeoGP.AbstractLikelihood
    inner = NeoGP.create_random(NeoGP.Individual{T}, params...)
    CCIndividual{T}(inner)
end

function NeoGP.crossover(parent1::CCIndividual{T}, parent2::CCIndividual{T}, params...) where T <: NeoGP.AbstractLikelihood
    newinner = NeoGP.crossover(parent1.inner, parent2.inner, params...)
    CCIndividual{T}(newinner)
end

function NeoGP.mutate!(indiv::CCIndividual, params...)
    NeoGP.mutate!(indiv.inner, params...)
    indiv
end

NeoGP.individual_length(indiv::CCIndividual) = NeoGP.individual_length(indiv.inner)
NeoGP.print_indiv(indiv::CCIndividual) = NeoGP.print_indiv(indiv.inner)

# We can calculate a description length for individuals 
# The second term (function complexity) is specific to the program representation.
# The first and the third term only work for individuals with likelihoods as loss functions
NeoGP.description_length(indiv::CCIndividual, buffers::NeoGP.InterpreterBuffers) = sum(NeoGP.description_length_terms(indiv, buffers))
NeoGP.description_length(indiv::CCIndividual) = sum(NeoGP.description_length_terms(indiv)) # convenience function

# Returns the three components of description length as a tuple: (negloglik, func_complexity, param_complexity)
# This allows specialization for custom individual types
function NeoGP.description_length_terms(indiv::CCIndividual)
    T = NeoGP.parametertype(NeoGP.getlossfunction(indiv))
    likelihood = NeoGP.getlossfunction(indiv)
    prog = NeoGP.getprogram(indiv)
    buffers = NeoGP.InterpreterBuffers(T, NeoGP.numobs(likelihood), NeoGP.numvar(likelihood), length(prog))

    NeoGP.description_length_terms(indiv, buffers)
end

function NeoGP.description_length_terms(indiv::CCIndividual, buffers::NeoGP.InterpreterBuffers)
    T = NeoGP.parametertype(NeoGP.getlossfunction(indiv))
    likelihood = NeoGP.getlossfunction(indiv)
    prog = NeoGP.getprogram(indiv)

    param = NeoGP.extractparam(T, indiv)

    p_compl = NeoGP.param_compl(likelihood, indiv, param, buffers)
    f_compl = NeoGP.func_compl(prog, buffers.symfreq)
    
    (likelihood(indiv, param, buffers), T(f_compl), p_compl)
end
