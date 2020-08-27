#=
Library backend proxy for paper trading.
=#
if backend == :Binance
    if !haskey(ENV,"BINANCE_APIKEY") || !haskey(ENV,"BINANCE_APIKEY")
        error("Set ENV[\"BINANCE_APIKEY\"] and ENV[\"BINANCE_SECRET\"] to their relevant values.")
    end
    
    const apikey = ENV["BINANCE_APIKEY"]
    const seckey = ENV["BINANCE_SECRET"]
    
    using Binance

    function getSymbols()
        data = Binance.getExchangeInfo()
        return data["symbols"]
    end

    function get24HRdata()
        return Binance.get24HR()
    end

    if paper

        function writeBalances(bals::Vector{Dict{String,Any}})
            l = length(bals)
            balsMatrix = Matrix{String}(undef,l,3)
            for i in 1:l
                balsMatrix[i]=bals[i]["locked"]
                balsMatrix[i+l]=bals[i]["free"]
                balsMatrix[i+2l]=bals[i]["asset"] 
            end
            HDir = pwd()*"/Paper"
            writeNArray("$HDir/value.txt",balsMatrix)
            return 0
        end

        function readBalances()
            HDir = pwd()*"/Paper"
            balsMatrix::Matrix{String} = safeReadNArray("$HDir/value.txt")
            l = size(balsMatrix)[1]
            bals = Vector{Dict{String,Any}}(undef,l)
            for i in 1:l
                bals[i] = Dict{String,Any}(
                "locked"=>balsMatrix[i],
                "free"=>balsMatrix[i+l],
                "asset"=>balsMatrix[i+2l]
                )
            end
            return bals
        end

        function getBalances(apikey::String,seckey::String)
            bals = readBalances()


            return bals
        end

        function limitOrder(symbol::String,quantity::Float64,price::Float64)
            # [BTCUSDT 1 0 false] Matrix
            HDir = pwd()*"/Paper"
            orderBook::Matrix{Union{String,Float64,Bool}} = readNArray("$HDir/orderBook.txt")
            orderBook = vcat(orderBook, [symbol quantity price false])
            writeNArray("$HDir/orderBook.txt",orderBook)
        end

        function up(stream::Array{Dict{String,Any},1},tickers::Dict{String,Dict{String,Any}},)
            HDir = pwd()*"/Paper"
            orderBook::Matrix{Union{Symbol,Float64,Bool}} = readNArray("$HDir/orderBook.txt")
            l = length(orderBook)
            orders = string.(orderBook[1:4:l])
            for i in stream
                if haskey(tickers,i["s"])
                    if tickers[i["s"]]["E"] < i["E"]
                        tickers[i["s"]] = i
                        if i["s"] in orders
                            n=5
                            for j in 1:(l÷4)
                                if i["s"] == orders[j]
                                    n=j
                                    break
                                end
                            end
                            if (!orderBook[4n]) && Meta.parse(i["v"]) >= orderBook[4n-2] && ((orderBook[4n-2] > 0 && Meta.parse(i["a"]) < orderBook[4n-1]) || (orderBook[4n-2] < 0 && Meta.parse(i["b"]) > orderBook[4n-1]))
                                orderBook[4n]=true #TODO: Investigate partial fulfillment
                            end
                        end
                    end
                else
                    tickers[i["s"]] = i
                end
            end
            writeNArray("$HDir/orderBook.txt",orderBook)
            return tickers
        end
        
    else

        function getBalances(apikey::String,seckey::String)
            bals::Vector{Dict{String,Any}} = Binance.balances(apikey,seckey)
            return bals
        end

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

    end

end