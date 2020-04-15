include("./ArrayRW.jl")
include("./CustomLib.jl")
HDir = pwd()*"\\History"

using Makie
using MakieThemes
using Dates

function Assess(period,stream,eDict,data,assets)
    ve = Threads.@spawn evalA(stream,eDict,data,assets)
    r = Threads.@spawn readNArray("$HDir\\value.txt")
    vArray = fetch(r)
    value,elements = fetch(ve)
    vArray = vcat(vArray,[value datetime2unix(now())])
    w = Threads.@spawn writeNArray("$HDir\\value.txt",vArray)
    l = length(vArray)
    fT = datetime2unix(now()-period)
    k=1
    l2 = l÷2
    for i in l2:-1:1
        if vArray[l2+i]<fT
            k =i+1
            break
        end
    end
    wait(w)
    return (vArray[(l2+k):1:l].-fT)./60^2,vArray[k:1:l2]
end
