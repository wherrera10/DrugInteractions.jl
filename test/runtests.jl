using Test
using DrugInteractions
     
win = drug_interactions_app(; stay_open = false)

@test win isa GtkWindow
