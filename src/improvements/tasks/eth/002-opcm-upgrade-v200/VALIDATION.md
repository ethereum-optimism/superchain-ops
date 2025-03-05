## Understanding Task Calldata

Multicall3DelegateCall calldata:
```bash

```

### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        ,
        , 
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: []() - Mainnet OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...` See below for decoding.

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>

[
    (
        ,
        ,
        
    )
]
```
1. First tuple (Unichain):
    - SystemConfigProxy: []()
    - ProxyAdmin: []()
    - AbsolutePrestate: [0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

## Tenderly State Changes
[Link]()

## Auto Generated Task State Changes

```bash

```