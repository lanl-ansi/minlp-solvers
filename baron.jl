#!/usr/bin/env julia

using ArgParse

using JuMP
using BARON

include("common.jl")

function parse_commandline_baron()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--file", "-f"
            help = "the minlplib data file (.jl)"
            required = true
        "--cpxlib", "-c"
            help = "cplex lib name (must be included in path)"
            arg_type = AbstractString
        "--time-limit", "-t"
            help = "puts a time limit on the sovler"
            arg_type = Float64
        "--print-level", "-o"
            help = "controls terminal output verbosity"
            arg_type = Int64
    end

    return parse_args(s)
end


function main(parsed_args)
    m = include(parsed_args["file"])
    # this adds a model named m to the current scope

    baron_args = Dict{Symbol,Any}()

    # by default, always run with ...
    baron_args[:LPSol] = 3

    # by default, always run with CPLEX
    baron_args[:CplexLibName] = "libcplex1271.so"

    if parsed_args["cpxlib"] != nothing
        baron_args[:CplexLibName] = parsed_args["cpxlib"]
    end

    if parsed_args["time-limit"] != nothing
        baron_args[:MaxTime] = parsed_args["time-limit"]
    end

    if parsed_args["print-level"] != nothing
        baron_args[:PrLevel] = parsed_args["print-level"]
    end

    solver = BaronSolver(; baron_args...)

    setsolver(m, solver)
    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
    main(parse_commandline_baron())
end
