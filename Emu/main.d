module main;

import std.stdio;
import std.conv;
import emu;
import std.typecons : Flag, Yes, No;

int main()
{
    writeln(z80!().assemble(
    "add a, $10
ld c, a"));
    writeln(z80!().disassemble(z80!().assemble(
    "add a, $10
ld c, a")));
    readln();
    return 0;
}
