module webradio_julia

include("theme.jl")
include("ui.jl")

using .UI

function main()
    println("Webradio Julia démarre")
    UI.run_ui()
end

end
