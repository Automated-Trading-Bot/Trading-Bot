module botMain
export Parent
include("./Assess.jl")



const n=4#loop complexity


const ΔUI = Dates.Minute(1) #UI refresh interval
const Δα = Dates.Second(5) #α calculation interval
const Δe = Dates.Millisecond(3000) #execution interval
const period = Dates.Day(1) #Plot display period
const Δp = Dates.Second(1) #Plot poll interval
const df = Dates.DateFormat("yyyy-mm-dd") #YahooFinance date format

function DummyFunction(string) #Dummy function for later replacement. Actual Functions will be in seperate
    println(string)
    return "Hello"
end

#Assess = DummyFunction #Asses account state
Execute = DummyFunction #Execute trades
Read = DummyFunction #Read from files
Algo = DummyFunction
#Algo("Compute α") #Initial alpha calculation
function Parent(speaker::Channel{Tuple{Symbol,Array{Float64,1},Array{Float64,1}}})

    time = fill(Dates.now()-Dates.Day(1),n) #Get starting time
    W = Threads.@spawn eval(0) #Completed task object
    W = fill(W,n+1) #Array of task objects initially completed
    c = [ΔUI,Δα,Δe,Δp]

    #GC.enable(false)

    #UI init

    counter::Int = 10
    counter2::Int = 0
    required::Bool = false

    #get Tickers and set up relational matrix for future reference
    tickers,assets,augAssets = getAssets()
    data,eDict = dist(assets,augAssets)
    tickersChannel = Channel{Array{Dict{String,Any},1}}(2^10)
    Tickers = initTickers()
    W[4] = Threads.@spawn Binance.wsTicker24Hr(tickersChannel)

    #Debug
    ycount = 0
    tcount = 0
    while true #Main refresh loop

        #Generate UI data from context
        if ((Dates.now()-time[1]) > ΔUI) && istaskdone(W[1]) #If specified interval has passed and previous attempt is completed
            interval = (Dates.now()-time[1])
            t = time[1]
            W[1] = Threads.@spawn Assess(period,Tickers,eDict,data,assets,speaker) #Assign one thread to display the UI (and asses account state)
            println("UI Update Initiated: $interval at $t")
            required = true
            time[1]=Dates.now() #Update execution time
        end

        #Update context and run algorithm
        if ((Dates.now()-time[2]) > Δα) && istaskdone(W[2]) #Ditto “
            interval = (Dates.now()-time[2])
            t = time[2]
            println("Algo Initiated: $interval at $t")
            if isready(tickersChannel)
                while isready(tickersChannel)
                    stream = take!(tickersChannel)
                    up(stream,Tickers)
                end
            elseif istaskdone(W[4]) || (counter2>100)
                counter2 = 0
                println("Channel empty, task done")
                #Check if the task has failed. If it it failed, check if it produces and expected html error code
                if istaskfailed(W[4])
                    println(dump(W[4]))
                    if ( !(hasproperty(W[4].result,:task) && hasproperty(W[4].result.task.result,:status)) || !(typeof(W[4].result.task.result.status) <: Number) || W[4].result.task.result.status ==  429 || W[4].result.task.result.status ==  418 || W[4].result.task.result.status <  400 || W[4].result.task.result.status > 600)
                        return W[4]
                    end
                end
                W[4] = Threads.@spawn Binance.wsTicker24Hr(tickersChannel)
            else
                counter2 +=1
                println("Channel empty, task in progress")
            end
            time[2]=Dates.now() #“
        end

        #Reallocate portfolio based on algorithm
        if ((Dates.now()-time[3]) > Δe) && istaskdone(W[3]) #“
            interval = (Dates.now()-time[3])
            t = time[3]
            println("PM Initiated: $interval at $t")
            W[3] = Threads.@spawn eval(0) #Assign one thread to execute trades
            time[3]=Dates.now() #“
        end
    end
    return 0
end #TODO: Tidy

end

#TODO: Paper trading infra
using Makie
using MakieThemes
AbstractPlotting.set_theme!(ggthemr(:flat_dark))
#function superMain()
    speaker = Channel{Tuple{Symbol,Array{Float64,1},Array{Float64,1}}}(2^10)

    Errorc=Threads.@spawn botMain.Parent(speaker) #TODO: Plot more information w/ MakieLayouts
    xx = Node([Point2f0(1,2),Point2f0(2,3)])
    gfx = lines(xx)
    display(gfx)

    while !istaskdone(Errorc)
        while isready(speaker)
            k=take!(speaker)
            if k[1] === :totalValue
                xx[]=Point2f0.(k[2],k[3])
                update!(gfx)
            end
        end
        GC.safepoint() # Signal to the compiler very strongly that this thread should do garbage collection
        yield() # ^^^
    end
    return Errorc
#end

j = superMain()
