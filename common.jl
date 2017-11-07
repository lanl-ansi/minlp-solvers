function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--file", "-f"
            help = "the minlplib data file (.jl)"
            required = true
        "--time-limit", "-t"
            help = "puts a time limit on the sovler"
            arg_type = Float64
    end

    return parse_args(s)
end

function print_result(m, status, file_path)
    file_name = split(file_path, '/')[end]
    data = [
        "DATA",
        file_name,
        getobjectivesense(m),
        getobjectivevalue(m),
        status,
        #getobjbound(m),
        #getobjgap(m),
        getsolvetime(m)
    ]
    println(join(data, ", "))
end
