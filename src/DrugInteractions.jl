"""
DrugInteractions.jl

Gtk4-based GUI to query drug interactions via RxNav.
"""
module DrugInteractions

export drug_interactions_app

using Gtk4
using RxNav

""" The Gtk4 app. Titles of app windows are `title` and 'rlabel`, and the stay_open argument is for testing """
function drug_interactions_app(title = "Drug Interaction Queries", rlabel = "Results"; stay_open = true)
    label = GtkLabel("Drug(s) to Check:  ")
    substances = GtkEntry()
    substances.hexpand = true

    topbox = GtkBox(:h)
    push!(topbox, label)
    push!(topbox, substances)

    highonly = GtkCheckButton("Only Search For High Severity")
    highonly.active = false

    resultbutton = GtkButton(rlabel)

    win = GtkWindow(title, 420, 120)
    vbox = GtkBox(:v)
    push!(win, vbox)
    push!(vbox, topbox)
    push!(vbox, highonly)
    push!(vbox, resultbutton)

    # tree view – set up once
    headercols = ["Substance 1", "Substance 2", "Severe?", "Description"]
    liststore = GtkListStore(String, String, String, String)
    tv = GtkTreeView(GtkTreeModel(liststore))

    rTxt = GtkCellRendererText()
    for (i, title) in enumerate(headercols)
        col = GtkTreeViewColumn(title, rTxt, Dict("text" => i - 1))
        col.resizable = true
        push!(tv, col)
    end

    function queryRxNav(_w)
        high = highonly.active
        text = something(substances.text, "")
        drugs = filter!(!isempty, String.(strip.(split(text, r"\s+"))))
        isempty(drugs) && return

        datatuples = interactions(drugs; severeonly = high)
        empty!(liststore)

        for t in datatuples
            sev = t.is_severe === true ?
                "Yes" :
                t.is_severe === false ? "No" : string(t.is_severe)
            push!(liststore, (string(t.drug1), string(t.drug2), sev, string(t.description)))
        end

        popup = GtkWindow("Results ($(length(datatuples)) warnings or interactions found)", 700, 450)
        sw = GtkScrolledWindow()

        # Horizontal and or vertical scrollbars when needed
        Gtk4.G_.set_policy(sw, Gtk4.PolicyType_AUTOMATIC, Gtk4.PolicyType_AUTOMATIC)
        sw[] = tv
        popup[] = sw
        show(popup)
    end

    signal_connect(queryRxNav, resultbutton, "clicked")

    !isinteractive() && @async Gtk4.GLib.start_main_loop()

    condition = Condition()

    if !stay_open
        @async begin
            sleep(5)
            notify(condition)
            close(win)
        end
    end
    
    signal_connect(win, "close-request") do _
        notify(condition)
        false
    end
    show(win)
    wait(condition)
end

end # module DrugInteractions
