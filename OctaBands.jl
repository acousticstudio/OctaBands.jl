module OctaBands
    using DataFrames
    using PrettyTables
    using Unitful
    using Unitful: W, m, Pa, dB, Decibel, @logunit

    @logunit dBSIL "dBSIL" Decibel 1e-12W/m^2

    struct ThirdOct end

    struct Oct end

    abstract type AbstractBandType end 

    ISObandFreq = Dict(:oct => [8, 16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
                        :third => [12.5, 16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250,
    315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000,
    5000, 6300, 8000, 10000, 12500, 16000, 20000])

    roundIfExact(x) = abs(x%1.0) <= 0.05 ? string(Int(round(x))) : string(round(x,digits=1))

    freqToBandName(f) = f < 999.0 ? roundIfExact(f) : roundIfExact(f/1000.0) * "k"

    struct BandFrame{T} <: AbstractBandType 
        data::AbstractDataFrame 
        bandFreqs::Vector{Real}
    end

    function Base.show(io::IO, bf::AbstractBandType) 
        table = pretty_table(io, (Array(bf.data )),
                            header=names(ustrip.(bf.data)))
        print 
    end

    function BandFrame(df::DataFrame)
        bandNames = "Band" .* (1:ncols(df)) 
        BandFrame{:arb}(df, bandNames)
    end

    function ISOBandFrame(data::AbstractArray, startFreq, ISOType)
        nbands = size(data)[end]
        if ISOType == :oct
            div = 1
        elseif ISOType == :third
            div = 3
        end
        bands = (startFreq .* 2 .^ ((0:nbands-1)./div))
        m = matchVecs(bands, ISObandFreq[ISOType])
        ISObands = ISObandFreq[ISOType][m]
        bandNames = freqToBandName.(ISObands)
        df = DataFrame([b=>vals for (b, vals) in zip(bandNames, eachcol(data))])
        BandFrame{ISOType}(df, bands)
    end

    function OctaveBandFrame(data::AbstractArray, startFreq)
        ISOBandFrame(data, startFreq, :oct)
    end

    function ThirdOctaveBandFrame(data::AbstractArray, startFreq)
        ISOBandFrame(data, startFreq, :third)
    end

    function add(bf1::T, bf2::T) where {T <: AbstractBandType}
        BandFrame{T}(bf1.data .+ bf2.data)
    end

    function concatenate(bf1::T, bf2::T) where {T <: AbstractBandType}
        bdict = Dict()
        for bf in [bf1, bf2]
            for (f, l) in zip(bf.bandFreqs, names(bf.data))
                bdict[l] = f
            end
        end
        data = vcat(bf1.data, bf2.data, cols = :union)
        bands = [bdict[l] for l in names(data)]
        BandFrame{T}(data, bands)
    end

    function matchVecs(x, y; reltol=0.1)
        mask = ones(Bool, size(y))
        corr = zeros(Int, size(x))
        for (xidx, xx) in enumerate(x)
            println(xidx)
            yremaining = y[mask]
            reldif = abs.((yremaining .- xx)/xx)
            nearestidx = argmin(reldif)
            if reldif[nearestidx] <= reltol
                origidx = findall(mask)[nearestidx] 
                corr[xidx] = origidx
                mask[origidx] = false
            end
        end
        corr
    end

    function alignToISO(bf::AbstractBandType; reltol=.01)
        freqs = bf
        for f in freqs
        end
    end

end