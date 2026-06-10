module Metadata

using Sockets
using HTTP

export start_metadata_fetcher, stop_metadata_fetcher

const active_fetcher = Ref{Union{Task, Nothing}}(nothing)
const active_io = Ref{Any}(nothing)

# ============================================================
# HELPERS
# ============================================================

function parse_icy_headers(raw::String)
    headers = Dict{String, String}()
    for line in split(raw, "\r\n")
        isempty(line) && continue
        m = match(r"^([^:]+):\s*(.*)$", line)
        if m !== nothing
            headers[lowercase(strip(m.captures[1]))] = strip(m.captures[2])
        end
    end
    return headers
end

function parse_url(url::String)
    m = match(r"(https?)://([^/:]+)(?::(\d+))?(/.*)?", url)
    if m === nothing
        error("URL invalide: $url")
    end
    scheme = m.captures[1]
    host = m.captures[2]
    port = m.captures[3] !== nothing ? parse(Int, m.captures[3]) : (scheme == "https" ? 443 : 80)
    path = m.captures[4] !== nothing ? m.captures[4] : "/"
    return scheme, host, port, path
end

function get_header(headers, name::String, default::String="")
    name_lower = lowercase(name)
    for (k, v) in headers
        if lowercase(k) == name_lower
            return v
        end
    end
    return default
end

# ============================================================
# HTTP BRUT (TCP)
# ============================================================

function fetch_metadata_http(url::String)
    scheme, host, port, path = parse_url(url)
    sock = connect(host, port)
    active_io[] = sock
    
    try
        request = "GET " * path * " HTTP/1.0\r\nHost: " * host * "\r\nIcy-MetaData: 1\r\nUser-Agent: Mozilla/5.0 (Julia-WebRadio)\r\nConnection: close\r\n\r\n"
        write(sock, request)
        flush(sock)
        
        header_buf = IOBuffer()
        prev = UInt8[0, 0, 0, 0]
        
        while isopen(sock)
            b = read(sock, UInt8)
            write(header_buf, b)
            prev[1], prev[2], prev[3], prev[4] = prev[2], prev[3], prev[4], b
            if prev == UInt8['\r', '\n', '\r', '\n']
                break
            end
        end
        
        header_str = String(take!(header_buf))
        headers = parse_icy_headers(header_str)
        
        return headers, sock
        
    catch e
        close(sock)
        rethrow(e)
    end
end

# ============================================================
# HTTPS via HTTP.jl
# ============================================================

function fetch_metadata_https(url::String)
    try
        response = HTTP.request("HEAD", url, ["Icy-MetaData" => "1"]; status_exception=false, redirect=true)
        headers = response.headers
        
        meta_int_str = get_header(headers, "icy-metaint", "0")
        meta_int = tryparse(Int, meta_int_str)
        
        if meta_int === nothing || meta_int <= 0
            return headers, nothing
        end
        
        stream = HTTP.open("GET", url, ["Icy-MetaData" => "1"])
        active_io[] = stream
        return headers, stream
        
    catch e
        return nothing, nothing
    end
end

# ============================================================
# FONCTION PRINCIPALE
# ============================================================

function start_metadata_fetcher(url::String, on_title::Function)
    stop_metadata_fetcher()
    
    active_fetcher[] = @async begin
        try
            scheme, host, port, path = parse_url(url)
            is_https = scheme == "https"
            
            # Connexion au serveur...
            if is_https
                headers, io = fetch_metadata_https(url)
            else
                headers, io = fetch_metadata_http(url)
            end
            
            if headers === nothing
                return
            end
            
            on_title("▶ Lecture en cours...")
            
            meta_int_str = get_header(headers, "icy-metaint", "0")
            meta_int = tryparse(Int, meta_int_str)
            
            if meta_int === nothing || meta_int <= 0 || io === nothing
                return
            end
            
            buffer = Vector{UInt8}(undef, meta_int)
            last_title = "▶ Lecture en cours..."
            
            while active_fetcher[] === current_task() && isopen(io)
                total = 0
                while total < meta_int
                    r = is_https ? readbytes!(io, view(buffer, total+1:meta_int), meta_int - total) : readbytes!(io, view(buffer, total+1:meta_int), meta_int - total)
                    if r == 0
                        break
                    end
                    total += r
                end
                
                if total < meta_int
                    break
                end
                
                len_byte = is_https ? read(io, UInt8) : read(io, UInt8)
                meta_len = Int(len_byte) * 16
                
                if meta_len > 0
                    meta_bytes = is_https ? read(io, meta_len) : read(io, meta_len)
                    meta_str = String(copy(meta_bytes))
                    
                    m = match(r"StreamTitle='([^']*)'", meta_str)
                    if m !== nothing
                        raw_title = strip(m.captures[1])
                        
                        new_title = isempty(raw_title) ? "▶ Lecture en cours..." : "🎵 " * raw_title
                        
                        if new_title != last_title
                            last_title = new_title
                            on_title(new_title)
                        end
                    end
                end
            end
            
        catch e
            if active_fetcher[] === current_task() && !(e isa EOFError || e isa Base.IOError || e isa InterruptException)
                @warn "Stream metadata interrompu" exception=e
            end
        finally
            io = active_io[]
            if io !== nothing && isopen(io)
                try close(io) catch end
            end
            active_io[] = nothing
        end
    end
end

function stop_metadata_fetcher()
    active_fetcher[] = nothing
    io = active_io[]
    if io !== nothing && isopen(io)
        try close(io) catch end
    end
    active_io[] = nothing
end

end # module