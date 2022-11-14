# <img src="/static/cpu.png" width="40" align=center /> RISC-CPU

![](https://img.shields.io/badge/language-verilog-brightgreen) 

- [课程地址](https://github.com/ACMClassCourses/RISCV-CPU)

## Design

![Arch][static/Arch.svg]

### 配置问题

#### Verilog Format

1. 到[Verilog Format (github)](https://github.com/ericsonj/verilog-format)上下载code zip
2. Check本地是否有 **Java8**, 没有需要重新下ww
3. 改preference settings的时候发现即使改了相关参数(e.g. indent)依旧无效, 但是plugin path导到的properties目录是对的: github 上有issue说明了[解决方案](https://github.com/ericsonj/vscode-verilogformar/issues/1)

5. 注释不支持中文? 是因为JDK默认编码不是utf-8, google一下, 添加一个环境变量就好了 (

~~这真是个头疼的玩意~~ :sneezing_face:

#### riscv-gnu-toolchain

注意需要--recursive命令来确保整个包都安装完毕, 大概是6.65G左右

```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
```

[github官方教程](https://github.com/riscv-collab/riscv-gnu-toolchain)

`git clone`的时候可能会存在terminal proxy的问题, 这个需要见(zi)仁(sheng)见(zi)智(mie)了

如果用的是Clash, 可以在`General`一栏点击port边上的terminal icon就可以简单方便的打开已经代理完成的Powershell/CMD, 接下来调用 git submodule update --init --recursive 就可以了.

- set HTTP_PROXY 会在cmd关闭后失效，下次打开cmd需要重新设置。

~~看清楚自己的port是多少, 不要清一色1080 (~~

### 仿真部分

Vivado待填坑...

## General

- the size of mem is 128KB, which implies the `mem_a` only 17:0 is used.
- About Verilog
  - use non-blocking assignment for `reg` type in always @(posedge/negedge)
  - use assign statement for `wire` type

## Sketch

### Instruction Fetch (IF)

- InsFetcher: Fetch instruction

  pc reg: program counter