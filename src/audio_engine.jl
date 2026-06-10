module AudioEngine

include("dsp.jl")
using .DSPVisualizer
using Sockets

export start_playback, stop_playback, is_playing

const current_process = Ref{Union{Base.Process, Nothing}}(nothing)
const udp_sock = Ref{Union{UDPSocket, Nothing}}(nothing)
const audio_task = Ref{Union{Task, Nothing}}(nothing)

function start_playback(url::String)
    stop_playback()

    println("▶ Démarrage GStreamer + DSP (via UDP)...")
    
    pipeline_str = "tee name=t ! queue ! pulsesink t. ! queue ! audioconvert ! audioresample ! audio/x-raw,format=S16LE,channels=1,rate=8000 ! udpsink host=127.0.0.1 port=9090"
    
    cmd = `gst-launch-1.0 -q playbin uri=$url audio-sink=$pipeline_str`

    proc = run(pipeline(cmd, stdout=devnull, stderr=devnull), wait=false)
    current_process[] = proc
    
    sock = UDPSocket()
    bind(sock, ip"127.0.0.1", 9090)
    udp_sock[] = sock

    audio_task[] = @async begin
        accumulated = UInt8[] # ✅ Le bac de rétention
        
        while current_process[] !== nothing && isopen(sock)
            try
                data = recv(sock)
                append!(accumulated, data) # On colle les paquets
                
                # Dès qu'on a la bonne taille, on dessine !
                while length(accumulated) >= 2048
                    chunk = accumulated[1:2048]
                    DSPVisualizer.process_audio_chunk(chunk)
                    deleteat!(accumulated, 1:2048) # On retire ce qu'on a lu
                end
                
                # Sécurité anti-fuite de mémoire
                if length(accumulated) > 16000
                    empty!(accumulated)
                end
            catch
                break 
            end
        end
    end

    atexit() do
        stop_playback()
    end

    return true
end

function stop_playback()
    if udp_sock[] !== nothing && isopen(udp_sock[])
        close(udp_sock[])
        udp_sock[] = nothing
    end

    if current_process[] !== nothing
        proc = current_process[]
        if process_running(proc)
            try kill(proc, Base.SIGTERM); sleep(0.1) catch end
            try kill(proc, Base.SIGKILL) catch end
        end
        current_process[] = nothing
    end
end

function is_playing()
    current_process[] !== nothing && process_running(current_process[])
end

end # module