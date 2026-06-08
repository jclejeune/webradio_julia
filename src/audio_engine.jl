module AudioEngine

export start_playback, stop_playback, is_playing

const current_process = Ref{Union{Base.Process, Nothing}}(nothing)

"""
Démarre la lecture avec GStreamer (playbin)
Gère automatiquement : HTTP, décodage, sortie PulseAudio
"""
function start_playback(url::String)
    stop_playback()  # Sécurité
    
    println("▶ Démarrage GStreamer...")
    println("   URL: $url")
    
    # Playbin = lecteur universel (gère MP3, AAC, OGG, etc.)
    # pulsesink = sortie vers PulseAudio/PipeWire
    cmd = `gst-launch-1.0 playbin uri=$url audio-sink=pulsesink`
    
    # Redirige stderr vers devnull pour éviter le spam GStreamer
    current_process[] = run(pipeline(cmd, stderr=devnull), wait=false)
    
    println("🔊 Lecture démarrée (PID: $(current_process[].pid))")
    return true
end

"""
Arrête la lecture
"""
function stop_playback()
    if is_playing()
        println("■ Arrêt de la lecture")
        try
            kill(current_process[])
            wait(current_process[])
        catch e
            # Process déjà mort, c'est OK
        end
        current_process[] = nothing
    end
end

"""
Vérifie si une lecture est en cours
"""
function is_playing()
    current_process[] !== nothing && process_running(current_process[])
end

end # module