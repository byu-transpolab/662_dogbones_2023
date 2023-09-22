## Create OD metadata

#read in balanced turning movement counts
turning <- c("obs","node","originleg","destination leg or turning movement","0-15vol","...","0-15%truck","...")

### make vehicle inputs
# for list of inputs, find vol for each 15 min segment with composite truck%. Put in hrly flow. Duplicate 0-15 for a prime
inputs <-c("list of ordered inputs")
output <- c("Input","0-15vol (vph)","...","0-15 truck%","...")

#write to a csv

### create od
Inputs <- c("list of ordered routes")

## for each turning movement, find the decimal percentage making that movement

od_feed <-c("movement","dec% 0-15","...")

## for the given Inputs, split into origin/destination pairs (left 4 is origin, right 4 is destination)
#####change 10241 to 1025

# somehow for each route we need to find the intermediate legs that the vehicles travel on
### ex 10341003 is 1034,1033,1021,1023,1011,1013,1001,1003
# then for each pair, we need to find the probability of that happening from od_feed
# find the product of the string of probabilities. The sum of all inputs from one leg should be equal to 1
# repeat for each time (0-15,15-30,...)

Ouput <- c("Route","0-15 percent","...")