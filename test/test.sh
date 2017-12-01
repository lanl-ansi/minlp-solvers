#!/bin/bash

# Tests solvers

# Native Solver Interfaces
../baron.jl -f data/ex1223a.jl > /dev/null
../bonmin.jl -f data/ex1223a.jl > /dev/null
../couenne.jl -f data/ex1223a.jl > /dev/null
../juniper.jl -f data/ex1223a.jl > /dev/null

# NL Writer Interfaces
../bonmin-nlw.jl -f data/ex1223a.jl > /dev/null
../couenne-nlw.jl -f data/ex1223a.jl > /dev/null
../scip-nlw.jl -f data/ex1223a.jl > /dev/null
../knitro-nlw.jl -f data/ex1223a.jl > /dev/null
