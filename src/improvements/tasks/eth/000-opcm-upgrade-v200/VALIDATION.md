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
        false, 
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
        
    ), 
    (
        ,
        ,
        
    ),
    (
        ,
        ,
        
    )
]
```
1. First tuple (OP Mainnet):
    - SystemConfigProxy: []()
    - ProxyAdmin: []()
    - AbsolutePrestate: 

2. Second tuple (Soneium):
    - SystemConfigProxy: []()
    - ProxyAdmin: []()
    - AbsolutePrestate: 

3. Third tuple (Ink):
    - SystemConfigProxy: []()
    - ProxyAdmin: []()
    - AbsolutePrestate: 


## Tenderly State Changes
[Link]()

## Auto Generated Task State Changes

```bash
```