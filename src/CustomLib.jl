using Binance,LightGraphs,SimpleWeightedGraphs
p = Meta.parse

if !haskey(ENV,"BINANCE_APIKEY") || !haskey(ENV,"BINANCE_APIKEY")
    error("Set ENV[\"BINANCE_APIKEY\"] and ENV[\"BINANCE_SECRET\"] to their relevant values.")
end

const apikey = ENV["BINANCE_APIKEY"]
const seckey = ENV["BINANCE_SECRET"]

#ADX for testing
function evalA(tickers::Dict{String,Dict{String,Any}},eDict::Dict{String,UInt32},data::Matrix{UInt32},assets::Vector{String},currency::String="USDT") #This too should be in libs
    bals::Vector{Dict{String,Any}}=Binance.balances(apikey,seckey)
    l = length(bals)
    value::Float64 = 0
    source::UInt32 = eDict[currency]
    dests::Vector{UInt32} = getindex.([eDict],getindex.(bals[1:end],"asset"))
    relations::Vector{Array{UInt32}} = link(data,source,dests)
    reqTickers = []
    for sequence in relations
        lSeq = length(sequence)
        for j in 1:(lSeq-1)
            a = assets[sequence[j]]
            b = assets[sequence[j+1]]
            if !("$a$b" in reqTickers) && "$a$b" in keys(tickers)
                push!(reqTickers,"$a$b")
            elseif !("$b$a" in reqTickers)
                push!(reqTickers,"$b$a")
            end
        end
    end
    values = Dict{String,Tuple{Float64,Float64}}()
    for key in keys(tickers)
        i = tickers[key]
        if i["s"] in reqTickers
            values[i["s"]] = p.((i["a"],i["b"]))
        end
    end
    for i in 1:l
        sequence = relations[i]
        lSeq = length(sequence)
        pArray = Vector{Float64}(undef,lSeq)
        pArray[1] = p(bals[i]["locked"])+p(bals[i]["free"])
        for j in 1:(lSeq-1)
            a = assets[sequence[j]]
            b = assets[sequence[j+1]]
            if ("$a$b" in reqTickers)
                pArray[j+1] =  inv(values["$a$b"][1])
            else
                pArray[j+1] = values["$b$a"][2]
            end
        end
        bals[i]["price"]= prod(pArray)
        value += prod(pArray)
    end
    return value,bals
end


function getAssets()
    data = Binance.getExchangeInfo()
    sData = data["symbols"]
    l = length(sData)
    tickers = Array{String,1}(undef,l)
    assets::Array{String,1} =  []
    augAssets = Array{Tuple{String,String},1}(undef,l)
    for i in 1:l
        tickers[i] = sData[i]["symbol"]
        if !(sData[i]["quoteAsset"] in assets)
            push!(assets,sData[i]["quoteAsset"])
        end
        if !(sData[i]["baseAsset"] in assets)
            push!(assets,sData[i]["baseAsset"])
        end
        augAssets[i] = (sData[i]["baseAsset"],sData[i]["quoteAsset"])
    end
    return tickers,assets,augAssets
end

function dist(assets::Array{String,1},augAssets::Array{Tuple{String,String},1})
    eDict = Dict{String,UInt32}()
    l = length(assets)
    for i in 1:l
        eDict[assets[i]]=i
    end
    l2 = length(augAssets)
    superAssets = Matrix{UInt32}(undef,l2,3)
    for i in 1:l2
        k1 = eDict[augAssets[i][1]]
        k2 = eDict[augAssets[i][2]]
        superAssets[i] = k1
        superAssets[l2+i] =k2
        superAssets[2l2+i]=1
    end
    return superAssets,eDict
end

function link(data::Matrix{UInt32},source::UInt32,dest::Array{UInt32,1})
    sources = Array{UInt32,1}(Int.(data[:,1]))
    destinations = Array{UInt32,1}(Int.(data[:,2]))
    weights = Array{UInt32,1}(data[:,3])
    g = SimpleWeightedGraph(sources, destinations, weights;combine=*)
    k = dijkstra_shortest_paths(g, source)
    return enumerate_paths.([k],dest)
end
#expect weighted path weight -- Note

function initTickers()
    init = Binance.get24HR()
    l = length(init)
    tickers = Dict{String,Dict{String,Any}}() #TODO: Consider Symbol/Char keys. Though Sym/Chr keys appear to cause much higher mem utlilisation.
    for i in init
        tick = Dict{String,Any}()
        tick["s"] = i["symbol"]
        tick["p"] = i["priceChange"]
        tick["P"] = i["priceChangePercent"]
        tick["w"] = i["weightedAvgPrice"]
        tick["x"] = i["prevClosePrice"]
        tick["c"] = i["lastPrice"]
        tick["Q"] = i["lastQty"]
        tick["b"] = i["bidPrice"]
        tick["a"] = i["askPrice"]
        tick["o"] = i["openPrice"]
        tick["h"] = i["highPrice"]
        tick["l"] = i["lowPrice"]
        tick["v"] = i["volume"]
        tick["q"] = i["quoteVolume"]
        tick["O"] = i["openTime"]
        tick["C"] = i["closeTime"]
        tick["F"] = i["firstId"]
        tick["L"] = i["lastId"]
        tick["n"] = i["count"]
        tick["B"] = NaN
        tick["A"] = NaN
        tick["E"] = 0
    tickers[tick["s"]] = tick
    end
    return tickers
end
#TODO: wrap in function
function up(stream::Array{Dict{String,Any},1},tickers::Dict{String,Dict{String,Any}},)
    for i in stream
        if haskey(tickers,i["s"])
            if tickers[i["s"]]["E"] < i["E"]
                tickers[i["s"]] = i
            end
        else
            tickers[i["s"]] = i
        end
    end
    return tickers
end
