module UI

using Gtk
include("theme.jl")
using .Theme
include("persistence.jl")
using .Persistence

export run_ui

function create_window()
    Theme.apply_theme!()
    
    win = GtkWindow("WebRadio Player", 600, 600)
    
    vbox = GtkBox(:v)
    set_gtk_property!(vbox, :spacing, 5)
    push!(win, vbox)
    
    # === DISPLAY ===
    display_frame = GtkFrame()
    set_gtk_property!(display_frame, :height_request, 100)
    push!(vbox, display_frame)
    
    radio_label = GtkLabel("WebRadio Julia")
    Theme.add_css_class!(radio_label, "radio-display")
    push!(display_frame, radio_label)
    
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
    
    # 3 colonnes: Nom, URL, Editable?
    list_store = GtkListStore(String, String, Bool)
    tree_view = GtkTreeView(GtkTreeModel(list_store))
    set_gtk_property!(tree_view, :headers_visible, false)
    
    renderer = GtkCellRendererText()
    col = GtkTreeViewColumn("Radio", renderer, Dict([("text", 0)]))
    push!(tree_view, col)
    
    push!(scrolled, tree_view)
    
    # Charger les données
    for (name, url, editable) in Persistence.load_radios()
        push!(list_store, (name, url, editable))
    end
    
    # === CONTRÔLES LECTURE ===
    ctrl_box = GtkBox(:h)
    set_gtk_property!(ctrl_box, :spacing, 5)
    set_gtk_property!(ctrl_box, :margin, 10)
    set_gtk_property!(ctrl_box, :halign, Gtk.GConstants.GtkAlign.CENTER)
    push!(vbox, ctrl_box)
    
    btn_play = GtkButton("▶ Play")
    btn_stop = GtkButton("■ Stop")
    push!(ctrl_box, btn_play)
    push!(ctrl_box, btn_stop)
    
    # === CALLBACKS ===
    selection = Gtk.GAccessor.selection(tree_view)
    
    # PLAY
    signal_connect(btn_play, "clicked") do _
        iter = Gtk.selected(selection)
        if iter !== nothing
            name = list_store[iter, 1]
            set_gtk_property!(radio_label, :label, "▶ $name")
            println("Lecture: $(list_store[iter, 2])")
        end
    end
    
    # STOP
    signal_connect(btn_stop, "clicked") do _
        set_gtk_property!(radio_label, :label, "WebRadio Julia")
    end
    
    # ADD
    signal_connect(btn_add, "clicked") do _
        dialog = GtkDialog("Ajouter", win, Gtk.GConstants.GtkDialogFlags.MODAL,
                          (("Annuler", 0), ("Ajouter", 1)))
        
        content = Gtk.GAccessor.content_area(dialog)
        v = GtkBox(:v)
        set_gtk_property!(v, :margin, 10)
        push!(content, v)
        
        push!(v, GtkLabel("Nom:"))
        name_entry = GtkEntry()
        push!(v, name_entry)
        
        push!(v, GtkLabel("URL:"))
        url_entry = GtkEntry()
        push!(v, url_entry)
        
        showall(dialog)
        if run(dialog) == 1
            name = get_gtk_property(name_entry, :text, String)
            url = get_gtk_property(url_entry, :text, String)
            if !isempty(name) && !isempty(url)
                if Persistence.add_radio(name, url)
                    push!(list_store, (name, url, true))
                else
                    println("URL déjà existante")
                end
            end
        end
        destroy(dialog)
    end
    
        # DELETE
    signal_connect(btn_del, "clicked") do _
        iter = Gtk.selected(selection)
        if iter !== nothing
            name = list_store[iter, 1]
            editable = list_store[iter, 3]
            
            if !editable
                println("Impossible de supprimer une radio par défaut")
                return
            end
            
            # Dialogue de confirmation simplifié
            dlg = GtkDialog("Confirmer", win, Gtk.GConstants.GtkDialogFlags.MODAL,
                           (("Annuler", 0), ("Supprimer", 1)))
            
            content = Gtk.GAccessor.content_area(dlg)
            vbox_dlg = GtkBox(:v)
            set_gtk_property!(vbox_dlg, :margin, 20)
            push!(content, vbox_dlg)
            
            lbl = GtkLabel("Supprimer '$name' ?")
            push!(vbox_dlg, lbl)
            
            showall(dlg)
            response = run(dlg)
            destroy(dlg)
            
            if response == 1  # 1 = Supprimer
                if Persistence.remove_radio(name)
                    Gtk.delete!(list_store, iter)
                    println("🗑️ Supprimé: $name")
                end
            end
        end
    end
    
    return win
end

function run_ui()
    win = create_window()
    showall(win)
    
    if !isinteractive()
        c = Condition()
        signal_connect(win, :destroy) do _
            notify(c)
        end
        wait(c)
    end
end

end # module