"""
DrugInteractions.jl

This module provides a Gtk4-based GUI application to query drug interactions
using the RxNav Julia module, which provides access to drug interaction data.
"""
module DrugInteractions

export drug_interactions_app

using Gtk4
using RxNav

const _apps = GtkWindow[]
const _apps_should_persist = [true]

function prettyline(d1, d2, issev, desc, nl = "\n")
    return rpad(string(d1), 20) *
        rpad(string(d2), 20) *
        rpad(string(issev), 8) *
        "   " * string(desc) * nl
end

"""
    drug_interactions_app(title = "Drug Interaction Queries", rlabel = "Results")

Create a Gtk4 window with entries for one or more substances to check for interactions.
"""
function drug_interactions_app(title = "Drug Interaction Queries", rlabel = "Results")
    label = GtkLabel("Drug(s) to Check:  ")
    substances = GtkEntry()
    substances.hexpand = true

    topbox = GtkBox(:h)
    push!(topbox, label)
    push!(topbox, substances)

    highonly = GtkCheckButton("Only Search For High Severity")
    highonly.active = false

    resultbutton = GtkButton(rlabel)

    win = GtkWindow(title, 300, 100)
    vbox = GtkBox(:v)
    push!(win, vbox)

    push!(vbox, topbox)
    push!(vbox, highonly)
    push!(vbox, resultbutton)

    function queryRxNav(w)
        high = highonly.active
        text = something(substances.text, "")
        drugs = String.(strip.(split(text, r"\s+")))
        filter!(!isempty, drugs)

        if !isempty(drugs)
            tuples = interactions(drugs; severeonly = high)
            if !isempty(tuples)
                lines = prettyline("Substance 1", "Substance 2", "Severe?", "Description")
                lines *= "-"^160 * "\n"
                for t in tuples
                    arr = strip.(values(t))
                    lines *= prettyline(arr[1], arr[2], arr[3], arr[4])
                end
                @async info_dialog(lines, win)
            else
                @async info_dialog("No results found", win)
            end
        end
    end

    signal_connect(queryRxNav, resultbutton, "clicked")

    !isinteractive() && @async start_main_loop()

    condition = Condition()
    signal_connect(win, "close-request") do widget
        notify(condition)
        false
    end
    show(win)
    wait(condition)
end

end # module

