module utils;

import map;
import emu;
import std.traits;
import std.regex;
import std.range;
import std.conv;
import std.string;

// W == 16-bit
// DW == 32-bit
// QW == 64-bit
// VX = 128-bit (SSE)
// VY = 256-bit (SSE)
// VZ = 512-bit (SSE)
/*public enum Registers
{
    // Native registers
    // 8-bit
    a,
    b,
    c,
    d,
    e,
    f,
    h,
    l,
    i,
    r,
    ixl,
    ixh,
    iyl,
    iyh,
    // 16-bit
    af,
    bc,
    de,
    hl,
    pc,
    sp,
    ix,
    iy,

    // Extended registers
    // 16-bit (general)
    wa,
    wb,
    wc,
    wd,
    we,
    wf,
    wh,
    wl,
    // 32-bit (general)
    dwa,
    dwb,
    dwc,
    dwd,
    dwe,
    dwf,
    dwh,
    dwl,
    // 64-bit (general)
    qwa,
    qwb,
    qwc,
    qwd,
    qwe,
    qwf,
    qwh,
    qwl,
    // 8-bit (ext-ext)
    b8,
    b9,
    b10,
    b11,
    b12,
    b13,
    b14,
    b15,
    // 16-bit (ext-ext)
    w8,
    w9,
    w10,
    w11,
    w12,
    w13,
    w14,
    w15,
    // 32-bit (ext-ext)
    dw8,
    dw9,
    dw10,
    dw11,
    dw12,
    dw13,
    dw14,
    dw15,
    // 64-bit (ext-ext)
    qw8,
    qw9,
    qw10,
    qw11,
    qw12,
    qw13,
    qw14,
    qw15,
    // 128-bit (SSE)
    vx0,
    vx1,
    vx2,
    vx3,
    vx4,
    vx5,
    vx6,
    vx7,
    vx8,
    vx9,
    vx10,
    vx11,
    vx12,
    vx13,
    vx14,
    vx15,
    // 256-bit (SSE)
    vy0,
    vy1,
    vy2,
    vy3,
    vy4,
    vy5,
    vy6,
    vy7,
    vy8,
    vy9,
    vy10,
    vy11,
    vy12,
    vy13,
    vy14,
    vy15,
    // 512-bit (SSE)
    vz0,
    vz1,
    vz2,
    vz3,
    vz4,
    vz5,
    vz6,
    vz7,
    vz8,
    vz9,
    vz10,
    vz11,
    vz12,
    vz13,
    vz14,
    vz15
}*/

// These fields are only here so we can temporarily use it when parsing
private static ubyte[] _literals;
private static string _line;
    
public static string[] parseLiterals(string[] data, out ubyte[][] literals)
{
    const auto hex8 = ctRegex!(r"(?:\$[\da-fA-F]{1,2}\b)|(?:\b[\da-fA-F]{1,2}h)", "gm");
    const auto hex16 = ctRegex!(r"(?:\$[\da-fA-F]{3,7}\b)|(?:\b[\da-fA-F]{3,7}h)", "gm");
    const auto hex32p = ctRegex!(r"(?:\$[\da-fA-F]{8,}\b)|(?:\b[\da-fA-F]{8,}h)", "gm");
    const auto dec8 = ctRegex!(r"(?<=\s)\d{1,3}d{0,1}\b", "gm");
    const auto dec16 = ctRegex!(r"(?<=\s)\d{4,5}d{0,1}\b", "gm");
    const auto dec32p = ctRegex!(r"(?<=\s)\d{5,}d{0,1}\b", "gm");
    const auto oct8 = ctRegex!(r"(?:@[0-7]{1,3}\b)|(?:\b[2-7]{1,3}o)", "gm");
    const auto oct16 = ctRegex!(r"(?:@[0-7]{4,9}\b)|(?:\b[2-7]{4,9}o)", "gm");
    const auto oct32p = ctRegex!(r"(?:@[0-7]{10,}\b)|(?:\b[2-7]{10,}o)", "gm");
    const auto bin8 = ctRegex!(r"(?:%[0-1]{1,8}\b)|(?:\b[0-1]{1,8}b)", "gm");
    const auto bin16 = ctRegex!(r"(?:%[0-1]{9,16}\b)|(?:\b[0-1]{9,16}b)", "gm");
    const auto bin32p = ctRegex!(r"(?:%[0-1]{17,}\b)|(?:\b[0-1]{17,}b)", "gm");
    const auto achar = ctRegex!(r"'.'", "gm");
    const auto astr = ctRegex!("\".*\"", "gm");
    string[] tdata = data.dup;

    foreach (ref string line; tdata)
    {
        _line = line;

        // n == 8-bit literal
        // Chars are 8-bit
        line = replaceAll!(literalOp!(ubyte, 16, "n"))(line, hex8);
        line = replaceAll!(literalOp!(ubyte, 10, "n"))(line, dec8);
        line = replaceAll!(literalOp!(ubyte, 8, "n"))(line, oct8);
        line = replaceAll!(literalOp!(ubyte, 2, "n"))(line, bin8);
        line = replaceAll!(literalOp!(char, 10, "n"))(line, achar);

        // nn == 16-bit literal
        line = replaceAll!(literalOp!(ushort, 16, "nn"))(line, hex16);
        line = replaceAll!(literalOp!(ushort, 10, "nn"))(line, dec16);
        line = replaceAll!(literalOp!(ushort, 8, "nn"))(line, oct16);
        line = replaceAll!(literalOp!(ushort, 2, "nn"))(line, bin16);

        // xnn == 32-bit or higher literal
        // str == String
        // These are not default Z80 features!
        line = replaceAll!(literalOp!(uint, 16, "xnn"))(line, hex32p);
        line = replaceAll!(literalOp!(uint, 10, "xnn"))(line, dec32p);
        line = replaceAll!(literalOp!(uint, 8, "xnn"))(line, oct32p);
        line = replaceAll!(literalOp!(uint, 2, "xnn"))(line, bin32p);
        line = replaceAll!(literalOp!(string, 2, "str"))(line, astr);

        literals ~= _literals;
        _literals = null;
    }

    return tdata;
}
    
private static string literalOp(T, int BASE, string TOKEN)(Captures!string m)
{
    // in8b == inbuilt 8-bit
    const auto in8b = ctRegex!(r"\w+ (?:\d,|\dh,)", "gm");
    // This is so things like set 4, b don't get matched
    // If we don't have this set 4, b gets converted to set n, b
    if (_line != null && (match(_line, in8b) || _line.startsWith("rst")))
    {
        _line = null;
        return m.hit;
    }
    string hit = m.hit;

    static if (is(T == char))
    {
        _literals ~= hit[1].to!ubyte;
    }
    else static if (is(T == string))
    {
        foreach (i; 1..(hit.length - 1))
        _literals ~= hit[i].to!ubyte;
    }
    else static if (is(T == ubyte))
    {
        // Just in case there's any prefix
        hit = hit.strip("$@%");
        _literals ~= parse!T(hit, BASE);
    }
    else static if (is(T == ushort))
    {
        hit = hit.strip("$@%");
        auto value = parse!T(hit, BASE);
        // Get individual bytes (2)
        _literals ~= [
            cast(ubyte)((value >> 8) & 0xFF), 
            cast(ubyte)(value & 0xFF)
        ];
    }
    else static if(is(T == uint))
    {
        hit = hit.strip("$@%");
        auto value = parse!T(hit, BASE);
        // Get individual bytes (4)
        _literals ~= [
            cast(ubyte)((value >> 24) & 0xFF),
            cast(ubyte)((value >> 16) & 0xFF),
            cast(ubyte)((value >> 8) & 0xFF), 
            cast(ubyte)(value & 0xFF)
        ];
    }
    
    return TOKEN;
} 

public static string findClosestMatch(string input, string[][] candidates...) 
{
    import std.algorithm;

    long minDistance = int.max;
    string closestMatch;

    foreach (candidate; candidates) 
    {
        foreach (map; candidate) 
        {
            long distance = input.levenshteinDistance(map);
            if (distance < minDistance) 
            {
                minDistance = distance;
                closestMatch = map;
            }
        }
    }

    return closestMatch;
}

public static int getLengthOfMnemonic(string mnemonic)
{
    mnemonic = mnemonic.replace("nn", "1000").replace('n', "100");
    return cast(int)z80!().assemble(mnemonic).length;
}

public static bool isRegister(string value)
{
    //return hasMember!(Registers, value);
    return value in registerMap;
}

// Global mapping between Z80 registers/memory and x86 registers or Z80 pseudo-registers
//
// If preserveBits is set to true then all literals will be mapped to their appropriate size
// using as many registers or as much memory as needed to fully represent them.
// This is advised to be set to false if memory is an issue or registers need to always be
// preserved throughout execution.
// Registers will only be preserved by restoring at the end of execution if they would not 
// otherwise be overwritten if mapping had not been set to preserveBits.
//
// If preserveBits is set to false then all literals will be treated as 8/16 bits
public static string mapRegisterZ80(string register)
{
    switch ()
}