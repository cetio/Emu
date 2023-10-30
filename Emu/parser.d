module parser;

// These fields are only here so we can temporarily use it when parsing
private static ubyte[] _data;
private static string _line;

// z80 literals
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

// x86 literals
// not implemented

// Not done
public static string parse!(alias func, bool x86LiteralFormat = true)(string[] lines, out ubyte[][] data)
{
    string[] tlines = lines.dup;

    foreach (ref string line; tlines)
    {
        _line = line;

        // n == 8-bit literal
        // Chars are 8-bit
        line = replaceAll!(literalOp!(ubyte, 16, "imm8"))(line, hex8);
        line = replaceAll!(literalOp!(ubyte, 10, "imm8"))(line, dec8);
        line = replaceAll!(literalOp!(ubyte, 8, "imm8"))(line, oct8);
        line = replaceAll!(literalOp!(ubyte, 2, "imm8"))(line, bin8);
        line = replaceAll!(literalOp!(char, 10, "imm8"))(line, achar);

        // nn == 16-bit literal
        line = replaceAll!(literalOp!(ushort, 16, "imm16"))(line, hex16);
        line = replaceAll!(literalOp!(ushort, 10, "imm16"))(line, dec16);
        line = replaceAll!(literalOp!(ushort, 8, "imm16"))(line, oct16);
        line = replaceAll!(literalOp!(ushort, 2, "imm16"))(line, bin16);

        // xnn == 32-bit or higher literal
        // str == String
        // These are not default Z80 features!
        line = replaceAll!(literalOp!(uint, 16, "imm32p"))(line, hex32p);
        line = replaceAll!(literalOp!(uint, 10, "imm32p"))(line, dec32p);
        line = replaceAll!(literalOp!(uint, 8, "imm32p"))(line, oct32p);
        line = replaceAll!(literalOp!(uint, 2, "imm32p"))(line, bin32p);
        line = replaceAll!(literalOp!(string, 2, "str"))(line, astr);

        literals ~= _literals;
        _literals = null;
    }

    return tlines;
}

public static bool normalMixin!(string repl)(ref string mnemonic, ref string[] literals)
{
    if (mnemonic != repl)
        return false;

    mnemonic = mixin(repl~"(literals)");
    return true;
}