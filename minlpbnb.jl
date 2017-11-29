#!/usr/bin/env julia

using ArgParse

include("common.jl")

function main(parsed_args)
    nlp_solver_args = Dict{Symbol,Any}()

    if parsed_args["print-level"] != nothing
        nlp_solver_args[:print_level] = parsed_args["print-level"]
    else
        nlp_solver_args[:print_level] = 0
    end


    nlp_solver = IpoptSolver(; nlp_solver_args...)

    solver_args = Dict{Symbol,Any}()
    #solver_args[:log_levels] = [:Options, :Info, :Table]

    if parsed_args["time-limit"] != nothing
        solver_args[:time_limit] = parsed_args["time-limit"]
    end

    if parsed_args["branch_strategy"] != nothing
        solver_args[:branch_strategy] = Symbol(parsed_args["branch_strategy"])
    end

    if parsed_args["no_strong_restart"]
        solver_args[:strong_restart] = 0
    end

    if parsed_args["traverse_strategy"] != nothing
        solver_args[:traverse_strategy] = Symbol(parsed_args["traverse_strategy"])
    end

    if parsed_args["processors"] != nothing
        solver_args[:processors] = parsed_args["processors"]
    end

    solver = MINLPBnBSolver(nlp_solver; solver_args...)

    # julia compilation step
    include("data/ex1223a.jl")
    setsolver(m, solver)
    status = solve(m)

    include(parsed_args["file"])
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
        "--print-level", "-o"
            help = "controls terminal output verbosity"
            arg_type = Int64
        "--branch_strategy"
            help = "branch strategy"
        "--no_strong_restart"
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
