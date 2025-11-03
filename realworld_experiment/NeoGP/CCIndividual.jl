using NeoGP

# Custom individual type for cosmic chronometers test case from ESR paper (returns sqrt of evolved function)
mutable struct CCIndividual <: NeoGP.AbstractIndividual{NeoGP.GaussianLikelihood{Float32}}
    inner::NeoGP.Individual{NeoGP.GaussianLikelihood{Float32}}
end

Base.copy(indiv::CCIndividual) = CCIndividual(Base.copy(indiv.inner))

NeoGP.getlikelihood(indiv::CCIndividual) = NeoGP.getlikelihood(indiv.inner)
NeoGP.getprogram(indiv::CCIndividual) = NeoGP.getprogram(indiv.inner)

function NeoGP.create_random(::Type{CCIndividual}, params...)
    inner = NeoGP.create_random(NeoGP.Individual{NeoGP.GaussianLikelihood}, params...)
    CCIndividual(inner)
end

function NeoGP.crossover(parent1::CCIndividual, parent2::CCIndividual, params...)
    newinner = NeoGP.crossover(parent1.inner, parent2.inner, params...)
    CCIndividual(newinner)
end

function NeoGP.mutate!(indiv::CCIndividual, params...)
    NeoGP.mutate!(indiv.inner, params...)
end

function NeoGP.predict!(buffers::NeoGP.InterpreterBuffers, indiv::CCIndividual, X::AbstractMatrix, param::AbstractVector)
    # the main change for this custom individual: apply sqrt to the output
    sqrt.(abs.(NeoGP.predict!(buffers, indiv.inner, X, param)))
end