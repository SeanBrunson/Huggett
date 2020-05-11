Code replicates Huggett 1996 Journal of Monetary Economics paper. Specifically replicating the results from Table 3, row 3 of uncertain lifetimes section.

Biggest difference between this replication and the paper is that I did not have the average income nor did I have the survival probabilities. Instead, I used the income process from Cocco, Gomes, and Maenhout 2005 Review of Financial Studies paper. Agents in this replication are assumed to be college graduates.

The death probabilities by age came from https://www.ssa.gov/oact/STATS/table4c6.html. I used the male estimates from the 2017 table.

The main.jl is the main code to find the equilibrium capital and transfer values. This replication does a great job matching the key moments from the Huggett paper.
