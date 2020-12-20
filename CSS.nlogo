extensions [ nw ]

globals [ collective-thought timestep-less-than-five closeness-of-conspirators betweenness-of-conspirators eigenvector-of-conspirators pagerank-of-conspirators tmp2 closeness_list num-conspirators num-inoculators ranked-susceptibles conspiracy-target-center inoculation-target-center conspiracy-target-center-rank inoculation-target-center-rank]

turtles-own [ agent-thought job already-interacted? distance-from-zero closeness_value betweenness_value eigenvector_value pagerank_value distance_from_oracle_mean difference-with-oracle count-my-links ] ;;property related to adoption
;;new code


to setup
  ca
  random-seed random_seed
  reset-ticks
  set-default-shape turtles "circle"
  if network-type = "random" [
    nw:generate-random turtles links num-susceptibles 0.05 [ set color white ]
  ]
  if network-type = "preferential-attachment"[
    nw:generate-preferential-attachment turtles links num-susceptibles 1 [ set color white ]
  ]
  if network-type = "watts-strogatz"[
    nw:generate-watts-strogatz turtles links num-susceptibles 2 0.01 [ set color white ]
  ]
  ask turtles [
    set count-my-links count my-links
    setxy random-xcor random-ycor
    set agent-thought random-float 2
    set job "regular"
  ]
  ;; assigns the * centrality of each agent to its variable "*_value"
  closeness
  betweenness
  eigenvector
  pagerank
  set num-inoculators round (num-susceptibles * ratio-targetted * inoculation-to-conspiracy-ratio)
  set num-conspirators round (num-susceptibles * ratio-targetted * (1 - inoculation-to-conspiracy-ratio))
  set ranked-susceptibles sort-on [runresult target-strategy] turtles with [job = "regular"]
  print(ranked-susceptibles)
  set conspiracy-target-center-rank round (length ranked-susceptibles * (  1 - ((exp (4 * (1 - conspiracy-target-log-rank))) - 1)/(e ^ 4 - 1) )  )
  create-turtles num-conspirators [
    set agent-thought 0
    set job "conspirator"
    set color red
    let my-target-rank conspiracy-target-center-rank + -1 ^ (count turtles with [job = "conspirator"] - 1) * abs round ((count turtles with [job = "conspirator"] - 1) / 2)
    if my-target-rank >= length ranked-susceptibles [
     set my-target-rank conspiracy-target-center-rank - abs round ((count turtles with [job = "conspirator"] - 1) / 2) - 1
    ]
    if my-target-rank < 0 [
     set my-target-rank abs round ((count turtles with [job = "conspirator"] - 1) / 2)
    ]
    if count turtles with [job = "conspirator"] = 1 [
    set conspiracy-target-center [runresult target-strategy] of item my-target-rank ranked-susceptibles
    ]
    create-link-with item my-target-rank ranked-susceptibles
  ]
  set inoculation-target-center-rank round (length ranked-susceptibles * (  1 - ((exp (4 * (1 - inoculation-target-log-rank))) - 1)/(e ^ 4 - 1) )   )
  create-turtles num-inoculators [
    set agent-thought 1
    set job "right"
    set color blue
    let my-target-rank-i inoculation-target-center-rank + -1 ^ (count turtles with [job = "right"] - 1) * abs round ((count turtles with [job = "right"] - 1) / 2)
    if my-target-rank-i >= length ranked-susceptibles [
     set my-target-rank-i inoculation-target-center-rank - abs round ((count turtles with [job = "right"] - 1) / 2) - 1
    ]
    if my-target-rank-i < 0 [
     set my-target-rank-i abs round ((count turtles with [job = "right"] - 1) / 2)
    ]
    if count turtles with [job = "right"]  = 1 [
    set inoculation-target-center [runresult target-strategy] of item my-target-rank-i ranked-susceptibles
    ]
    create-link-with item my-target-rank-i ranked-susceptibles
  ]
  ;;ask turtle 3 [
  ;;  set agent-thought 0
  ;;  set job "conspirator"
  ;; set color red
  ;;]
  ;;ask turtle 6 [
  ;; set agent-thought 1
  ;;  set job "right"
  ;;  set color blue
  ;;]
  ;;ask n-of 4 turtles with [job = "right"] [ create-link-with one-of other turtles with [job = "right"]  ]
  set closeness-of-conspirators ((sum [closeness_value] of turtles with [ job = "conspirator" ]) / (num-conspirators))
  set betweenness-of-conspirators ((sum [betweenness_value] of turtles with [ job = "conspirator" ]) / (num-conspirators))
  set eigenvector-of-conspirators ((sum [eigenvector_value] of turtles with [ job = "conspirator" ]) / (num-conspirators))
  set pagerank-of-conspirators ((sum [pagerank_value] of turtles with [ job = "conspirator" ]) / (num-conspirators))
  set tmp2 0
end




to go
  ask turtles [ set already-interacted? false ]
  ;;  if ticks = 250 [
  ;;    ask n-of 5 turtles [
  ;;      set agent-thought 2
  ;;      set job "right"
  ;;    ]
  ;;  ]
  ;;  if ticks = 500 [
  ;;    ask turtles with [ job = "right" ] [
  ;;      create-link-with turtle 0
  ;;      create-link-with turtle 1
  ;;      create-link-with turtle 2
  ;;      create-link-with turtle 3
  ;;      create-link-with turtle 4
  ;;    ]
  ;;  ]
  ask turtles [
    ;;already-interacted plays the role of a control. With this control, if an agent has experienced an interaction in the current timestep, then it can not be the "center of interaction", i.e., the agents that starts
    ;;the interaction. With this control, each agent may experience "at maximum" the number of its links.
    if true [;not already-interacted? [
      let target one-of link-neighbors
      if job = "conspirator" [;; I am conspirator
        if [job] of target = "conspirator" [;;target is conspirator
          set agent-thought 0
          set already-interacted? true
          ask target [ set already-interacted? true]
        ]
        if [job] of target = "regular" [;;target is regular
          if random-float 1 < p-of-interaction [ ask target [set agent-thought ((agent-thought + 0) / 2) ]
            set already-interacted? true
            ask target [ set already-interacted? true]
          ]
        ]
        if [job] of target = "right" [;;target is right
          set already-interacted? true
          ask target [ set already-interacted? true]
        ]
      ]
      if job = "regular" [;; I am regular
        if [job] of target = "conspirator" [;;target is conspirator
          if random-float 1 < p-of-interaction [ set agent-thought ((agent-thought + [agent-thought] of target) / 2)
            set already-interacted? true
            ask target [ set already-interacted? true]
          ]
        ]
        if [job] of target = "regular" [;;target is regular
          if random-float 1 < p-of-interaction [
            set agent-thought ((agent-thought + [agent-thought] of target) / 2)
            let tmp agent-thought
            ask target [set agent-thought ((agent-thought + tmp) / 2)]
            set already-interacted? true
            ask target [ set already-interacted? true]
          ]
        ]
        if [job] of target = "right" [
          if random-float 1 < p-of-interaction [set agent-thought ((agent-thought + 1) / 2)]
          set already-interacted? true
          ask target [ set already-interacted? true]
        ]
      ]
      if job = "right"  [
        if [job] of target = "conspirator" [;;target is conspirator
          set already-interacted? true
          ask target [ set already-interacted? true]
        ]
        if [job] of target = "regular" [;;target is regular
          if random-float 1 < p-of-interaction [ ask target [set agent-thought ((agent-thought + 1) / 2) ]
            set already-interacted? true
            ask target [ set already-interacted? true]
          ]
        ]
        if [job] of target = "right"[
          set already-interacted? true
          ask target [ set already-interacted? true]
        ]
      ]
    ]
  ]
  set collective-thought ( ( sum [ agent-thought ] of turtles with [ job = "regular" ] ) / ( count turtles with [ job = "regular" ] ) )
  ask turtles with [job = "regular"] [ set color scale-color white agent-thought 0 1  ]
  tick
end


to-report timestep-less-than-five-r
  report timestep-less-than-five
end


to-report closeness-of-conspirators-r
  report closeness-of-conspirators
end

to-report betweenness-of-conspirators-r
  report betweenness-of-conspirators
end

to-report eigenvector-of-conspirators-r
  report eigenvector-of-conspirators
end

to-report pagerank-of-conspirators-r
  report pagerank-of-conspirators
end

to-report collective-thought-r
  report collective-thought
end

to-report std-of-degree-distribution
  report standard-deviation [count-my-links] of turtles
end

to-report max-degree
  report max [count-my-links] of turtles
end
to-report global-clustering-coefficient
  let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of turtles
  let triplets sum [ count my-links * (count my-links - 1) ] of turtles
  report closed-triplets / triplets
end




to-report mean-closeness-of-network
  report ( ( sum [ closeness_value ] of turtles ) / ( count turtles ) )
end


;;make nodes bigger as they get closer to oracle-mean



to layout
  let factor sqrt count turtles
  if factor = 0 [ set factor 1 ]
  layout-spring turtles links (1 / factor) (14 / factor) (1.5 / factor)
end


;to sizebasedonmean
;  ask turtles [
;    set label ""
;    set distance_from_oracle_mean abs (agent-thought - 1)
;    set color scale-color green distance_from_oracle_mean 0 1
;    set size distance_from_oracle_mean
;  ]
;  normalize-sizes-and-colors-mean
;end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Centrality Measures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to closeness
  ask turtles [ set closeness_value nw:closeness-centrality ]
end

to betweenness
  ask turtles [ set betweenness_value nw:betweenness-centrality ]
end

to eigenvector
  ask turtles [ set eigenvector_value nw:eigenvector-centrality ]
end

to pagerank
  ask turtles [ set pagerank_value nw:page-rank ]
end

; Takes a centrality measure as a reporter task, runs it for all nodes
; and set labels, sizes and colors of turtles to illustrate result
;to centrality_closeness [ measure ]
;  ask turtles [
;    let res (runresult measure) ; run the task for the turtle
;    ifelse is-number? res [
;      set label precision res 2
;      set size res ; this will be normalized later
;
;      ;;define the closeness for each turtle
;      set closeness_value label
;    ]
;    [ ; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
;      set label res
;      set size 1
;    ]
;
;
;  ]
;  normalize-sizes-and-colors-centrality
;end

;to centrality_betweenness [ measure ]
;  ask turtles [
;    let res (runresult measure) ; run the task for the turtle
;    ifelse is-number? res [
;      set label precision res 2
;      set size res ; this will be normalized later
;
;      ;;define the closeness for each turtle
;      set betweenness_value label
;    ]
;    [ ; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
;      set label res
;      set size 1
;    ]
;
;
;  ]
;  normalize-sizes-and-colors-centrality
;end

;to centrality_eigenvector [ measure ]
;  ask turtles [
;    let res (runresult measure) ; run the task for the turtle
;    ifelse is-number? res [
;      set label precision res 2
;      set size res ; this will be normalized later
;
;      ;;define the closeness for each turtle
;      set eigenvector_value label
;    ]
;    [ ; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
;      set label res
;      set size 1
;    ]
;
;
;  ]
;  normalize-sizes-and-colors-centrality
;end

;to centrality_pagerank [ measure ]
;  ask turtles [
;    let res (runresult measure) ; run the task for the turtle
;    ifelse is-number? res [
;      set label precision res 2
;      set size res ; this will be normalized later
;
;      ;;define the closeness for each turtle
;      set pagerank_value label
;    ]
;    [ ; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
;      set label res
;      set size 1
;    ]
;
;
;  ]
;  normalize-sizes-and-colors-centrality
;end




; We want the size of the turtles to reflect their centrality, but different measures
; give different ranges of size, so we normalize the sizes according to the formula
; below. We then use the normalized sizes to pick an appropriate color.
;to normalize-sizes-and-colors-centrality
;  if count turtles > 0 [
;    let sizes sort [ size ] of turtles ; initial sizes in increasing order
;    let delta last sizes - first sizes ; difference between biggest and smallest
;    ifelse delta = 0 [ ; if they are all the same size
;      ask turtles [ set size 1 ]
;    ]
;    [ ; remap the size to a range between 0.5 and 2.5
;      ask turtles [ set size ((size - first sizes) / delta) * 2 + 0.5 ]
;    ]
;    ask turtles [ set color scale-color red size 0 5 ] ; using a higher range max not to get too white...
;  ]
;end
;
;
;to normalize-sizes-and-colors-mean
;  if count turtles > 0 [
;    ask turtles [ set size (1 / size) ]
;    let sizes sort [ size ] of turtles ; initial sizes in increasing order
;    let delta last sizes - first sizes ; difference between biggest and smallest
;    ifelse delta = 0 [ ; if they are all the same size
;      ask turtles [ set size 1 ]
;    ]
;    [ ; remap the size to a range between 0.5 and 2.5
;      ask turtles [ set size ((size - first sizes) / delta) * 2 + 0.5 ]
;    ]
;  ]
;end
@#$#@#$#@
GRAPHICS-WINDOW
273
15
776
519
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
29
192
238
225
num-susceptibles
num-susceptibles
0
200
100.0
1
1
NIL
HORIZONTAL

BUTTON
57
506
130
539
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
131
506
194
539
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
50
117
132
150
NIL
eigenvector
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
132
117
214
150
NIL
betweenness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
132
149
214
182
NIL
closeness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
50
149
132
182
NIL
pagerank
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
85
473
177
506
random_seed
random_seed
-1000000
1000000
-36.0
1
1
NIL
HORIZONTAL

PLOT
776
15
1130
225
Collective Thought
NIL
NIL
0.0
3000.0
0.0
1.0
true
false
"" ""
PENS
"mean" 1.0 0 -13840069 true "" "plot mean [agent-thought] of turtles with [job = \"regular\"]"
"median" 1.0 0 -2674135 true "" "plot median [agent-thought] of turtles with [job = \"regular\"]"
"variance" 1.0 0 -10141563 true "" "plot variance [agent-thought] of turtles with [job = \"regular\"]"

CHOOSER
39
64
225
109
network-type
network-type
"preferential-attachment" "random" "watts-strogatz"
0

SLIDER
29
257
238
290
inoculation-to-conspiracy-ratio
inoculation-to-conspiracy-ratio
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
28
397
237
430
p-of-interaction
p-of-interaction
0
1
1.0
0.01
1
NIL
HORIZONTAL

MONITOR
1191
41
1371
86
NIL
std-of-degree-distribution
17
1
11

MONITOR
1437
40
1630
85
NIL
collective-thought-r
17
1
11

SLIDER
29
321
238
354
inoculation-target-log-rank
inoculation-target-log-rank
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
29
224
238
257
ratio-targetted
ratio-targetted
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
29
290
238
323
conspiracy-target-log-rank
conspiracy-target-log-rank
0
1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
57
539
130
572
NIL
layout
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
54
353
213
398
target-strategy
target-strategy
"closeness_value" "betweenness_value" "eigenvector_value" "pagerank_value"
2

PLOT
996
483
1196
633
Targetability
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -16777216 true "" "histogram [runresult target-strategy] of turtles with [job = \"regular\"]"

PLOT
1211
131
1627
467
plot 1
NIL
NIL
0.0
1.0
0.0
10.0
true
true
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [agent-thought] of turtles with [job = \"regular\"]"

BUTTON
218
595
281
628
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test1-preferential" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>timestep-less-than-five-r</metric>
    <metric>closeness-of-conspirators-r</metric>
    <metric>nw:mean-path-length</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="collective-thought-timeseries-preferential" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>collective-thought-r</metric>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test1-watts" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>timestep-less-than-five-r</metric>
    <metric>closeness-of-conspirators-r</metric>
    <metric>nw:mean-path-length</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;watts-strogatz&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="collective-thought-timeseries-watts" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="8000"/>
    <metric>collective-thought-r</metric>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;watts-strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_seed">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all-variables-preferential" repetitions="10000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>timestep-less-than-five-r</metric>
    <metric>closeness-of-conspirators-r</metric>
    <metric>betweenness-of-conspirators-r</metric>
    <metric>eigenvector-of-conspirators-r</metric>
    <metric>pagerank-of-conspirators-r</metric>
    <metric>nw:mean-path-length</metric>
    <metric>std-of-degree-distribution</metric>
    <metric>max-degree</metric>
    <metric>global-clustering-coefficient</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all-variables-watts" repetitions="10000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>timestep-less-than-five-r</metric>
    <metric>closeness-of-conspirators-r</metric>
    <metric>betweenness-of-conspirators-r</metric>
    <metric>eigenvector-of-conspirators-r</metric>
    <metric>pagerank-of-conspirators-r</metric>
    <metric>nw:mean-path-length</metric>
    <metric>std-of-degree-distribution</metric>
    <metric>max-degree</metric>
    <metric>global-clustering-coefficient</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;watts-strogatz&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="population-100-preferential" repetitions="250" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>timestep-less-than-five-r</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="50"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="population-500-preferential" repetitions="250" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>timestep-less-than-five-r</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="5"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="250"/>
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="population-1000-preferential" repetitions="250" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>timestep-less-than-five-r</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
      <value value="500"/>
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="population-1000-watts" repetitions="250" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>timestep-less-than-five-r</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
      <value value="500"/>
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;watts-strogatz&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="population-100-watts" repetitions="250" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>timestep-less-than-five-r</metric>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="50"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;watts-strogatz&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-with-all-turtles" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>[ agent-thought ] of turtles with [ job = "regular"]</metric>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rights">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-conspirators">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_seed">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp1_Conspirators_RatioTargetted_AgentThought" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500000"/>
    <metric>median [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>mean [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>variance [agent-thought] of turtles with [job = "regular"]</metric>
    <steppedValueSet variable="p-of-interaction" first="0.01" step="0.01" last="1"/>
    <enumeratedValueSet variable="num-susceptibles">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inoculation-to-conspiracy-ratio">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conspiracy-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inoculation-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="target-strategy">
      <value value="&quot;eigenvector_value&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_seed">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ratio-targetted" first="0.01" step="0.01" last="1"/>
  </experiment>
  <experiment name="(Exp 1 in paper)Exp2_ConspiratorsInoculators_RatioTargetted_AgentThought" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>median [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>mean [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>variance [agent-thought] of turtles with [job = "regular"]</metric>
    <steppedValueSet variable="p-of-interaction" first="0.1" step="0.1" last="1"/>
    <enumeratedValueSet variable="num-susceptibles">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="inoculation-to-conspiracy-ratio" first="0" step="0.05" last="0.95"/>
    <enumeratedValueSet variable="conspiracy-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inoculation-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="target-strategy">
      <value value="&quot;eigenvector_value&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_seed">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ratio-targetted" first="0.05" step="0.05" last="1"/>
  </experiment>
  <experiment name="Exp3_TargetLogRank_Eigenvector_AgentThought" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>conspiracy-target-center</metric>
    <metric>inoculation-target-center</metric>
    <metric>conspiracy-target-center-rank</metric>
    <metric>inoculation-target-center-rank</metric>
    <metric>median [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>mean [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>variance [agent-thought] of turtles with [job = "regular"]</metric>
    <steppedValueSet variable="p-of-interaction" first="0.2" step="0.2" last="1"/>
    <enumeratedValueSet variable="num-susceptibles">
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="inoculation-to-conspiracy-ratio" first="0" step="0.1" last="0.9"/>
    <enumeratedValueSet variable="conspiracy-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="inoculation-target-log-rank" first="0" step="0.05" last="1"/>
    <enumeratedValueSet variable="target-strategy">
      <value value="&quot;eigenvector_value&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ratio-targetted" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="Exp3_TargetLogRank_Closeness_AgentThought" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>conspiracy-target-center</metric>
    <metric>inoculation-target-center</metric>
    <metric>conspiracy-target-center-rank</metric>
    <metric>inoculation-target-center-rank</metric>
    <metric>median [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>mean [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>variance [agent-thought] of turtles with [job = "regular"]</metric>
    <steppedValueSet variable="p-of-interaction" first="0.2" step="0.2" last="1"/>
    <enumeratedValueSet variable="num-susceptibles">
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="inoculation-to-conspiracy-ratio" first="0" step="0.1" last="0.9"/>
    <enumeratedValueSet variable="conspiracy-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="inoculation-target-log-rank" first="0" step="0.05" last="1"/>
    <enumeratedValueSet variable="target-strategy">
      <value value="&quot;closeness_value&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ratio-targetted" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="(Exp2 in paper)Exp3_1Inoc1Consp_TargetLogRank_Eigenvector_AgentThought" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>conspiracy-target-center</metric>
    <metric>inoculation-target-center</metric>
    <metric>conspiracy-target-center-rank</metric>
    <metric>inoculation-target-center-rank</metric>
    <metric>median [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>mean [agent-thought] of turtles with [job = "regular"]</metric>
    <metric>variance [agent-thought] of turtles with [job = "regular"]</metric>
    <steppedValueSet variable="p-of-interaction" first="0.2" step="0.2" last="1"/>
    <enumeratedValueSet variable="num-susceptibles">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ratio-targetted">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inoculation-to-conspiracy-ratio">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conspiracy-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="inoculation-target-log-rank" first="0" step="0.05" last="1"/>
    <enumeratedValueSet variable="target-strategy">
      <value value="&quot;eigenvector_value&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="(Histograms in paper)histogram" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>[agent-thought] of turtles with [ job = "regular" ]</metric>
    <enumeratedValueSet variable="ratio-targetted">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-of-interaction">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inoculation-target-log-rank">
      <value value="0.1"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-susceptibles">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inoculation-to-conspiracy-ratio">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="target-strategy">
      <value value="&quot;eigenvector_value&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conspiracy-target-log-rank">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random_seed">
      <value value="-36"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
