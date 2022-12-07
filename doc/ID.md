Decode and Dispatch instruction

- to RS
- to LSB




### Decoder

- only Store and Branch instruction has no `rd`, set `rd = 0` (otherwise, there will be mistaken-write in register file while committing)

  ​