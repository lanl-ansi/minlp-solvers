
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--file", "-f"
            help = "the minlplib data file (.jl)"
            required = true
        "--time-limit", "-t"
            help = "puts a time limit on the sovler"
            arg_type = Float64
        "--print-level", "-o"
            help = "controls terminal output verbosity"
            arg_type = Int64
    end

    return parse_args(s)
end

function print_result(m, status, file_path)
    file_name = split(file_path, '/')[end]

    nbin = 0
    nint = 0 

    for i in 1:JuMP.num_variables(m)
        vref = JuMP.VariableRef(m, JuMP.MOI.VariableIndex(i)) 
        JuMP.is_binary(vref) && (nbin += 1; continue)
        JuMP.is_integer(vref) && (nint += 1; continue)
    end 

    objbound = NaN
    try
        objbound = JuMP.objective_bound(m)
    catch
        @warn "the solver does not implement objective_bound"
    end

    
    solve_time = NaN
    try
        solve_time = JuMP.MOI.get(m, MOI.SolveTime())
    catch
        warn(LOGGER, "the solver does not provide a solve time.");
    end

    data = [
        "DATA",
        file_name,
        JuMP.num_variables(m),
        nbin,
        nint,
        JuMP.num_nl_constraints(m),
        JuMP.objective_sense(m),
        JuMP.objective_value(m),
        objbound,
        status,
        solve_time
    ]

    println(join(data, ", "))
end
