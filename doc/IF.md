## I$:

Mapping strategy: *direct mapping*

since all instructions's address are divided by 4, thus, pc[1:0] = 0 all the time, which means it can just be abandoned? (

Let each "cache line" contain 4 instructions, then the idx for DM should at least start at pc[4:4].

Say we have 256 entries, then the map_idx should be pc[11:4], and as for which instruction to fetch should be decided by pc[3:2].

- if not hit, then we should fill the block(ask data byte one by one from **Mem controller**)

- if hit, just simply send the instruction back

  ​

## InsFetcher: 

:dart:goal: Fetch instruction ... 

1. reset = 1: clear the state
2. ready = 0: postpone the action
3. otherwise: run the process

- pc reg: program counter

- ICache (i.e. Instruction Queue):

  size: 256 entries (7:0) 

  Since it's a `I$`, using the knowledge acquired in *Arch*, we use Direct Map mechanism for it:

  - components: index, valid_bit, value

  1). every time pc send signal to the icache to acquire instruction, if not hit, get instruction from **Mem controller** & update icache.

  2). send the instruction to Issue part

  3). send the pc to the predictor






## Predictor:

![predict](https://www.researchgate.net/publication/221219835/figure/fig3/AS:671528857399296@1537116364016/Two-bit-saturating-counter.png)

