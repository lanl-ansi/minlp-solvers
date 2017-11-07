#!/usr/bin/env julia

using ArgParse

using AmplNLWriter
using CoinOptServices

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]

        # WARNING this is not parrallel safe
        open("couenne.opt", "w") do f
            write(f, "time_limit $(tl)")
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
