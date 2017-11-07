#!/usr/bin/env julia

using ArgParse

using AmplNLWriter
using CoinOptServices

include("common.jl")

function main(parsed_args) 
    include(parsed_args["file"])
    # this adds a model named m to the current scope

    if parsed_args["time-limit"] != nothing
        tl = parsed_args["time-limit"]
        solver = BonminNLSolver(["bonmin.time_limit=$(tl)"])
        #solver = BonminNLSolver(["bonmin.time_limit=$(tl)", "max_cpu_time=$(tl)", "bonmin.nlp_log_level=2", "bonmin.bb_log_level=5", "bonmin.bb_log_interval=1", "print_level=5"])
    else
        solver = BonminNLSolver()
    end

    setsolver(m, solver)

    status = solve(m)

    print_result(m, status, parsed_args["file"])
end

if isinteractive() == false
  main(parse_commandline())
end
