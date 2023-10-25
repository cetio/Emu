module map;

/*// Global mapping between Z80 registers/memory and x86 registers or Z80 pseudo-registers
//
// If preserveBits is set to true then all literals will be mapped to their appropriate size
// using as many registers or as much memory as needed to fully represent them.
// This is advised to be set to false if memory is an issue or registers need to always be
// preserved throughout execution.
// Registers will only be preserved by restoring at the end of execution if they would not 
// otherwise be overwritten if mapping had not been set to preserveBits.
//
// If preserveBits is set to false then all literals will be treated as 8/16 bits
public template map(string register, bool preserveBits = true)
{
    public string getOrCreateMap()
    {

    }

    public const string map = getOrCreateMap();
}*/

// W == 16-bit
// DW == 32-bit
// QW == 64-bit
// VX = 128-bit (SSE)
// VY = 256-bit (SSE)
// VZ = 512-bit (SSE)
public enum Registers
{
    // Native registers
    // 8-bit
    A,
    B,
    C,
    D,
    E,
    F,
    H,
    L,
    I,
    R,
    IXL,
    IXH,
    IYL,
    IYH,
    // 16-bit
    AF,
    BC,
    DE,
    HL,
    PC,
    SP,
    IX,
    IY,

    // Extended registers
    // 16-bit (general)
    WA,
    WB,
    WC,
    WD,
    WE,
    WF,
    WH,
    WL,
    // 32-bit (general)
    DWA,
    DWB,
    DWC,
    DWD,
    DWE,
    DWF,
    DWH,
    DWL,
    // 64-bit (general)
    QWA,
    QWB,
    QWC,
    QWD,
    QWE,
    QWF,
    QWH,
    QWL,
    // 8-bit (ext-ext)
    B8,
    B9,
    B10,
    B11,
    B12,
    B13,
    B14,
    B15,
    // 16-bit (ext-ext)
    W8,
    W9,
    W10,
    W11,
    W12,
    W13,
    W14,
    W15,
    // 32-bit (ext-ext)
    DW8,
    DW9,
    DW10,
    DW11,
    DW12,
    DW13,
    DW14,
    DW15,
    // 64-bit (ext-ext)
    QW8,
    QW9,
    QW10,
    QW11,
    QW12,
    QW13,
    QW14,
    QW15,
    // 128-bit (SSE)
    VX0,
    VX1,
    VX2,
    VX3,
    VX4,
    VX5,
    VX6,
    VX7,
    VX8,
    VX9,
    VX10,
    VX11,
    VX12,
    VX13,
    VX14,
    VX15,
    // 256-bit (SSE)
    VY0,
    VY1,
    VY2,
    VY3,
    VY4,
    VY5,
    VY6,
    VY7,
    VY8,
    VY9,
    VY10,
    VY11,
    VY12,
    VY13,
    VY14,
    VY15,
    // 512-bit (SSE)
    VZ0,
    VZ1,
    VZ2,
    VZ3,
    VZ4,
    VZ5,
    VZ6,
    VZ7,
    VZ8,
    VZ9,
    VZ10,
    VZ11,
    VZ12,
    VZ13,
    VZ14,
    VZ15
}