module Persistence

using TOML

export load_radios, add_radio, remove_radio

const DEFAULT_PATH = joinpath(@__DIR__, "..", "resources", "radios.toml")
const USER_PATH = joinpath(homedir(), ".config", "webradio_julia", "radios.toml")

function load_radios()
    radios = Vector{Tuple{String, String, Bool}}()
    if isfile(DEFAULT_PATH)
        try
            data = TOML.parsefile(DEFAULT_PATH)
            if haskey(data, "radios")
                for r in data["radios"]
                    push!(radios, (r["name"], r["url"], false))
                end
            end
        catch e
            println("⚠ Erreur chargement défauts: $e")
        end
    end
    
    if isfile(USER_PATH)
        try
            data = TOML.parsefile(USER_PATH)
            if haskey(data, "radios")
                for r in data["radios"]
                    push!(radios, (r["name"], r["url"], true))
                end
            end
        catch e
            println("⚠ Erreur chargement user: $e")
        end
    end
    
    return radios
end

function add_radio(name::String, url::String)
    dir = dirname(USER_PATH)
    isdir(dir) || mkpath(dir)
    
    existing = Dict{String, Any}()
    if isfile(USER_PATH)
        try
            existing = TOML.parsefile(USER_PATH)
        catch
        end
    end
    
    radios = get(existing, "radios", Dict{String, Any}[])
    
    for r in radios
        if r["url"] == url
            return false
        end
    end
    
    push!(radios, Dict("name" => name, "url" => url))
    existing["radios"] = radios
    
    open(USER_PATH, "w") do io
        TOML.print(io, existing)
    end
    
    return true
end

function remove_radio(name::String)
    isfile(USER_PATH) || return false
    
    try
        data = TOML.parsefile(USER_PATH)
        radios = get(data, "radios", Dict{String, Any}[])
        new_radios = filter(r -> r["name"] != name, radios)
        
        if length(new_radios) < length(radios)
            data["radios"] = new_radios
            open(USER_PATH, "w") do io
                TOML.print(io, data)
            end
            return true
        end
    catch e
        println("Erreur suppression: $e")
    end
    
    return false
end

end # module