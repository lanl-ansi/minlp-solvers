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

    nbin = sum(m.colCat .== :Bin)
    nint = sum(m.colCat .== :Int)

    objbound = NaN
    try
        objbound = getobjbound(m)
    catch
        warn("the solver does not implement getobjbound")
    end

    data = [
        "DATA",
        file_name,
        MathProgBase.numvar(m),
        nbin,
        nint,
        MathProgBase.numconstr(m),
        getobjectivesense(m),
        getobjectivevalue(m),
        objbound,
        status,
        getsolvetime(m)
    ]

    println(join(data, ", "))
end
