module UI

using Gtk
include("theme.jl")
using .Theme

export run_ui

# Liste de radios par défaut (comme ta version Clojure)
const DEFAULT_RADIOS = [
    ("Shonan Beach FM",        "http://shonanbeachfm.out.airtime.pro:8000/shonanbeachfm_a"),
    ("CHOI 981 Radio X",       "https://lb0-stream.radiox981.ca/choi.mp3"),
    ("Soma FM",                "https://ice1.somafm.com/gsclassic-128-mp3"),
    ("Radio Perú", "https://stream.zeno.fm/2kwbahnnq2zuv"),
    ("Radio Moris",            "https://azc.radiomoris.com:8010/radio.mp3"),
    ("Radio Pilmaiqu",         "https://streaming.chiloestreaming.com:10977/"),
    ("FM Kahoku 78.7",         "http://radio.kahoku.net:8000/"),
    ("Dance Wave Retro",       "http://stream3.dancewave.online:8080/retrodance.mp3"),
    ("Soma FM Metal Detector", "http://ice6.somafm.com/metal-128-mp3"),
    ("Radio Vexin Val de Seine","https://rvvs.ice.infomaniak.ch/rvvs-64.aac"),
    ("Capital London",         "https://media-ice.musicradio.com/CapitalMP3"),
    ("J-Rock PowerPlay",       "http://kathy.torontocast.com:3340/"),
]


function create_window()
    Theme.apply_theme!()
    
    win = GtkWindow("WebRadio Player", 600, 600)
    
    # Layout vertical principal
    vbox = GtkBox(:v)
    set_gtk_property!(vbox, :spacing, 0)
    push!(win, vbox)
    
    # ============================
    # HAUT : Display du nom de la radio
    # ============================
    display_frame = GtkFrame()
    set_gtk_property!(display_frame, :height_request, 120)
    push!(vbox, display_frame)
    
    radio_name_label = GtkLabel("WebRadio Julia")
    Theme.add_css_class!(radio_name_label, "radio-display")
    push!(display_frame, radio_name_label)
    
    # ============================
    # Bouton Ajouter Radio
    # ============================
    btn_box = GtkBox(:h)
    set_gtk_property!(btn_box, :margin, 5)
    push!(vbox, btn_box)
    
    btn_add = GtkButton("Ajouter Radio")
    push!(btn_box, btn_add)
    
    # ============================
    # MILIEU : Liste des radios
    # ============================
    scrolled = GtkScrolledWindow()
    set_gtk_property!(scrolled, :vexpand, true)
    set_gtk_property!(scrolled, :hexpand, true)
    push!(vbox, scrolled)
    
    list_store = GtkListStore(String, String)  # Nom, URL
    
    tree_view = GtkTreeView(GtkTreeModel(list_store))
    set_gtk_property!(tree_view, :headers_visible, false)  # Pas d'en-têtes
    
    renderer = GtkCellRendererText()
    col = GtkTreeViewColumn("Radio", renderer, Dict([("text", 0)]))
    push!(tree_view, col)
    
    push!(scrolled, tree_view)
    
    # Remplir avec les radios par défaut
    for (name, url) in DEFAULT_RADIOS
        push!(list_store, (name, url))
    end
    
    # ============================
    # BAS : Contrôles télécommande
    # ============================
    ctrl_frame = GtkFrame()
    push!(vbox, ctrl_frame)
    
    ctrl_box = GtkBox(:h)
    set_gtk_property!(ctrl_box, :margin, 8)
    set_gtk_property!(ctrl_box, :spacing, 5)
    set_gtk_property!(ctrl_box, :halign, Gtk.GConstants.GtkAlign.CENTER)
    push!(ctrl_frame, ctrl_box)
    
    btn_prev = GtkButton("⏮")
    btn_play = GtkButton("▶")
    btn_next = GtkButton("⏭")
    btn_stop = GtkButton("■")
    
    for btn in [btn_prev, btn_play, btn_next, btn_stop]
        Theme.add_css_class!(btn, "transport")
        push!(ctrl_box, btn)
    end
    
    # ============================
    # CALLBACKS
    # ============================
    current_index = Ref(0)
    
    signal_connect(btn_play, "clicked") do _
        iter = Gtk.selected(Gtk.GAccessor.selection(tree_view))
        if iter !== nothing
            name = list_store[iter, 1]
            url = list_store[iter, 2]
            set_gtk_property!(radio_name_label, :label, name)
            println("▶ Lecture de : $name")
            println("   URL : $url")
        else
            println("Aucune radio sélectionnée")
        end
    end
    
    signal_connect(btn_stop, "clicked") do _
        set_gtk_property!(radio_name_label, :label, "WebRadio Julia")
        println("■ Stop")
    end
    
    signal_connect(btn_prev, "clicked") do _
        n = length(list_store)
        if n > 0
            current_index[] = max(1, current_index[] - 1)
            iter = Gtk.iter_from_index(list_store, current_index[])
            Gtk.select(Gtk.GAccessor.selection(tree_view), iter)
            name = list_store[iter, 1]
            set_gtk_property!(radio_name_label, :label, name)
            println("⏮ $name")
        end
    end
    
    signal_connect(btn_next, "clicked") do _
        n = length(list_store)
        if n > 0
            current_index[] = min(n, current_index[] + 1)
            iter = Gtk.iter_from_index(list_store, current_index[])
            Gtk.select(Gtk.GAccessor.selection(tree_view), iter)
            name = list_store[iter, 1]
            set_gtk_property!(radio_name_label, :label, name)
            println("⏭ $name")
        end
    end
    
    signal_connect(btn_add, "clicked") do _
        show_add_dialog(win, list_store)
    end
    
    # Double-clic sur une radio = play
    signal_connect(tree_view, "row-activated") do widget, path, col
        iter = Gtk.iter_from_string_index(list_store, string(path))
        name = list_store[iter, 1]
        url = list_store[iter, 2]
        set_gtk_property!(radio_name_label, :label, name)
        println("▶ $name")
    end
    
    # Sélection simple = mettre à jour l'index courant
    selection = Gtk.GAccessor.selection(tree_view)
    signal_connect(selection, "changed") do _
        iter = Gtk.selected(selection)
        if iter !== nothing
            name = list_store[iter, 1]
            # On peut afficher juste la sélection sans lancer
        end
    end
    
    return win
end

# Dialog pour ajouter une radio
function show_add_dialog(parent, list_store)
    dialog = GtkDialog("Ajouter une radio", parent, 
                       Gtk.GConstants.GtkDialogFlags.MODAL,
                       (("Annuler", Gtk.GConstants.GtkResponseType.CANCEL),
                        ("Ajouter", Gtk.GConstants.GtkResponseType.ACCEPT)))
    
    set_gtk_property!(dialog, :width_request, 400)
    
    content = Gtk.GAccessor.content_area(dialog)
    
    vbox = GtkBox(:v)
    set_gtk_property!(vbox, :spacing, 10)
    set_gtk_property!(vbox, :margin, 10)
    push!(content, vbox)
    
    push!(vbox, GtkLabel("Nom de la radio :"))
    name_entry = GtkEntry()
    push!(vbox, name_entry)
    
    push!(vbox, GtkLabel("URL du flux :"))
    url_entry = GtkEntry()
    set_gtk_property!(url_entry, :placeholder_text, "http://...")
    push!(vbox, url_entry)
    
    showall(dialog)
    
    response = run(dialog)
    
    if response == Gtk.GConstants.GtkResponseType.ACCEPT
        name = get_gtk_property(name_entry, :text, String)
        url = get_gtk_property(url_entry, :text, String)
        if !isempty(name) && !isempty(url)
            push!(list_store, (name, url))
            println("Ajouté : $name → $url")
        end
    end
    
    destroy(dialog)
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