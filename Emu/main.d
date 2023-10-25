module main;

import std.stdio;
import std.conv;
import emu;

int main()
{
    writeln(z80!().assemble("
                            add a, 4
                            bit 0, (ix + 10)
    "));
    writeln(z80!().disassemble(z80!().assemble("        
        add a, 4
        bit 0, (ix + 10)
    ")));
    readln();
    return 0;
}
