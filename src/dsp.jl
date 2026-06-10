module DSPVisualizer

using FFTW

export process_audio_chunk, get_bands

const NUM_BANDS = 32
const CHUNK_SIZE = 1024
const bands = zeros(Float64, NUM_BANDS)
const window = 0.5 .* (1 .- cos.(2 .* π .* (0:CHUNK_SIZE-1) ./ (CHUNK_SIZE - 1)))

function process_audio_chunk(pcm_bytes::Vector{UInt8})
    # Sécurité absolue
    if length(pcm_bytes) != CHUNK_SIZE * 2
        return
    end
    
    signal = zeros(Float64, CHUNK_SIZE)
    for i in 1:CHUNK_SIZE
        b1 = pcm_bytes[2i - 1]
        b2 = pcm_bytes[2i]
        val = (Int16(b2) << 8) | Int16(b1)
        signal[i] = Float64(val) * window[i]
    end
    
    F = abs.(rfft(signal))
    
    step = floor(Int, (length(F) - 10) / NUM_BANDS)
    for i in 1:NUM_BANDS
        start_idx = 5 + (i-1)*step
        end_idx = start_idx + step - 1
        
        val = sum(F[start_idx:end_idx]) / step
        bands[i] = 0.7 * bands[i] + 0.3 * (val / 10000.0)
    end
end

function get_bands()
    return bands
end

end # module