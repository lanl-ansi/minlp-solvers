#!/usr/bin/env julia
using JuMP
using ArgParse

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
    end

    return parse_args(s)
end


function main(parsed_args)

    m = include(parsed_args["file"])
    # this adds a model named m to the current scope

    # By default, always run with CPLEX
    parsed_args["cpxlib"] != nothing ? cpxlib = parsed_args["cpxlib"] : cpxlib = "libcplex1271.so"

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]
        solver = BaronSolver(LPSol=3, CplexLibName=cpxlib, MaxTime=tl)
    else
        solver = BaronSolver(LPSol=3, CplexLibName=cpxlib)
    end

    setsolver(m, solver)
    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
    main(parse_commandline_baron())
end
