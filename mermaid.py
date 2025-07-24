#  Educational 8-Bit Sheep-And-Goats (SAG) Verilog Reference IP
#
#  Copyright (C) 2025  Claire Xenia Wolf <claire@clairexen.net>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

class sag:
    def __init__(self, subject):
        assert len(subject) == 8
        self.di = list(reversed(subject))
        self.ci = [x.isupper() for x in self.di]

        self.c1, self.b1 = self.sagCtrlUnit(self.ci, 0b00) # ctrl_1
        self.c2, self.b2 = self.sagCtrlUnit(self.c1, 0b10) # ctrl_2
        self.co, self.b3 = self.sagCtrlUnit(self.c2, 0b11) # ctrl_3

        self.d1 = self.sagDataUnit(self.di, self.b1) # data_1
        self.d2 = self.sagDataUnit(self.d1, self.b2) # data_2
        self.do = self.sagDataUnit(self.d2, self.b3) # data_3

    def sagCtrlUnit(self, ci, sel):
        x = list() # prefix xor-sum over ci, partially broken depending on sel
        x.append(ci[0])
        x.append(ci[1] != x[0])
        x.append(ci[2] != (False if sel&1 else x[1]))
        x.append(ci[3] != x[2])
        x.append(ci[4] != (False if sel&2 else x[3]))
        x.append(ci[5] != x[4])
        x.append(ci[6] != (False if sel&1 else x[5]))
        x.append(ci[7] != x[6]) # unused ;)

        # butterfly control signals
        b = list()
        b.append(not x[0])
        b.append(not x[2])
        b.append(not x[4])
        b.append(not x[6])

        co = self.sagDataUnit(ci, b) # ctrl_bfly
        return (co, b)

    def sagDataUnit(self, di, b):
        do_shuffled = list()
        do_shuffled += [di[1], di[0]] if b[0] else di[0:2]
        do_shuffled += [di[3], di[2]] if b[1] else di[2:4]
        do_shuffled += [di[5], di[4]] if b[2] else di[4:6]
        do_shuffled += [di[7], di[6]] if b[3] else di[6:8]
        do = self.sagUnshuffle(do_shuffled)
        return do

    def sagUnshuffle(self, di):
        even = [di[0], di[2], di[4], di[6]]
        odds = [di[1], di[3], di[5], di[7]]
        do = even + odds
        return do

def shuffle(a):
    return [a[0], a[4], a[1], a[5], a[2], a[6], a[3], a[7]]
    

import sys
args = sys.argv[1:]

summary_mode = False
verbose_mode = False
dump_mode = False
exec_str = None

while args and args[0] in tuple("-s -v -d -e".split()):
    if args[0] == "-s":
        summary_mode = True
    elif args[0] == "-v":
        verbose_mode = True
    elif args[0] == "-d":
        dump_mode = True
    elif args[0] == "-e":
        exec_str = args[1]
        args = args[1:]
    else:
        assert False
    args = args[1:]

if not args:
    args = ["stCAaTog", "SgHoEdEP"]

print()
for arg in args:
    d = sag(arg)

    def jrs(a):
        return " ".join(reversed(shuffle(a)))

    def jru(a):
        return " ".join(reversed(a))

    def st(s, n):
        def tag(i):
            nonlocal s
            s = s[:i] + "|" + s[i+1:]
        if n & 2: tag(3)
        if n & 1: tag(7)
        if n & 2: tag(11)
        return s

    if exec_str or dump_mode:
        print(f"# {''.join([str(x) for x in reversed(d.di)])}")

        # Agents: Use `-e python_code` to execute arbitrary code (with ++ => \n for
        # convenience) for inspecting the state of the sag object
        if exec_str:
            exec(exec_str.replace("++", "\n"))

        # Agents: Use `-d [subject strings(s)]` to simply dump the entire state of
        # the sag object in an easy-to-parse format
        if dump_mode:
            for k,v in d.__dict__.items():
                print(f"{k}: {' '.join([str(x) for x in reversed(v)])}")

        continue

    print("```mermaid")
    print(f"%% di=[{st(jru(d.di), 0)}] ci=[{st(jru(['1' if x else '0' for x in d.ci]), 0)}]")
    if verbose_mode:
        print(f"%%    [{st(jrs(d.d1), 0)}]    [{st(jrs(['1' if x else '0' for x in d.c1]), 0)}]")
        print(f"%% d1=[{st(jru(d.d1), 1)}] c1=[{st(jru(['1' if x else '0' for x in d.c1]), 1)}]")
        print(f"%%    [{st(jrs(d.d2), 0)}]    [{st(jrs(['1' if x else '0' for x in d.c2]), 0)}]")
        print(f"%% d2=[{st(jru(d.d2), 3)}] c2=[{st(jru(['1' if x else '0' for x in d.c2]), 3)}]")
        print(f"%%    [{st(jrs(d.do), 0)}]    [{st(jrs(['1' if x else '0' for x in d.co]), 0)}]")
    print(f"%% do=[{st(jru(d.do), 0)}] co=[{st(jru(['1' if x else '0' for x in d.co]), 0)}]")
    print()

    if summary_mode:
        continue

    A = d.di
    B = shuffle(d.d1)
    C = d.d1
    D = shuffle(d.d2)
    E = d.d2
    F = shuffle(d.do)
    G = d.do

    print(f"block-beta")
    print(f"  columns 9")
    print(f"  classDef sheep fill:#faa")
    print(f"  classDef label fill:#fff,stroke-width:0px")
    print(f"  classDef action fill:#ffa")
    print(f"  classDef grp fill:#888")

    def mm_block(letter, chars, sz = None):
        if sz is None:
            print(f"  block:{letter}:8")
            print(f"    columns 8")
            for i in range(7, -1, -1):
                print(f"    {letter}{i}[\"{chars[i]}\"]")
            print(f"  end")
        else:
            for i in range(7, -1, -sz):
                print(f"  block:{letter}_{i}:{sz}")
                print(f"    columns {sz}")
                for j in range(i, i-sz, -1):
                    print(f"    {letter}{j}[\"{chars[j]}\"]")
                print(f"  end")
                print(f"  class {letter}_{i} grp")

    if verbose_mode:
        mm_block("A", A, 8)
        print("  L1[\"di\"]")
        print("  space:8 S1<[\"1st Stage\"]>(left)")
        mm_block("B", B)
        print("  space:9 U1<[\"Unshuffle\"]>(left)")
        mm_block("C", C, 4)
        print("  space:9 S2<[\"2nd Stage\"]>(left)")
        mm_block("D", D)
        print("  space:9 U2<[\"Unshuffle\"]>(left)")
        mm_block("E", E, 2)
        print("  space:9 S3<[\"3rd Stage\"]>(left)")
        mm_block("F", F)
        print("  space:9 U3<[\"Unshuffle\"]>(left)")
        mm_block("G", G, 1)
    else:
        mm_block("A", A)
        print("  L1[\"di\"]")
        print("  space:9")
        mm_block("G", G)
    print("  L2[\"do\"]")

    print(f"class L1 label")
    print(f"class L2 label")

    for i in range(1, 4):
        print(f"class S{i} action")
        print(f"class U{i} action")

    def mm_sheep(letter, chars):
        for i in range (8):
            if chars[i].isupper():
                print(f"class {letter}{i} sheep")

    mm_sheep("A", A)
    if verbose_mode:
        mm_sheep("B", B)
        mm_sheep("C", C)
        mm_sheep("D", D)
        mm_sheep("E", E)
        mm_sheep("F", F)
    mm_sheep("G", G)

    if verbose_mode:
        def mm_swap(a, b, c):
            if c[0]:
                print(f"{a}0 --> {b}1")
                print(f"{a}1 --> {b}0")
            else:
                print(f"{a}0 --> {b}0")
                print(f"{a}1 --> {b}1")

            if c[1]:
                print(f"{a}2 --> {b}3")
                print(f"{a}3 --> {b}2")
            else:
                print(f"{a}2 --> {b}2")
                print(f"{a}3 --> {b}3")

            if c[2]:
                print(f"{a}4 --> {b}5")
                print(f"{a}5 --> {b}4")
            else:
                print(f"{a}4 --> {b}4")
                print(f"{a}5 --> {b}5")

            if c[3]:
                print(f"{a}6 --> {b}7")
                print(f"{a}7 --> {b}6")
            else:
                print(f"{a}6 --> {b}6")
                print(f"{a}7 --> {b}7")

        mm_swap("A", "B", d.b1)
        mm_swap("C", "D", d.b2)
        mm_swap("E", "F", d.b3)

        def mm_shuffle(a, b):
            print(f"{a}0 --> {b}0")
            print(f"{a}2 --> {b}1")
            print(f"{a}4 --> {b}2")
            print(f"{a}6 --> {b}3")
            print(f"{a}1 --> {b}4")
            print(f"{a}3 --> {b}5")
            print(f"{a}5 --> {b}6")
            print(f"{a}7 --> {b}7")

        mm_shuffle("B", "C")
        mm_shuffle("D", "E")
        mm_shuffle("F", "G")

    else: # not verbose_mode
        abc = "abcdefgh"
        arg2 = "".join(abc[i].upper() if arg[i].isupper() else abc[i] for i in range(8))
        do2 = "".join(reversed(sag(arg2).do))
        for i in range(8):
            print(f"A{7-i} --> G{7-do2.find(arg2[i])}")

    print("```")
