#!/usr/bin/env julia

using ArgParse, JuMP

include("common.jl")

using Juniper.MathOptInterface

function main(parsed_args)
    # fill a meta file with all information
    meta = Dict{Symbol,Any}()
    meta[:date] = Dates.today() 
    # remove /src in the end
    pkg_dir = dirname(pathof(Juniper))[1:end-4]
    meta[:version] = Pkg.TOML.parsefile(pkg_dir*"/Project.toml")["version"]
    meta[:julia_version] = string(VERSION)
    meta[:hash] = Git.head(;dir=pkg_dir)
    meta[:branch] = Git.branch(;dir=pkg_dir)
    # display name for BnBVisual: 
    display_name = "juniper"
    if parsed_args["processors"] != nothing
        display_name = "$(display_name) -p $(parsed_args["processors"])"
    end
    display_name = " v$(meta[:version])"
    if meta[:branch] != "master"
        display_name = " ($(meta[:branch]))"
    end
    meta[:display] = display_name
    meta[:settings] = Dict{Symbol,Any}()

    nlp_solver_args = Dict{Symbol,Any}()
    nlp_solver = nothing
    if !parsed_args["knitro"]
        if parsed_args["print-level"] != nothing
            nlp_solver_args[:print_level] = parsed_args["print-level"]
        else 
            nlp_solver_args[:print_level] = 0
        end
        meta[:settings][:nlp_solver] = "Ipopt"
        nlp_solver = with_optimizer(Ipopt.Optimizer; nlp_solver_args...)
    else
        if parsed_args["print-level"] != nothing
            nlp_solver_args[:KTR_PARAM_OUTLEV] = parsed_args["print-level"]
        else
            nlp_solver_args[:KTR_PARAM_OUTLEV] = 0
        end
        meta[:settings][:nlp_solver] = "Knitro"
        nlp_solver = with_optimizer(Knitro.Optimizer; nlp_solver_args...)
    end


    solver_args = Dict{Symbol,Any}()
    solver_args[:nl_solver] = nlp_solver

    if !parsed_args["no_fp"]
        solver_args[:mip_solver] = with_optimizer(Cbc.Optimizer, logLevel=0)
        meta[:settings][:mip_solver] = "Cbc"
        if parsed_args["fp_glpk"]
            solver_args[:mip_solver] = with_optimizer(GLPK.Optimizer)
            meta[:settings][:mip_solver] = "GLPK"
        end
        if parsed_args["fp_grb"]
            solver_args[:mip_solver] = with_optimizer(Gurobi.Optimizer, OutputFlag=0)
            meta[:settings][:mip_solver] = "Gurobi"
        end
    else
        meta[:settings][:mip_solver] = "NONE"
    end
   
    if parsed_args["mu"] != nothing
        solver_args[:gain_mu] = parsed_args["mu"]
        meta[:settings][:gain_mu] = parsed_args["mu"]
    end

    if parsed_args["strong-total-time"] != nothing
       solver_args[:strong_branching_total_time_limit] = parsed_args["strong-total-time"]
       meta[:settings][:strong_branching_total_time_limit] = parsed_args["strong-total-time"]
    end

    if parsed_args["time-limit"] != nothing
        solver_args[:time_limit] = parsed_args["time-limit"]
        meta[:settings][:time_limit] = parsed_args["time-limit"]
    end

    if parsed_args["branch_strategy"] != nothing
        solver_args[:branch_strategy] = Symbol(parsed_args["branch_strategy"])
        meta[:settings][:branch_strategy] = Symbol(parsed_args["branch_strategy"])
    end

    if parsed_args["no_strong_restart"]
        solver_args[:strong_restart] = 0
        meta[:settings][:strong_restart] = 0
    end

    if parsed_args["traverse_strategy"] != nothing
        solver_args[:traverse_strategy] = Symbol(parsed_args["traverse_strategy"])
        meta[:settings][:traverse_strategy] = Symbol(parsed_args["traverse_strategy"])
    end

    if parsed_args["incumbent_constr"]
        solver_args[:incumbent_constr] = true
        meta[:settings][:incumbent_constr] = true
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
        meta[:settings][:processors] = parsed_args["processors"]
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

    # write meta file only once
    if parsed_args["meta-file"] != nothing && !isfile(parsed_args["meta-file"])
        write(parsed_args["meta-file"], JSON.json(meta))
    end

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
        "--debug"
            help = "write a debug file"
            action = :store_true
        "--debug_dir"
            help = "debug folder only if --debug"
        "--meta-file"
            help = "path and file name of the meta file"
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
    using Distributed
    if args["processors"] != nothing
        addprocs(args["processors"])
    end
    using Juniper
    using Ipopt
    using Cbc
    using JSON
    using Dates
    using Pkg
    using Git
    #using GLPKMathProgInterface
    #using Gurobi
    #using KNITRO
    main(args)
end
