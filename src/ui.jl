module UI

using Gtk

include("theme.jl")
using .Theme
include("persistence.jl")
using .Persistence
include("audio_engine.jl")
using .AudioEngine
include("metadata.jl")
using .Metadata

export run_ui

function create_window()
    Theme.apply_theme!()
    
    win = GtkWindow("WebRadio Player", 600, 650)
    
    vbox = GtkBox(:v)
    set_gtk_property!(vbox, :spacing, 5)
    push!(win, vbox)
    
    # === DISPLAY ===
    display_frame = GtkFrame()
    set_gtk_property!(display_frame, :height_request, 120)
    push!(vbox, display_frame)
    
    display_vbox = GtkBox(:v)
    set_gtk_property!(display_vbox, :spacing, 5)
    push!(display_frame, display_vbox)
    
    station_label = GtkLabel("WebRadio Julia")
    Theme.add_css_class!(station_label, "radio-display")
    push!(display_vbox, station_label)
    
    title_label = GtkLabel("Sélectionnez une radio...")
    Theme.add_css_class!(title_label, "title-display")
    push!(display_vbox, title_label)
    
    
    # === BOUTONS CRUD ===
    btn_box = GtkBox(:h)
    set_gtk_property!(btn_box, :spacing, 5)
    set_gtk_property!(btn_box, :margin, 5)
    push!(vbox, btn_box)
    
    btn_add = GtkButton("+ Ajouter")
    btn_del = GtkButton("- Supprimer")
    push!(btn_box, btn_add)
    push!(btn_box, btn_del)
    
    # === LISTE ===
    scrolled = GtkScrolledWindow()
    set_gtk_property!(scrolled, :vexpand, true)
    push!(vbox, scrolled)
    
    list_store = GtkListStore(String, String, Bool)
    tree_view = GtkTreeView(GtkTreeModel(list_store))
    set_gtk_property!(tree_view, :headers_visible, false)
    
    renderer = GtkCellRendererText()
    col = GtkTreeViewColumn("Radio", renderer, Dict([("text", 0)]))
    push!(tree_view, col)
    
    push!(scrolled, tree_view)
    
    # Chargement initial
    for (name, url, editable) in Persistence.load_radios()
        push!(list_store, (name, url, editable))
    end
    
    # === CONTRÔLES LECTURE ===
    ctrl_box = GtkBox(:h)
    set_gtk_property!(ctrl_box, :spacing, 10)
    set_gtk_property!(ctrl_box, :margin, 10)
    set_gtk_property!(ctrl_box, :halign, Gtk.GConstants.GtkAlign.CENTER)
    push!(vbox, ctrl_box)
    
    btn_play = GtkButton("▶ Play")
    btn_stop = GtkButton("■ Stop")
    
    for btn in [btn_play, btn_stop]
        Theme.add_css_class!(btn, "transport")
        push!(ctrl_box, btn)
    end
    
    # === LOGIQUE ===
    selection = Gtk.GAccessor.selection(tree_view)
    
    function play_current()
        iter = Gtk.selected(selection)
        if iter === nothing
            println("⚠️ Sélectionnez une radio d'abord")
            return
        end
        
        name = list_store[iter, 1]
        url = list_store[iter, 2]
        
        set_gtk_property!(station_label, :label, name)
        set_gtk_property!(title_label, :label, "Connexion...")
        
        AudioEngine.start_playback(url)
        
        Metadata.start_metadata_fetcher(url, function(title)
            Gtk.g_idle_add() do
                set_gtk_property!(title_label, :label, title)
                return false
            end
        end)
    end
    
    # Callbacks
    signal_connect(btn_play, "clicked") do _
        play_current()
    end
    
    signal_connect(btn_stop, "clicked") do _
        AudioEngine.stop_playback()
        Metadata.stop_metadata_fetcher()
        set_gtk_property!(title_label, :label, "Arrêté")
        println("■ Stop")
    end
       
    signal_connect(tree_view, "row-activated") do widget, path, col
        iter = Gtk.selected(selection)
        if iter !== nothing
            play_current()
        end
    end
    
    signal_connect(btn_add, "clicked") do _
        dialog = GtkDialog("Ajouter une radio", win, Gtk.GConstants.GtkDialogFlags.MODAL, (("Annuler", 0), ("Ajouter", 1)))
        content = Gtk.GAccessor.content_area(dialog)
        v = GtkBox(:v)
        set_gtk_property!(v, :spacing, 10); set_gtk_property!(v, :margin, 20); push!(content, v)
        push!(v, GtkLabel("Nom de la radio :")); name_entry = GtkEntry(); push!(v, name_entry)
        push!(v, GtkLabel("URL du flux :")); url_entry = GtkEntry(); set_gtk_property!(url_entry, :text, "http://"); push!(v, url_entry)
        showall(dialog)
        if run(dialog) == 1
            name = get_gtk_property(name_entry, :text, String); url = get_gtk_property(url_entry, :text, String)
            if !isempty(name) && !isempty(url) && url != "http://"
                if Persistence.add_radio(name, url)
                    push!(list_store, (name, url, true)); println("✅ Ajouté: $name")
                end
            end
        end
        destroy(dialog)
    end
    
    signal_connect(btn_del, "clicked") do _
        iter = Gtk.selected(selection)
        if iter === nothing return end
        name = list_store[iter, 1]; editable = list_store[iter, 3]
        if !editable println("Impossible de supprimer une radio par défaut"); return end
        dlg = GtkDialog("Confirmer", win, Gtk.GConstants.GtkDialogFlags.MODAL, (("Annuler", 0), ("Supprimer", 1)))
        content = Gtk.GAccessor.content_area(dlg)
        v = GtkBox(:v); set_gtk_property!(v, :margin, 20); push!(content, v); push!(v, GtkLabel("Supprimer '$name' ?"))
        showall(dlg)
        if run(dlg) == 1
            if Persistence.remove_radio(name)
                Gtk.delete!(list_store, iter); println("🗑️ Supprimé: $name")
            end
        end
        destroy(dlg)
    end
    
    return win
end

function run_ui()
    win = create_window()
    showall(win)
    
    if !isinteractive()
        c = Condition()
        
        signal_connect(win, "delete-event") do widget, event
            println("\n👋 Nettoyage et fermeture...")
            try AudioEngine.stop_playback() catch end
            try Metadata.stop_metadata_fetcher() catch end
            return false
        end
        
        signal_connect(win, :destroy) do _
            notify(c)
        end
        
        wait(c)
    end
end

end # module