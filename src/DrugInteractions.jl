module DrugInteractions

export drug_interactions_app

using Gtk
using RxNav

const _apps = GtkWindow[]
const _apps_should_persist = [true]

"""
    drug_interactions_app(title = "Drug Interaction Queries", rlabel = "Results")

Create a `Gtk` widget with entries for one or more substances to check for interactions.
"""
function drug_interactions_app(title = "Drug Interaction Queries", rlabel = "Results")
    label = GtkLabel("Drug(s) to Check:  ")
    substances = GtkEntry()
    topbox = GtkBox(:h)
    push!(topbox, label, substances)
    highonly = GtkCheckButton("Only Search For High Severity")
    set_gtk_property!(highonly, :active, true)
    resultbutton = GtkButton(rlabel)
    win = GtkWindow(title, 300, 100) |> (GtkFrame() |> (vbox = GtkButtonBox(:v)))
    push!(vbox, topbox, highonly, resultbutton)
    set_gtk_property!(substances, :expand, true)

    function queryRxNav(w)
        high = get_gtk_property(highonly, :active, Bool)
        drugs = split(something(get_gtk_property(substances, :text, String), ""), r"\s+")
        if !isempty(drugs)
            tuples = length(drugs) == 1 ? interaction(first(drugs); ONCHigh = high) :
                                          interaction_within_list(string.(drugs))
            lines = "Substance 1     Substance 2    Severity    Description\n" * "-"^160 * "\n"
            for t in tuples
                line = rpad(t[1], 20) * " " * rpad(t[2], 20) * " " * rpad(t[3], 8) * " " * t[4]
                lines *= line * "\n"
            end
            info_dialog(lines)
        else
            info_dialog("No results found")
        end
    end

    signal_connect(queryRxNav, resultbutton, :clicked)

    if _apps_should_persist[1]
        cond = Condition()
        endit(w) = notify(cond)
        signal_connect(endit, win, :destroy)
        showall(win)
        wait(cond)
    else
        sleep(5)
    end
end

end # module
