module Metadata

using HTTP

export start_metadata_fetcher, stop_metadata_fetcher, get_station_name

const active_fetcher = Ref{Union{Task, Nothing}}(nothing)
const current_callback = Ref{Any}(nothing)

"""
Démarre la récupération des métadonnées ICY
Appelle on_title(new_title) quand le titre change
"""
function start_metadata_fetcher(url::String, on_title::Function)
    stop_metadata_fetcher()
    current_callback[] = on_title
    
    active_fetcher[] = @async begin
        try
            HTTP.open("GET", url, headers=["Icy-MetaData" => "1"]) do http
                # Récupère le nom de la station
                station = HTTP.header(http, "icy-name", "Inconnu")
                
                # Récupère l'intervalle des métadonnées
                meta_int = tryparse(Int, HTTP.header(http, "icy-metaint", "0"))
                
                if meta_int === nothing || meta_int <= 0
                    @warn "Pas de métadonnées pour cette station"
                    return
                end
                
                buffer = Vector{UInt8}(undef, meta_int)
                last_title = ""
                
                while active_fetcher[] === current_task() && isopen(http)
                    # Lit les données audio (on les ignore)
                    readbytes!(http, buffer, meta_int)
                    
                    # Lit la taille des métadonnées
                    len_byte = read(http, 1)
                    if isempty(len_byte)
                        sleep(0.1)
                        continue
                    end
                    
                    meta_len = len_byte[1] * 16
                    
                    if meta_len > 0
                        # Lit et parse les métadonnées
                        meta_bytes = read(http, meta_len)
                        meta_str = String(meta_bytes)
                        
                        # Extrait StreamTitle='...'
                        m = match(r"StreamTitle='([^']*)'", meta_str)
                        if m !== nothing
                            title = m.captures[1]
                            if !isempty(title) && title != last_title
                                last_title = title
                                # Appelle le callback (thread-safe pour GTK)
                                try
                                    on_title(title)
                                catch e
                                    @error "Erreur callback titre" exception=e
                                end
                            end
                        end
                    end
                end
            end
        catch e
            if !(e isa InterruptException)
                @warn "Erreur metadata" exception=e
            end
        end
    end
end

"""
Arrête le fetcher de métadonnées
"""
function stop_metadata_fetcher()
    if active_fetcher[] !== nothing
        try
            schedule(active_fetcher[], InterruptException(), error=true)
        catch
        end
        active_fetcher[] = nothing
    end
end

"""
Extrait le nom de la station depuis les headers
"""
function get_station_name(url::String)
    try
        HTTP.open("GET", url, headers=["Icy-MetaData" => "1"]) do http
            return HTTP.header(http, "icy-name", "Radio Inconnue")
        end
    catch
        return "Radio"
    end
end

end # module