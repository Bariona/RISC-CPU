## Reservation Station

| busy | op type | Res  |  Qi  |  Qj  |  Vi  |  Vj  |  pc  |
| :--: | :-----: | :--: | :--: | :--: | :--: | :--: | :--: |
|  0   |   ADD   |      |      |      |      |      |      |
|  1   |   MUL   |      |      |      |      |      |      |
|  1   |   SUB   |      |      |      |      |      |      |

- send operands to ALU (blocking assignment)

  if ALU hasn't calculated last instruction, it will postpone current instruction. 



- once thee result is calculated, **broadcast it**?





## LoadStore Buffer

- Data Structure: FIFO
- Why FIFO? ROB need to commit in order $\Rightarrow$ store should be executed in order (FIFO)



- [ ] is_full: dispatch的处理