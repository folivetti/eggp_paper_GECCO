

function mean_squared_error(y,ypred)
    @assert axes(ypred) == axes(y)
    sumsq = zero(eltype(ypred))
    @inbounds for i in eachindex(y)
        sumsq += (ypred[i] - y[i])^2
    end
    sumsq / length(y)
end

function mean_squared_error(param, indiv::Individual, gp, buffers)
    mean_squared_error(param, indiv.program, gp, buffers)
end

function mean_squared_error(param, prog, gp, buffers)
    ypred = predict!(buffers, prog, gp.X, param)
    mean_squared_error(gp.y, ypred)
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

function r2_score(param, indiv::Individual, gp, buffers)
    r2_score(param, indiv.program, gp, buffers)
end

function r2_score(param, prog, gp, buffers)
    ypred = predict!(buffers, prog, gp.X, param)
    r2_score(gp.y, ypred)
end
