#!/usr/bin/env julia

using ArgParse
using MINLPBnB
using Ipopt

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    nlp_solver_args = Dict{Symbol,Any}()
    nlp_solver_args[:print_level] = 0

    #nlp_solver_args[:tol] = 1e-6
    #if parsed_args["hsl"]
    #    nlp_solver_args[:linear_solver] = "ma57"
    #end
    nlp_solver = IpoptSolver(; nlp_solver_args...)


    solver_args = Dict{Symbol,Any}()
    if parsed_args["time-limit"] != nothing
        solver_args[:time_limit] = parse(Float64, parsed_args["time-limit"])
    end

    solver = MINLPBnBSolver(nlp_solver; solver_args...)
    setsolver(m, solver)

    status = solve(m)

    data = [
        "DATA",
        parsed_args["file"],
        getobjectivevalue(m),
        getobjbound(m),
        getobjgap(m),
        getsolvetime(m),
        status
    ]
    println(join(data, ", "))
end

if isinteractive() == false
  main(parse_commandline())
end