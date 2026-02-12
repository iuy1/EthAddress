# 以太坊靓号地址生成器

## 使用

1. 生成随机私钥，为了方便演示假设为

```txt
0000000100000001000000010000000100000001000000010000000100000001
```

1. 计算相应公钥

```txt
d798be011def700daf1a62a3670eb5c606dc4cb11acf9366f86d5a82c657135b
4d3e65aefc08574c72da152af9f78f77666b58257c1554d57424a39807293f5a
```

1. 运行

```sh
swift run Cli d798be011def700daf1a62a3670eb5c606dc4cb11acf9366f86d5a82c657135b4d3e65aefc08574c72da152af9f78f77666b58257c1554d57424a39807293f5a --leading_zeros
```

得到输出

```txt
score:  6  tweak:   279ae07  address: 000000b54cfd45f3f2966ba0e73fd9158118663b
```

1. 将私钥和 tweak 相加得到调整后的私钥

```txt
000000010000000100000001000000010000000100000001000000010279ae08
```

注意：本程序在计算时跳过了对一些小概率情况的检查，且可能存在未知 bug ，因此您应该将生成的私钥导入到钱包中来确保生成的地址是正确的。

## 添加自定义筛选规则

您可以修改 [score.metal](Sources/EthAddress/score.metal) 和 [Cli.swift](Sources/Cli/Cli.swift)

## benchmark

在 Apple M3 芯片上的速度约为 16 M/s （约为 [profanity2](https://github.com/1inch/profanity2) 的 1/5 ）

速度的差异主要是因为循环没有展开（Metal 没有循环展开指令），其次是因为计算椭圆曲线时数学优化不足

## 参考资料

- <https://github.com/bitcoin-core/secp256k1>
- <https://github.com/1inch/profanity2>
- <https://github.com/DenizBasgoren/sha3>
- <https://github.com/ethereumbook/ethereumbook>
- <https://github.com/mikecvet/sha-3>
- <https://emn178.github.io/online-tools/keccak_256.html>
