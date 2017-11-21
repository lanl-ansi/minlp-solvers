#!/usr/bin/env julia

using ArgParse

using AmplNLWriter
using CoinOptServices

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    lines = String[]

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]
        append!(lines, ["time_limit $(tl)"])
    end

    if parsed_args["print-level"] != nothing
        pl = parsed_args["print-level"]
        append!(lines, ["print_level $(pl)"])
    end

    # WARNING this is not parrallel safe
    open("couenne.opt", "w") do f
        for line in lines
            write(f, "$(line) \n")
        end
    end

    solver = CouenneNLSolver()

    setsolver(m, solver)

    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
  main(parse_commandline())
end
