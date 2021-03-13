using PaddedViews
using PyCall
using Infinity

comping = pyimport(comping)


#Computes final image size
function calcFinalSize(ninput::Int, stride::Int, gabSize::Int, padding::String)
    p = 0
    if (padding=="one")
        p = 1
    elseif (padding =="zeros")
        p = 1
    elseif (padding == "none")
    else
        @assert false "padding only supported to be none or same"
    end

    return floor((ninput + 2*p - gabSize)/(stride)) + 1
end

#Adds padding to an image
function addPadding(image, padding)
    if (padding=="none")
    elseif (padding == "one")
        image = PaddedView(1, image, (size(image)[1], size(image)[1]))
    elseif (padding == "zeros")
        image = PaddedView(0, image, (size(image)[1], size(image)[1]))
    else
        @assert false "padding only supported to be none or same"
    end

    return image
end

#Perfoms winnerTakesAll convolution, given a gabor filter bank and an image
function winnerConv(image, gaborBank, stride::Int=1, padding::String="full")

    sizeBank, filter_r, filter_c = size(gaborBank)

    if (filter_r != filter_c)
        throw(DomainError(gaborBank, "Filter row and column should be the same"))
    end

    outSize = calcFinalSize(input_r, stride, filter_r, padding)
    result = zeros(outSize, outSize)
    image = addPadding(image, padding)
    input_r, input_c = size(image)
    start = 1
    if (padding == "none")
        start = 0
    end

    for i in 1:input_r
        for j in 1:input_c
            measures = [0, -∞]
            imageToCompare = image[i+start: i+filter_r, j+start:j+filter_c]
            for k in 1:sizeBank
                val = comping.similarity.SSIM().compare(imageToCompare, gaborBank[k, :, :])
                if val > measures[2]
                    measures = [k, val]
                end
            end
            result[i, j] = measures[1]
        end
    end

    return result
end


#Perfoms AverageConv convolution, given a gabor filter bank and an image
function avgConv(image, gaborBank, stride::Int=1, padding::String="full")

    sizeBank, filter_r, filter_c = size(gaborBank)

    if (filter_r != filter_c)
        throw(DomainError(gaborBank, "Filter row and column should be the same"))
    end

    outSize = calcFinalSize(input_r, stride, filter_r, padding)
    result = zeros(outSize*sizeBank, outSize*sizeBank)
    image = addPadding(image, padding)
    input_r, input_c = size(image)
    start = 1
    if (padding == "none")
        start = 0
    end

    for i in 1:input_r
        for j in 1:input_c
            measures = zeros(sizeBank)
            imageToCompare = image[i+start: i+filter_r, j+start:j+filter_c]
            for k in 1:sizeBank
                val = comping.similarity.SSIM().compare(imageToCompare, gaborBank[k, :, :])
                measures[k] = val
            end
            result[(i-1)*sizeBank: i*sizeBank, (j-1)*sizeBank:j*sizeBank] = measures
        end
    end

    return result
end
            




