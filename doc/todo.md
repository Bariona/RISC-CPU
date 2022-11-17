## Questions

- [ ] reg初始化? output用reg/wire? (两边必有一个reg)
- [x] 为什么要先assign q_full 在assign full = q_full, 不可以一步到位吗? A: 可
- [x] top module中rst_delay作用仅仅是为了多rst一个clock吗? A: yes
- [ ] hci什么用处, 上板的时候写入mem 或者用来debug一些东西用的吗? host communication interface.
      电脑上模拟应该就是ram $\leftrightarrow$ cpu, 上板的时候可以调成debug模式就是ram $\leftrightarrow$ hci的交互 ?(
- [ ] branch predictor是不是要先Decode?
- [ ] 超前进位加法器
- [ ] instruction from mc to icache, add an arrival signal?
- [x] cache独立出来, cache line expasion...
- [ ] mem被icache读和dcache读/写抢占 
- [ ] 去掉硬编码