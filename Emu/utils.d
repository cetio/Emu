module utils;

import map;
import emu;
import std.traits;
import std.regex;
import std.range;
import std.conv;

public static class assemblers
{
    // These fields are only here so we can temporarily use it when parsing
    private static ubyte[] _literals;
    private static string _line;

    //return hasMember!(Registers, value);
    
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
        import std.string;

        // in8b == inbuilt 8-bit
        const auto in8b = ctRegex!(r"\w+ (?:\d,|\dh,)", "gm");
        // This is so things like set 4, b don't get matched
        // If we don't have this set 4, b gets converted to set n, b
        if (match(_line, in8b) || _line.startsWith("rst"))
            return m.hit;
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

    public static ulong getLengthOfMnemonic(string mnemonic)
    {
        mnemonic = mnemonic.replace("nn", "1000").replace('n', "100");
        return z80!().assemble(mnemonic).length;
    }
}