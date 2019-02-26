#!/usr/bin/env julia

using ArgParse, JuMP, MathOptInterface

function solve(m::Model)
    JuMP.optimize!(m)
    bm = JuMP.backend(m)
    return MOI.get(bm, MOI.TerminationStatus()) 
end 

function internalmodel(m::Model)
    bm = JuMP.backend(m)
    return bm.optimizer.model.inner
end

function getsolvetime(m::Model)
    bm = JuMP.backend(m)
    return MOI.get(bm, MOI.SolveTime()) 
end

function main(parsed_args)
    nlp_solver_args = Dict{Symbol,Any}()
    nlp_solver = nothing
    nlp_print_level = 0
    if !parsed_args["knitro"]
        if parsed_args["print-level"] != nothing
            nlp_print_level = parsed_args["print-level"]
        end

        nlp_solver = with_optimizer(Ipopt.Optimizer, print_level=nlp_print_level)
    else
        if parsed_args["print-level"] != nothing
            nlp_print_level = parsed_args["print-level"]
        else
            nlp_solver_args[:KTR_PARAM_OUTLEV] = 0
        end

        nlp_solver = with_optimizer(Knitro.Optimizer, KTR_PARAM_OUTLEV=nlp_print_level)
    end


    solver_args = Dict{Symbol,Any}()
    solver_args[:nl_solver] = nlp_solver

    if !parsed_args["no_fp"]
        solver_args[:mip_solver] = with_optimizer(Cbc.Optimizer, logLevel=0)
        if parsed_args["fp_glpk"]
            solver_args[:mip_solver] = with_optimizer(GLPK.Optimizer)
        end
        if parsed_args["fp_grb"]
            solver_args[:mip_solver] = with_optimizer(Gurobi.Optimizer, OutputFlag=0)
        end
    end
   
    if parsed_args["mu"] != nothing
        solver_args[:gain_mu] = parsed_args["mu"]
    end

    if parsed_args["strong-total-time"] != nothing
       solver_args[:strong_branching_total_time_limit] = parsed_args["strong-total-time"]
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

    if parsed_args["debug"]
        debug_dir = "debug_dir"
        if parsed_args["debug_dir"] != nothing
            debug_dir = parsed_args["debug_dir"]
        end
        if !ispath(debug_dir)
            mkpath(debug_dir)
        end
        solver_args[:debug] = true
        solver_args[:debug_write] = true
        instance_name = split(parsed_args["file"],'/')[end][1:end-3] # remove .jl
        solver_args[:debug_file_path] = debug_dir*"/"*instance_name*".json"
    end

    if parsed_args["processors"] != nothing
        solver_args[:processors] = parsed_args["processors"]
    end

    solver = with_optimizer(Juniper.Optimizer, solver_args)

    # julia compilation step
    include("data/ex1223a.jl")
    set_optimizer(m, solver)
    optimize!(m)

    include(parsed_args["file"])
    set_optimizer(m, solver)
    status = solve(m)
 
    internal = internalmodel(m)

    file_name = split(parsed_args["file"],"/")[end]
    data = [
        parsed_args["file"],
        file_name,
        internal.num_var,
        internal.nbinvars,
        internal.nintvars,
        internal.num_constr,
        internal.obj_sense,
        JuMP.objective_value(m),
        JuMP.objective_bound(m),
        status,
        getsolvetime(m)
    ]

    println(join(data, ", "))
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
        "--debug"
            help = "write a debug file"
            action = :store_true
        "--debug_dir"
            help = "debug folder only if --debug"
        "--processors", "-p"
            help = "number of parallel processes to use"
            arg_type = Int
        "--mu"
            help = "mu parameter for gain score"
            arg_type = Float64
        "--strong-total-time"
            help = "Total time limit for strong branching"
            arg_type = Float64
    end

    return parse_args(s)
end


if isinteractive() == false
    args = parse_commandline_bnb()
    if args["processors"] != nothing
        addprocs(args["processors"])
    end
    using Juniper
    using Ipopt
    using Cbc
    using GLPKMathProgInterface
    #using Gurobi
    #using KNITRO
    main(args)
end
