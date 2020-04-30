include("./ArrayRW.jl")
include("./CustomLib.jl")
const HDir = pwd()*"\\History"

using Dates
#using TimeSeries

function Assess(period::Dates.Period,stream::Dict{String,Dict{String,Any}},eDict::Dict{String,UInt32},data::Matrix{UInt32},assets::Array{String,1},speaker::Channel{Tuple{Symbol,Array{Float64,1},Array{Float64,1}}})
    ve = Threads.@spawn evalA(stream,eDict,data,assets)
    r = Threads.@spawn readNArray("$HDir\\value.txt")
    vArray = fetch(r)
    value,elements = fetch(ve)
    vArray=vcat(vArray,[value datetime2unix(now())])
    w = Threads.@spawn writeNArray("$HDir\\value.txt",vArray)
    l = length(vArray)
    #t = from(TimeArray(unix2datetime.(vArray[(l÷2+1):l]),vArray[1:(l÷2)],[:USD_Value]),now()-period)
    fT = datetime2unix(now()-period)
    k=1
    l2 = l÷2
    for i in l2:-1:1
        if vArray[l2+i]<fT
            k =i+1
            break
        end
    end
    #gfx=plot() #for other backends
    #gfx = plot(t)
    wait(w)
    push!(speaker,(:totalValue,(vArray[(l2+k):1:l].-fT)./60^2,vArray[k:1:l2]))
    return (vArray[(l2+k):1:l].-fT)./60^2,vArray[k:1:l2]
end
