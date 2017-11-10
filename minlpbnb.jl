#!/usr/bin/env julia

using ArgParse

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
        solver_args[:time_limit] = parsed_args["time-limit"]
    end

    if parsed_args["branch_strategy"] != nothing
        solver_args[:branch_strategy] = Symbol(parsed_args["branch_strategy"])
    end

    if parsed_args["strong_restart"] != nothing
        solver_args[:strong_restart] = parsed_args["strong_restart"]
    end

    if parsed_args["traverse_strategy"] != nothing
        solver_args[:traverse_strategy] = Symbol(parsed_args["traverse_strategy"])
    end

    if parsed_args["processors"] != nothing
        solver_args[:processors] = parsed_args["processors"]
    end


    solver = MINLPBnBSolver(nlp_solver; solver_args...)
    setsolver(m, solver)

    status = solve(m)

    print_result(m, status, parsed_args["file"])
end


function parse_commandline_bnb()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--file", "-f"
            help = "the minlplib data file (.jl)"
            required = true
        "--time-limit", "-t"
            help = "puts a time limit on the solver"
            arg_type = Float64
        "--branch_strategy"
            help = "branch strategy"
        "--strong_restart"
            help = "strong branching option"
            action = :store_true
        "--traverse_strategy"
            help = "traverse strategy"
        "--processors", "-p"
            help = "number of parallel processes to use"
            arg_type = Int
    end

    return parse_args(s)
end


if isinteractive() == false
    args = parse_commandline_bnb()
    if args["processors"] != nothing
        addprocs(args["processors"])
    end
    using MINLPBnB
    using Ipopt
    main(args)
end
