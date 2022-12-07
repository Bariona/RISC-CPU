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



- [ ] is_full signal: to dispatch

- [x] while issuing an instruction into the FIFO, consider at the same time ALU has calculated the result of Qi/Qj

  You need to update the information, i.e., Qi/Qj = 0, Vi/Vj = result from ALU



- [ ] load/store 指令都会在做两次store 或者 load.... 这是为什么 (是因为一直set ena_mc = 1导致的)

  solution: remove the whole code into memory controller.

  ​