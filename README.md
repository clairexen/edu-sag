## Educational 8-Bit Sheep-And-Goats (SAG) Verilog Reference IP

This repository demonstrates how the Sheep-and-Goats (SAG) bit manipulation
primitive can be implemented in hardware.  Everything is hard coded to a small
8‑bit data path so the logic is easy to follow and experiment with.

SAG rearranges the bits of an input word `di` according to a mask `ci`. Bits
where `ci[i]` is `1` (the *sheep*) are moved to the low end of the result in
order. Bits where `ci[i]` is `0` (the *goats*) are placed in the remaining high
positions in reverse order. The operation behaves like a small sorting network
that separates sheep from goats.

### SAG at a glance

```mermaid
flowchart LR
    di["di: data in"] --> SAG{{SAG logic}}
    ci["ci: control mask"] --> SAG
    SAG --> do["do: data out"]
```

### Operation

For each bit `i` of `di`:
1. If `ci[i] = 1`, the bit is appended to the next free low position.
2. Otherwise the bit is appended to the next free high position, counting down
   from the most significant bit.

This results in all sheep packed at the front and all goats packed at the back
in mirrored order.

### Example

For a short 4-bit word `di = 4'b1010` and mask `ci = 4'b0101`, the sheep bits
(`di[2]` and `di[0]`) are packed to the low side while the goats fill in from
the high side:

```mermaid
flowchart LR
    di1["di[1]=1"] -- goat --> do3["do[3]=1"]
    di3["di[3]=1"] -- goat --> do2["do[2]=1"]
    di2["di[2]=0"] -- sheep --> do1["do[1]=0"]
    di0["di[0]=0"] -- sheep --> do0["do[0]=0"]
```

The output in this case is `do = 4'b1100`.

### Letter example

To see SAG in a more familiar setting, consider the string
`s t C A a T o g` where the capital letters are the sheep.  After processing,
all of the goats are collected first (in reverse order) followed by the sheep
in their original order:

```
g o a t s C A T
```

The mapping of characters can also be shown with the beta layout plugin for
Mermaid.  Eight input boxes remain aligned above eight output boxes so the
arrows clearly illustrate how each letter moves:

```mermaid
block-beta
  columns 8
  block:group1:8
    columns 8
    i7["s"]
    i6["t"]
    i5["C"]
    i4["A"]
    i3["a"]
    i2["T"]
    i1["o"]
    i0["g"]
  end

  classDef sheep fill:#a66
  class i0 sheep

  block:group2:8
    columns 8
    o7["g"]
    o6["o"]
    o5["a"]
    o4["t"]
    o3["s"]
    o2["C"]
    o1["A"]
    o0["T"]
  end
  i7-->o3
  i6-->o4
  i5-->o2
  i4-->o1
  i3-->o5
  i2-->o0
  i1-->o6
  i0-->o7
```

### Hardware Pipeline

The Verilog implementation is organized as three identical stages. Each stage
contains a control unit that computes swap signals followed by a data unit that
applies those swaps.

```mermaid
flowchart LR
    di --> DU1
    ci --> CU1
    CU1 --> DU1
    DU1 --> CU2
    CU2 --> DU2
    DU2 --> CU3
    CU3 --> DU3
    DU3 --> do
    subgraph Stage1
        CU1
        DU1
    end
    subgraph Stage2
        CU2
        DU2
    end
    subgraph Stage3
        CU3
        DU3
    end
```

Because the design is fixed at 8 bits, exactly three stages are required.

### Running the Testbench

A simple testbench in `top.v` exhaustively tests all `ci` and `di`
combinations. Use the provided script to run it:

```bash
./run.sh
```

The simulation produces verbose output and finishes with `ALL TESTS PASSED` when
no mismatches are found.
