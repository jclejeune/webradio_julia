module AudioEngine

export start_playback, stop_playback, is_playing

const current_process = Ref{Union{Base.Process, Nothing}}(nothing)

function start_playback(url::String)
    stop_playback()

    println("▶ Démarrage GStreamer...")
    println("   URL: $url")

    cmd = `gst-launch-1.0 playbin uri=$url audio-sink=pulsesink`

    proc = run(pipeline(cmd, stderr=devnull), wait=false)

    current_process[] = proc

    atexit() do
        stop_playback()
    end

    # ✅ On a retiré le proc.pid qui faisait crasher !
    println("🔊 Lecture démarrée") 
    return true
end

function stop_playback()
    if current_process[] !== nothing
        proc = current_process[]

        if process_running(proc)
            # ✅ On a retiré le proc.pid ici aussi
            println("■ Arrêt GStreamer") 

            try
                kill(proc, Base.SIGTERM)
                sleep(0.2)

                if process_running(proc)
                    kill(proc, Base.SIGKILL)
                end

                wait(proc)
            catch
                # déjà mort → ok
            end
        end

        current_process[] = nothing
    end
end

function is_playing()
    current_process[] !== nothing && process_running(current_process[])
end

end # module