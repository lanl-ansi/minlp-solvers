#!/usr/bin/env julia

using ArgParse

using JuMP
using AmplNLWriter

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    optoins = String[]
    append!(optoins, ["--obj_gap_percent"])
    append!(optoins, ["1e-2"])

    # seems to break things
    #append!(optoins, ["--fpump"])
    #append!(optoins, ["1"])

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]
        append!(optoins, ["--bnb_time_limit"])
        append!(optoins, ["$(tl)"])
    end

    if parsed_args["print-level"] != nothing
        pl = parsed_args["print-level"]
        append!(optoins, ["--log_level"])
        append!(optoins, ["$(pl)"])
    end

    solver = AmplNLSolver("msbnb", optoins)

    setsolver(m, solver)

    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
  main(parse_commandline())
end

