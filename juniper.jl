#!/usr/bin/env julia

using ArgParse

include("common.jl")

function main(parsed_args)
    nlp_solver_args = Dict{Symbol,Any}()

    if !parsed_args["knitro"]
        if parsed_args["print-level"] != nothing
            nlp_solver_args[:print_level] = parsed_args["print-level"]
        else
            nlp_solver_args[:print_level] = 0
        end

        nlp_solver = with_optimizer(Ipopt.Optimizer; nlp_solver_args...)
    else
        if parsed_args["print-level"] != nothing
            nlp_solver_args[:KTR_PARAM_OUTLEV] = parsed_args["print-level"]
        else
            nlp_solver_args[:KTR_PARAM_OUTLEV] = 0
        end

        nlp_solver = KnitroSolver(; nlp_solver_args...)
    end

    solver_args = Dict{Symbol,Any}()

    if !parsed_args["no_fp"]
        solver_args[:mip_solver] = with_optimizer(Cbc.Optimizer, logLevel=0)
        if parsed_args["fp_glpk"]
            solver_args[:mip_solver] = GLPKSolverMIP()
        end
        if parsed_args["fp_grb"]
            solver_args[:mip_solver] = GurobiSolver(OutputFlag=0)
        end
    end

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

    if parsed_args["incumbent_constr"]
        solver_args[:incumbent_constr] = true
    end

    if parsed_args["processors"] != nothing
        solver_args[:processors] = parsed_args["processors"]
    end

    #solver = JuniperSolver(nlp_solver; solver_args...)

    solver = with_optimizer(
        Juniper.Optimizer,
        nl_solver=nlp_solver;
        solver_args...
    )

    # julia compilation step
    include("data/ex1223a.jl")
    JuMP.optimize!(m, solver)
    status = JuMP.termination_status(m)

    include(parsed_args["file"])
    JuMP.optimize!(m, solver)
    status = JuMP.termination_status(m)

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
        "--incumbent_constr"
            help = "incumbent constraint option"
            action = :store_true
        "--branch_strategy"
            help = "branch strategy"
        "--no_strong_restart"
            help = "strong branching option"
            action = :store_true
        "--traverse_strategy"
            help = "traverse strategy"
        "--no_fp"
            help = "no feasibility pump"
            action = :store_true
        "--fp_glpk"
            help = "feasibility pump using glpk"
            action = :store_true
        "--fp_grb"
            help = "feasibility pump using gurobi"
            action = :store_true
        "--knitro"
            help = "use knitro as the nlp solver"
            action = :store_true
        "--processors", "-p"
            help = "number of parallel processes to use"
            arg_type = Int
    end

    return parse_args(s)
end


if isinteractive() == false
    args = parse_commandline_bnb()
    using Distributed
    if args["processors"] != nothing
        addprocs(args["processors"])
    end
    using JuMP
    using Juniper
    using Ipopt
    using Cbc
    #using GLPKMathProgInterface
    #using Gurobi
    #using KNITRO
    main(args)
end
