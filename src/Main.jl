module botMain
export Parent
import YahooFinance:get_symbols
import YahooFinance:values
include("./Assess.jl")
n=4#loop complexity
time = fill(Dates.now()-Dates.Day(1),n) #Get starting time
W = Threads.@spawn eval(0) #Completed task object
W = fill(W,n) #Array of task objects initially completed

ΔUI = Dates.Minute(1) #UI refresh interval
Δα = Dates.Second(5) #α calculation interval
Δe = Dates.Second(3) #execution interval
period = Dates.Day(1) #Plot display period
Δp = Dates.Second(1) #Plot poll interval
AbstractPlotting.set_theme!(ggthemr(:flat_dark))

df = Dates.DateFormat("yyyy-mm-dd") #YahooFinance date format

function DummyFunction(string) #Dummy function for later replacement. Actual Functions will be in seperate
    println(string)
    return "Hello"
end

#Assess = DummyFunction #Asses account state
Execute = DummyFunction #Execute trades
Read = DummyFunction #Read from files
Algo = DummyFunction

Read("Read historical info") #Read information from files
#Algo("Compute α") #Initial alpha calculation

function Parent()

    #UI init
    xx = Node([Point2f0(1,2),Point2f0(2,3)])
    counter = 10
    gfx = lines(xx)
    display(gfx)
    required = false

    #get Tickers and set up relational matrix for future reference
    tickers,assets,augAssets = getAssets()
    data,eDict = dist(assets,augAssets)
    tickersChannel = Channel(15)
    Tickers = initTickers()
    @async Binance.wsTicker24Hr(tickersChannel)

    while true #Main refresh loop
        if ((Dates.now()-time[1]) > ΔUI) && istaskdone(W[1]) #If specified interval has passed and previous attempt is completed
            interval = (Dates.now()-time[1])
            W[1] = Threads.@spawn Assess(period,Tickers,eDict,data,assets) #Assign one thread to display the UI (and asses account state)
            println("UI Update Initiated: $interval")
            required = true
            time[1]=Dates.now() #Update execution time
        end
        if ((Dates.now()-time[2]) > Δα) && istaskdone(W[2]) #Ditto “
            interval = (Dates.now()-time[2])
            println("Algo Initiated: $interval")
            stream = take!(tickersChannel)
            up(stream,Tickers)
            #W[2] = Threads.@spawn Algo(tickers,df) #Assign one thread to calculate alpha. May be increased to variable number of threads in future
            time[2]=Dates.now() #“
        end
        if ((Dates.now()-time[3]) > Δe) && istaskdone(W[3]) #“
            #W[3] = Threads.@spawn Execute("Execute Trades") #Assign one thread to execute trades
            time[3]=Dates.now() #“
        end
        if required && ((Dates.now()-time[4]) > Δp) && istaskdone(W[1])
            required = false
            output = []
            try
                output=fetch(W[1])
            catch e
                println("broke")
                return W[1]
            end
            xx[]=Point2f0.(output[1],output[2])
            time[4]=now()
            counter+=1
            if counter > 10
                counter = 0
                update!(gfx)
            end
        end
        yield()
    end
    return 0
end

end
#x=Threads.@spawn botMain.Parent()
#fetch(x)
e=botMain.Parent()
