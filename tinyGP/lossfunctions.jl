# Not used for now

function mean_squared_error(y,ypred)
    @assert axes(ypred) == axes(y)
    sumsq = zero(eltype(ypred))
    @inbounds for i in eachindex(y)
        sumsq += (ypred[i] - y[i])^2
    end
    sumsq / length(y)
end

# can be used as a loss function and must have the signature
# (::Likelihood, program::Vector{Instruction}, param::AbstractVector{T <: Real}, buffers::InterpreterBuffers)
function mean_squared_error(lik::Likelihood, prog, param, buffers)
    ypred = predict!(buffers, prog, lik.X, param)
    mean_squared_error(lik.y, ypred)
end

function r2_score(y, ypred)
    @assert axes(ypred) == axes(y)
    mean_y = sum(y) / length(y)
    ss_tot = zero(eltype(ypred))
    ss_res = zero(eltype(ypred))
    @inbounds for i in eachindex(y)
        ss_res += (ypred[i] - y[i])^2
        ss_tot += (y[i] - mean_y)^2
    end

    iszero(ss_tot) ? one(eltype(ypred)) : one(eltype(ypred)) - ss_res / ss_tot
end

function r2_score(lik::Likelihood, prog, param, buffers)
    ypred = predict!(buffers, prog, lik.X, param)
    r2_score(lik.y, ypred)
end
