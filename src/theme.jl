module Theme

using Gtk

const COLORS = Dict(
    :background   => "#3C3F41",
    :foreground   => "#BBBBBB",
    :button_bg    => "#4D4D4D",
    :button_fg    => "#DCDCDC",
    :selection_bg => "#FA8B01",
    :selection_fg => "#000000",
    :status_bg    => "#282828",
    :status_fg    => "#FA8B01",
    :border       => "#646464",
    :slider_bg    => "#4D4D4D",
    :slider_fg    => "#FA8B01",
)

const CSS_THEME = """
/* Reset global agressif */
* {
    background-color: #3C3F41;
    color: #BBBBBB;
    border-color: #646464;
}

window {
    background-color: #3C3F41;
}

/* ===== BARRE DE TITRE FORCÉE ===== */
headerbar, .titlebar {
    background-color: #282828 !important;
    background-image: none !important;
    border-bottom: 1px solid #646464 !important;
    box-shadow: none !important;
    min-height: 0 !important;
    padding: 4px !important;
}

headerbar .title, headerbar title {
    color: #FA8B01 !important;
    font-family: monospace !important;
    font-weight: bold !important;
    font-size: 14px !important;
    text-shadow: none !important;
}

headerbar button.titlebutton {
    background-color: #4D4D4D !important;
    background-image: none !important;
    min-width: 16px !important;
    min-height: 16px !important;
    padding: 4px !important;
    border-radius: 50% !important;
    border: 1px solid #646464 !important;
    color: #BBBBBB !important;
}

headerbar button.titlebutton:hover {
    background-color: #5A5A5A !important;
    border-color: #FA8B01 !important;
}

headerbar button.titlebutton.close {
    background-color: #5A3030 !important;
}

headerbar button.titlebutton.close:hover {
    background-color: #FA8B01 !important;
    color: #000000 !important;
}

headerbar button.titlebutton.maximize,
headerbar button.titlebutton.minimize {
    background-color: #4D4D4D !important;
}


/* ===== FOCUS DE LA FENÊTRE (empêche le blanc quand active) ===== */
window:focus headerbar,
window:focus .titlebar,
headerbar:focus,
.titlebar:focus,
headerbar:backdrop,
.titlebar:backdrop {
    background-color: #282828 !important;
    background-image: none !important;
    border-bottom: 1px solid #646464 !important;
    box-shadow: none !important;
}

window:focus headerbar .title,
window:focus headerbar title,
headerbar:focus .title {
    color: #FA8B01 !important;
}

window:focus headerbar button.titlebutton,
headerbar:focus button.titlebutton {
    background-color: #4D4D4D !important;
    color: #BBBBBB !important;
    border-color: #646464 !important;
}

window:focus headerbar button.titlebutton:hover {
    background-color: #5A5A5A !important;
    border-color: #FA8B01 !important;
}

/* Empêche le fond blanc de la fenêtre au focus */
window:focus {
    background-color: #3C3F41;
}

/* Tous les containers */
box, grid, paned, notebook {
    background-color: #3C3F41;
}

/* Frames et bordures */
frame {
    background-color: #3C3F41;
    border: 1px solid #646464;
}

frame > label {
    color: #FA8B01;
    font-weight: bold;
    background-color: #3C3F41;
}

/* Labels */
label {
    color: #BBBBBB;
    font-family: monospace;
    background-color: transparent;
}

/* Le display principal */
label.radio-display {
    color: #FA8B01;
    background-color: #282828;
    font-size: 32px;
    font-weight: bold;
    padding: 30px;
}

/* Status labels */
label.status {
    color: #FA8B01;
    background-color: #282828;
    border: 2px solid #646464;
    padding: 10px;
    font-family: monospace;
    font-weight: bold;
    font-size: 16px;
}

/* Boutons */
button {
    background-color: #4D4D4D;
    background-image: none;
    color: #DCDCDC;
    border: 1px solid #646464;
    border-radius: 3px;
    padding: 5px 15px;
    font-family: monospace;
    font-weight: bold;
    box-shadow: none;
    text-shadow: none;
}

button:hover {
    background-color: #5A5A5A;
    border-color: #FA8B01;
    color: #FFFFFF;
}

button:active, button:checked {
    background-color: #FA8B01;
    color: #000000;
}

button.transport {
    font-size: 20px;
    padding: 8px 20px;
    min-width: 50px;
}

/* TreeView */
treeview {
    background-color: #282828;
    color: #BBBBBB;
    font-family: monospace;
}

treeview:selected {
    background-color: #FA8B01;
    color: #000000;
}

treeview:selected:focus {
    background-color: #FA8B01;
    color: #000000;
}

treeview row:selected {
    background-color: #FA8B01;
    color: #000000;
}

treeview row {
    background-color: #282828;
}

treeview header button {
    background-color: #3C3F41;
    color: #BBBBBB;
    border: 1px solid #646464;
}

/* Scrolled window */
scrolledwindow {
    background-color: #282828;
    border: 1px solid #646464;
}

scrolledwindow viewport {
    background-color: #282828;
}

/* Progress bars */
progressbar trough {
    background-color: #282828;
    border: 1px solid #646464;
    min-height: 12px;
    border-radius: 2px;
}

progressbar progress {
    background-color: #FA8B01;
    background-image: none;
    border-radius: 2px;
    min-height: 12px;
}

/* Sliders */
scale {
    background-color: #3C3F41;
}

scale trough {
    background-color: #4D4D4D;
    border-radius: 3px;
    min-height: 6px;
}

scale highlight {
    background-color: #FA8B01;
    background-image: none;
    border-radius: 3px;
}

scale slider {
    background-color: #FA8B01;
    background-image: none;
    border-radius: 50%;
    min-width: 16px;
    min-height: 16px;
}

/* Entries */
entry {
    background-color: #282828;
    color: #BBBBBB;
    border: 1px solid #646464;
    border-radius: 3px;
    padding: 5px;
}

/* Menus */
menu, popover, popover.background {
    background-color: #282828;
    color: #BBBBBB;
}

menuitem:hover {
    background-color: #FA8B01;
    color: #000000;
}

/* Dialog */
dialog, messagedialog {
    background-color: #3C3F41;
}

dialog headerbar {
    background-color: #282828 !important;
    background-image: none !important;
}

dialog content area {
    background-color: #3C3F41;
}

/* Séparateurs */
separator {
    background-color: #646464;
}

/* Scrollbar */
scrollbar {
    background-color: #3C3F41;
}

scrollbar trough {
    background-color: #282828;
}

scrollbar slider {
    background-color: #646464;
    border-radius: 3px;
    min-width: 8px;
}

scrollbar slider:hover {
    background-color: #FA8B01;
}

/* Tooltips */
tooltip {
    background-color: #282828;
    color: #FA8B01;
}

tooltip label {
    color: #FA8B01;
}

/* Barre de titre custom */
#custom-titlebar {
    background-color: #282828;
    border-bottom: 1px solid #646464;
}

label.window-title {
    color: #FA8B01;
    font-family: monospace;
    font-weight: bold;
    font-size: 14px;
}

"""

function apply_theme!()
    provider = GtkCssProvider()
    
    ccall((:gtk_css_provider_load_from_data, Gtk.libgtk),
          Bool, 
          (Ptr{GObject}, Ptr{UInt8}, Cint, Ptr{Nothing}),
          provider, CSS_THEME, -1, C_NULL)
    
    display = ccall((:gdk_display_get_default, Gtk.libgdk), 
                    Ptr{Nothing}, ())
    
    screen = ccall((:gdk_display_get_default_screen, Gtk.libgdk), 
                   Ptr{Nothing}, 
                   (Ptr{Nothing},), 
                   display)
    
    ccall((:gtk_style_context_add_provider_for_screen, Gtk.libgtk),
          Nothing,
          (Ptr{Nothing}, Ptr{GObject}, Cuint),
          screen, provider, 800)
    
    println("✓ Thème sombre + orange appliqué")
end

function add_css_class!(widget, class_name::String)
    context = ccall((:gtk_widget_get_style_context, Gtk.libgtk),
                    Ptr{Nothing},
                    (Ptr{GObject},),
                    widget)
    
    ccall((:gtk_style_context_add_class, Gtk.libgtk),
          Nothing,
          (Ptr{Nothing}, Cstring),
          context, class_name)
end

end # module