- 根据端口的方向，端口类型有 3 种： 输入（input），输出（output）和双向端口（inout）。

  input、inout 类型不能声明为 reg 数据类型，因为 reg 类型是用于保存数值的，而输入端口只能反映与其相连的外部信号的变化，不能保存这些信号的值。

  output 可以声明为 wire 或 reg 数据类型