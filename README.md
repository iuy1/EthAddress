# Ethereum Vanity Address Generator

## Usage

1. Generate a random private key. For demonstration purposes, assume it is:

```txt
0000000100000001000000010000000100000001000000010000000100000001
```

1. Calculate the corresponding public key:

```txt
d798be011def700daf1a62a3670eb5c606dc4cb11acf9366f86d5a82c657135b
4d3e65aefc08574c72da152af9f78f77666b58257c1554d57424a39807293f5a
```

1. Run:

```sh
swift run Cli d798be011def700daf1a62a3670eb5c606dc4cb11acf9366f86d5a82c657135b4d3e65aefc08574c72da152af9f78f77666b58257c1554d57424a39807293f5a --leading_zeros
```

Output:

```txt
score:  6  tweak:   279ae07  address: 000000b54cfd45f3f2966ba0e73fd9158118663b
```

1. Add the private key and tweak to obtain the adjusted private key:

```txt
000000010000000100000001000000010000000100000001000000010279ae08
```

**Note:** This program skips checking for some low-probability edge cases during computation and may contain unknown bugs. Therefore, you should import the generated private key into a wallet to ensure the generated address is correct.

## Adding Custom Filter Rules

You can modify [score.metal](Sources/EthAddress/score.metal) and [Cli.swift](Sources/Cli/Cli.swift)

## Benchmark

Speed on Apple M3 chip is approximately 16 M/s (about 1/5 of [profanity2](https://github.com/1inch/profanity2))

The speed difference is mainly due to unrolled loops (Metal lacks loop unrolling instructions), and secondly due to insufficient mathematical optimization when computing elliptic curves.

## References

- <https://github.com/bitcoin-core/secp256k1>
- <https://github.com/1inch/profanity2>
- <https://github.com/DenizBasgoren/sha3>
- <https://github.com/ethereumbook/ethereumbook>
- <https://github.com/mikecvet/sha-3>
- <https://emn178.github.io/online-tools/keccak_256.html>
