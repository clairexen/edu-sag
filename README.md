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

In the following examples, upper case letters are the sheep (`ci[i] = 1`) and
lower case letters are the goats (`ci[i] = 0`).

```mermaid
%% di=[s t C A a T o g] ci=[0 0 1 1 0 1 0 0]
%% do=[g o a t s C A T] co=[0 0 0 0 0 1 1 1]

block-beta
  columns 9
  classDef sheep fill:#faa
  classDef label fill:#fff,stroke-width:0px
  classDef action fill:#ffa
  classDef grp fill:#888
  block:A:8
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
  L1["di"]
  space:9
  block:G:8
    columns 8
    G7["g"]
    G6["o"]
    G5["a"]
    G4["t"]
    G3["s"]
    G2["C"]
    G1["A"]
    G0["T"]
  end
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
class G0 sheep
class G1 sheep
class G2 sheep
A7 --> G3
A6 --> G4
A5 --> G2
A4 --> G1
A3 --> G5
A2 --> G0
A1 --> G6
A0 --> G7
```
```mermaid
%% di=[S g H o E d E P] ci=[1 0 1 0 1 0 1 1]
%% do=[d o g S H E E P] co=[0 0 0 1 1 1 1 1]

block-beta
  columns 9
  classDef sheep fill:#faa
  classDef label fill:#fff,stroke-width:0px
  classDef action fill:#ffa
  classDef grp fill:#888
  block:A:8
    columns 8
    A7["S"]
    A6["g"]
    A5["H"]
    A4["o"]
    A3["E"]
    A2["d"]
    A1["E"]
    A0["P"]
  end
  L1["di"]
  space:9
  block:G:8
    columns 8
    G7["d"]
    G6["o"]
    G5["g"]
    G4["S"]
    G3["H"]
    G2["E"]
    G1["E"]
    G0["P"]
  end
  L2["do"]
class L1 label
class L2 label
class S1 action
class U1 action
class S2 action
class U2 action
class S3 action
class U3 action
class A0 sheep
class A1 sheep
class A3 sheep
class A5 sheep
class A7 sheep
class G0 sheep
class G1 sheep
class G2 sheep
class G3 sheep
class G4 sheep
A7 --> G4
A6 --> G5
A5 --> G3
A4 --> G6
A3 --> G2
A2 --> G7
A1 --> G1
A0 --> G0
```


### Principle of Operations

The method demonstrated in [sag.v](sag.v) is a divide and conquer-type approach to the problem, that is enabled by the following important property of the Sheep-And-Goats (SAG) operation with bit-reflection for the goats:

> **The most significant bit of the control word is not used.**

This is because no matter if the MSB bit is a sheep or goat, it's always going to end up between all the (other) goats and all the (other) sheep.

**Therefore we are free to pick whatever MSB bit-value in the control word is required, so that there's an even number of sheep (and thus, also and even number of goats).**

Because of this, because we can make it so that there's always an even number of sheep and goats, we get the following usefull property:

**Going through the control word from right to left, i.e. from LSB to MSB bits, and deciding for each pair of bits if it should be swapped based only of the fact if we have ecountered an even or odd number of set bits so far, is EQUIVALENT IN THE OVERLAPPING CASES to going from left to right and counting the zero bits.**

With *EQUIVALENT IN THE OVERLAPPING CASES* we refer to the fact that the "right-to-left" approach produces no constraints on a pair of zero bits, and the "left-to-right" approach produces no constraints on a pair of one bits.

However, there's no need to actually evaluate the control words in both directions in the actual core. Instead we only calculate the "right-to-left" XOR prefix-sum, and also use it to correctly calculate what to do with a pair of zero bits, as demonstrated in the core.

We do not need to explicitly set the "right" MSB bit of the control value in the core. Instead, we simply discard the MSB control bit and rely only on the XOR prefix sum of the other N-1 control bits.

Thus the method performs the following steps

1. Figure out for each pair of bits, if they should be swapped, based on the XOR prefix sum.

2. Swap both, the N/2 pairs of data bits, and the N/2 pairs of control bits, accordingly to the N/2 control signals produced by step 1.

3. "Unshuffle" both the control and the data bits. This means to place all the bits at even positions compressed to the right in the lower half of the output, and to place all the bits in odd positions into the higher half of the output. It is the inverse operation of the *perfect outer shuffle* of the bits in a word.

4. Divide and Conquer: Apply steps 1.-3. to the new data and control words, but instead of a XOR prefix sum over all bits, we now perform 2 XOR prefix sums, each covering a span of N/2 bits. And in the next iteration it's 4 XOR prefix sums, each covering N/4 bits, and so forth.

5. Stop after log2(N) iterations of steps 1.-3.

In the first iteration we put each data (and control) bit in the correct (even/odd) half of the word.

The unshuffle operations switches the roles of the bit-index-bits. I.e. for 8-bit words the unshuffle operation corresponds to a one-bit rotate right shift of the 3-bit bit-indices.) Note that an unshuffle opration does not require any active hardware elements, it's just crossing wires.

After the unshuffle we treat the even and odd halfs as completely seperate (upper and lower) N/2 half-words, and then effectively call the algorithm recursively on the two halfs, quartes, etc, until we have passed each bit-address-bit throught the zero position and have re-created the original bit-address-bit-ordering after log2(N) right-shifts of the log2(N) bit-address-bits.

----

And here is a picture of the complete data-flow through the SAG IP for the two examples shown above: 

```mermaid
%% di=[s t C A a T o g] ci=[0 0 1 1 0 1 0 0]
%%    [s t A C a T g o]    [0 0 1 1 0 1 0 0]
%% d1=[s A a g|t C T o] c1=[0 1 0 0|0 1 1 0]
%%    [s A g a C t o T]    [0 1 0 0 1 0 0 1]
%% d2=[s g|C o|A a|t T] c2=[0 0|1 0|1 0|0 1]
%%    [g s o C a A t T]    [0 0 0 1 0 1 0 1]
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

----

```mermaid
%% di=[S g H o E d E P] ci=[1 0 1 0 1 0 1 1]
%%    [g S H o d E E P]    [0 1 1 0 0 1 1 1]
%% d1=[g H d E|S o E P] c1=[0 1 0 1|1 0 1 1]
%%    [H g d E o S E P]    [1 0 0 1 0 1 1 1]
%% d2=[H d|o E|g E|S P] c2=[1 0|0 1|0 1|1 1]
%%    [d H o E g E S P]    [0 1 0 1 0 1 1 1]
%% do=[d o g S H E E P] co=[0 0 0 1 1 1 1 1]

block-beta
  columns 9
  classDef sheep fill:#faa
  classDef label fill:#fff,stroke-width:0px
  classDef action fill:#ffa
  classDef grp fill:#888
  block:A_7:8
    columns 8
    A7["S"]
    A6["g"]
    A5["H"]
    A4["o"]
    A3["E"]
    A2["d"]
    A1["E"]
    A0["P"]
  end
  class A_7 grp
 L1["di"] space:8 S1<["1st Stage"]>(left)
  block:B:8
    columns 8
    B7["g"]
    B6["S"]
    B5["H"]
    B4["o"]
    B3["d"]
    B2["E"]
    B1["E"]
    B0["P"]
  end
space:9 U1<["Unshuffle"]>(left)
  block:C_7:4
    columns 4
    C7["g"]
    C6["H"]
    C5["d"]
    C4["E"]
  end
  class C_7 grp
  block:C_3:4
    columns 4
    C3["S"]
    C2["o"]
    C1["E"]
    C0["P"]
  end
  class C_3 grp
space:9 S2<["2nd Stage"]>(left)
  block:D:8
    columns 8
    D7["H"]
    D6["g"]
    D5["d"]
    D4["E"]
    D3["o"]
    D2["S"]
    D1["E"]
    D0["P"]
  end
space:9 U2<["Unshuffle"]>(left)
  block:E_7:2
    columns 2
    E7["H"]
    E6["d"]
  end
  class E_7 grp
  block:E_5:2
    columns 2
    E5["o"]
    E4["E"]
  end
  class E_5 grp
  block:E_3:2
    columns 2
    E3["g"]
    E2["E"]
  end
  class E_3 grp
  block:E_1:2
    columns 2
    E1["S"]
    E0["P"]
  end
  class E_1 grp
space:9 S3<["3rd Stage"]>(left)
  block:F:8
    columns 8
    F7["d"]
    F6["H"]
    F5["o"]
    F4["E"]
    F3["g"]
    F2["E"]
    F1["S"]
    F0["P"]
  end
space:9 U3<["Unshuffle"]>(left)
  block:G_7:1
    columns 1
    G7["d"]
  end
  class G_7 grp
  block:G_6:1
    columns 1
    G6["o"]
  end
  class G_6 grp
  block:G_5:1
    columns 1
    G5["g"]
  end
  class G_5 grp
  block:G_4:1
    columns 1
    G4["S"]
  end
  class G_4 grp
  block:G_3:1
    columns 1
    G3["H"]
  end
  class G_3 grp
  block:G_2:1
    columns 1
    G2["E"]
  end
  class G_2 grp
  block:G_1:1
    columns 1
    G1["E"]
  end
  class G_1 grp
  block:G_0:1
    columns 1
    G0["P"]
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
class A0 sheep
class A1 sheep
class A3 sheep
class A5 sheep
class A7 sheep
class B0 sheep
class B1 sheep
class B2 sheep
class B5 sheep
class B6 sheep
class C0 sheep
class C1 sheep
class C3 sheep
class C4 sheep
class C6 sheep
class D0 sheep
class D1 sheep
class D2 sheep
class D4 sheep
class D7 sheep
class E0 sheep
class E1 sheep
class E2 sheep
class E4 sheep
class E7 sheep
class F0 sheep
class F1 sheep
class F2 sheep
class F4 sheep
class F6 sheep
class G0 sheep
class G1 sheep
class G2 sheep
class G3 sheep
class G4 sheep
A0 --> B0
A1 --> B1
A2 --> B3
A3 --> B2
A4 --> B4
A5 --> B5
A6 --> B7
A7 --> B6
C0 --> D0
C1 --> D1
C2 --> D3
C3 --> D2
C4 --> D4
C5 --> D5
C6 --> D7
C7 --> D6
E0 --> F0
E1 --> F1
E2 --> F2
E3 --> F3
E4 --> F4
E5 --> F5
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
