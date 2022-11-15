## InsFetcher: 

:dart:goal: Fetch instruction ... 

- pc reg: program counter

- ICache (i.e. Instruction Queue):

  size: 256 entries (7:0) 

  Since it's a I`$`, using the knowledge acquired in *Arch*, we use Direct Map mechanism for it:

  - components: index, valid_bit, value


1. reset = 1: clear the state

2. ready = 0: postpone the action

3. otherwise: run the process


## Predictor

![predict](https://www.researchgate.net/publication/221219835/figure/fig3/AS:671528857399296@1537116364016/Two-bit-saturating-counter.png)

