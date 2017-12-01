#!/usr/bin/env julia

using ArgParse

using JuMP
using AmplNLWriter

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    lines = String[]

    append!(lines, ["heuristics/subnlp/nlpoptfile = \"ipopt.opt\""])
    append!(lines, ["limits/gap = 1e-4"])

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]
        append!(lines, ["limits/time = $(tl)"])
    end

    if parsed_args["print-level"] != nothing
        pl = parsed_args["print-level"]
        append!(lines, ["display/verblevel = $(pl)"])
    end

    # WARNING this is not parrallel safe
    open("scip.set", "w") do f
        for line in lines
            write(f, "$(line) \n")
        end
    end

    solver = AmplNLSolver("scipampl")

    setsolver(m, solver)

    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
  main(parse_commandline())
end
