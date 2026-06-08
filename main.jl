ENV["GTK_THEME"] = "Adwaita:dark" 

include("src/webradio_julia.jl")
using .webradio_julia

webradio_julia.main()
