#!/usr/bin/env julia

using ArgParse

using JuMP
using AmplNLWriter

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    optoins = String[]
    append!(optoins, ["mip_integral_gap_rel=1e-4"])

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]
        append!(optoins, ["mip_maxtime_real=$(tl)"])
    end

    if parsed_args["print-level"] != nothing
        pl = parsed_args["print-level"]
        append!(optoins, ["outlev=$(pl)"])
    end

    solver = AmplNLSolver("knitroampl", optoins)

    setsolver(m, solver)

    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
  main(parse_commandline())
end
