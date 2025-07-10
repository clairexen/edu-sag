## Educational 8-Bit Sheep-And-Goats (SAG) Verilog Reference IP

The purpose of this design is to demonstrade the inner workings of an efficient SAG hardware IP.

Everything is hardcoded to 8-Bits (and thus 3-Stages) to keep the code as simple as possible.


### Functional Description of the Sheep-and-Goats (SAG) Operation

The Sheep-and-Goats (SAG) operation partitions and reorders the bits of a data
word `di` using a control mask `ci`. It outputs a new word where:

Bits of `di` selected by `ci` (i.e., where `ci[i] = 1`, the sheep) are packed
into the lower bits of the result, preserving their order.

The remaining bits of `di` (i.e., where `ci[i] = 0`, the goats) are packed into
the higher bits of the result in reversed order.

This creates a word where `di` is filtered and reorganized based on `ci`, with
a forward-ordered prefix of selected bits and a mirrored suffix of the rest.

```mermaid
%% di=[s t C A a T o g] ci=[0 0 1 1 0 1 0 0]
%%    [s t A C a T g o]    [0 0 1 1 0 1 0 0]
%% d1=[s A a g|t C T o] c1=[0 1 0 0|0 1 1 0]
%%    [s A g a|C t o T]    [0 1 0 0|1 0 0 1]
%% d2=[s g|C o|A a|t T] c2=[0 0|1 0|1 0|0 1]
%%    [g s|o C|a A|t T]    [0 0|0 1|0 1|0 1]
%% do=[g o a t s C A T] co=[0 0 0 0 0 1 1 1]
block-beta
  columns 9
  classDef sheep fill:#faa
  classDef label fill:#fff,stroke-width:0px
  classDef action fill:#ffa
  classDef grp fill:#888
  block:A_7:8
    columns 8
    A7["s"]
    A6["t"]
    A5["C"]
    A4["A"]
    A3["a"]
    A2["T"]
    A1["o"]
    A0["g"]
  end
  class A_7 grp
 L1["di"] space:8 S1<["1st Stage"]>(left)
  block:B:8
    columns 8
    B7["s"]
    B6["t"]
    B5["A"]
    B4["C"]
    B3["a"]
    B2["T"]
    B1["g"]
    B0["o"]
  end
space:9 U1<["Unshuffle"]>(left)
  block:C_7:4
    columns 4
    C7["s"]
    C6["A"]
    C5["a"]
    C4["g"]
  end
  class C_7 grp
  block:C_3:4
    columns 4
    C3["t"]
    C2["C"]
    C1["T"]
    C0["o"]
  end
  class C_3 grp
space:9 S2<["2nd Stage"]>(left)
  block:D:8
    columns 8
    D7["s"]
    D6["A"]
    D5["g"]
    D4["a"]
    D3["C"]
    D2["t"]
    D1["o"]
    D0["T"]
  end
space:9 U2<["Unshuffle"]>(left)
  block:E_7:2
    columns 2
    E7["s"]
    E6["g"]
  end
  class E_7 grp
  block:E_5:2
    columns 2
    E5["C"]
    E4["o"]
  end
  class E_5 grp
  block:E_3:2
    columns 2
    E3["A"]
    E2["a"]
  end
  class E_3 grp
  block:E_1:2
    columns 2
    E1["t"]
    E0["T"]
  end
  class E_1 grp
space:9 S3<["3rd Stage"]>(left)
  block:F:8
    columns 8
    F7["g"]
    F6["s"]
    F5["o"]
    F4["C"]
    F3["a"]
    F2["A"]
    F1["t"]
    F0["T"]
  end
space:9 U3<["Unshuffle"]>(left)
  block:G_7:1
    columns 1
    G7["g"]
  end
  class G_7 grp
  block:G_6:1
    columns 1
    G6["o"]
  end
  class G_6 grp
  block:G_5:1
    columns 1
    G5["a"]
  end
  class G_5 grp
  block:G_4:1
    columns 1
    G4["t"]
  end
  class G_4 grp
  block:G_3:1
    columns 1
    G3["s"]
  end
  class G_3 grp
  block:G_2:1
    columns 1
    G2["C"]
  end
  class G_2 grp
  block:G_1:1
    columns 1
    G1["A"]
  end
  class G_1 grp
  block:G_0:1
    columns 1
    G0["T"]
  end
  class G_0 grp
 L2["do"]
class L1 label
class L2 label
class S1 action
class U1 action
class S2 action
class U2 action
class S3 action
class U3 action
class A2 sheep
class A4 sheep
class A5 sheep
class B2 sheep
class B4 sheep
class B5 sheep
class C1 sheep
class C2 sheep
class C6 sheep
class D0 sheep
class D3 sheep
class D6 sheep
class E0 sheep
class E3 sheep
class E5 sheep
class F0 sheep
class F2 sheep
class F4 sheep
class G0 sheep
class G1 sheep
class G2 sheep
A0 --> B1
A1 --> B0
A2 --> B2
A3 --> B3
A4 --> B5
A5 --> B4
A6 --> B6
A7 --> B7
C0 --> D1
C1 --> D0
C2 --> D3
C3 --> D2
C4 --> D5
C5 --> D4
C6 --> D6
C7 --> D7
E0 --> F0
E1 --> F1
E2 --> F3
E3 --> F2
E4 --> F5
E5 --> F4
E6 --> F7
E7 --> F6
B0 --> C0
B2 --> C1
B4 --> C2
B6 --> C3
B1 --> C4
B3 --> C5
B5 --> C6
B7 --> C7
D0 --> E0
D2 --> E1
D4 --> E2
D6 --> E3
D1 --> E4
D3 --> E5
D5 --> E6
D7 --> E7
F0 --> G0
F2 --> G1
F4 --> G2
F6 --> G3
F1 --> G4
F3 --> G5
F5 --> G6
F7 --> G7
```
