using Gtk
using Test
using DrugInteractions

DrugInteractions._apps_should_persist[1] = false
     
drug_interactions_app()

@test DoseCalculators._apps[end] isa GtkWindow
