"""
    readNArray(filename::AbstractString)

Read an array from filename and attempt to parse it as a Julia value (as written by `writeNArray`). Works for an array of any size.
"""
function readNArray(filename::AbstractString)
    contents = read(filename,String) #Read file
    contents = split(contents,"۩") #Split file by delimiter ۩ (unlikely to be in data)
    l = length(contents) #length of array + 1
    dims = eval(Meta.parse(contents[1])) #First element of file is the dimensions of the array. Parse this as a tuple using Julia metaprogramming.
    return Meta.parse.(reshape(contents[2:l],dims)) #Reshape linear array (contents) to array of dims specified and parse to a Julia value. Notice the broadcasting of the parse parse.()
end

"""
    safeReadNArray(filename::AbstractString)

Read an array from filename but do not attempt to parse it as a Julia value (as written by `writeNArray`). Works for any array.
"""
function safeReadNArray(filename::AbstractString)
    contents = read(filename,String)
    contents = split(contents,"۩")
    l = length(contents)
    dims = eval(Meta.parse(contents[1]))
    return reshape(contents[2:l],dims)
end

"""
    writeNArray(filename::AbstractString,nArray::AbstractArray)

Write an array to filename. Works for any array.
"""
function writeNArray(filename::AbstractString,nArray::AbstractArray)
    l = length(nArray) #length of array
    x = string(size(nArray)) #dimensions of array
    for i in 1:l
        x = x * "۩" *string(nArray[i]) #convert array to csv with dimensions at start
    end
    file = open(filename,"w")
    write(file,x) #Write to file
    close(file)
    return 0 #return value to show completion
end
