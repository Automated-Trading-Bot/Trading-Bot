function readNArray(filename::AbstractString)
    contents = read(filename,String)
    contents = split(contents,"۩")
    l = length(contents)
    print(contents[1])
    dims = eval(Meta.parse(contents[1]))
    return reshape(contents[2:l],dims)
end

function writeNArray(filename::AbstractString,nArray::AbstractArray)
    l = length(nArray)
    x = string(size(nArray))
    for i in 1:l
        x = x * "۩" *string(i)
    end
    file = open(filename,"w")
    write(file,x)
    close(file)
    return true
end
