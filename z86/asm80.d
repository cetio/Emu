module asm80;

// This file is used for converting a token list of Z80 to bytes or x86

import std.typecons;
import std.range;

public enum OpCode
{
    nop, 
    ld, 
    inc, 
    dec, 
    add, 
    adc, 
    sub, 
    sbc, 
    and, 
    xor, 
    or, 
    cp, 
    rlca, 
    rrca, 
    rla, 
    rra, 
    daa, 
    cpl, 
    scf, 
    ccf, 
    halt, 
    di, 
    ei, 
    exx, 
    ex, 
    push, 
    pop, 
    jp, 
    jr, 
    call, 
    ret, 
    reti, 
    rst, 
    //in, 
    //out, 
    tst, 
    tstio, 
    otdr, 
    otir, 
    ind, 
    inir, 
    outd, 
    otir, 
    ldd, 
    ldi, 
    cpd, 
    cpi, 
    neg, 
    im, 
    mlt, 
    tsts, 
    set, 
    res, 
    bit, 
    rld, 
    rrd, 
    slp
}

// This map is used for fast lookups of opcode suffixes
ubyte[string] iids = {
    {"nop", 0x00}, 
    {"ld bc, nn", 0x01}, {"ld (bc), a", 0x02}, {"inc bc", 0x03}, {"inc b", 0x04}, {"dec b", 0x05}, 
    {"ld b, n", 0x06}, {"rlca", 0x07}, {"ex af, af'", 0x08}, {"add hl, bc", 0x09}, 
    {"ld a, (bc)", 0x0A}, {"dec bc", 0x0B}, {"inc c", 0x0C}, {"dec c", 0x0D}, 
    {"ld c, n", 0x0E}, {"rrca", 0x0F}, 

    {"djnz d", 0x10}, {"ld de, nn", 0x11}, {"ld (de), a", 0x12}, {"inc de", 0x13}, 
    {"inc d", 0x14}, {"dec d", 0x15}, {"ld d, n", 0x16}, {"rla", 0x17}, 
    {"jr d", 0x18}, {"add hl, de", 0x19}, {"ld a, (de)", 0x1A}, {"dec de", 0x1B}, 
    {"inc e", 0x1C}, {"dec e", 0x1D}, {"ld e, n", 0x1E}, {"rra", 0x1F}, 

    {"jr nz, d", 0x20}, {"ld hl, nn", 0x21}, {"ld (nn), hl", 0x22}, {"inc hl", 0x23}, 
    {"inc h", 0x24}, {"dec h", 0x25}, {"ld h, n", 0x26}, {"daa", 0x27}, {"jr z, d", 0x28}, 
    {"add hl, hl", 0x29}, {"ld hl, (nn)", 0x2A}, {"dec hl", 0x2B}, {"inc l", 0x2C}, 
    {"dec l", 0x2D}, {"ld l, n", 0x2E}, {"cpl", 0x2F}, 

    {"jr nc, d", 0x30}, {"ld sp, nn", 0x31}, {"ld (nn), a", 0x32}, {"inc sp", 0x33}, 
    {"inc (hl)", 0x34}, {"dec (hl)", 0x35}, {"ld (hl), n", 0x36}, {"scf", 0x37}, 
    {"jr c, d", 0x38}, {"add hl, sp", 0x39}, {"ld a, (nn)", 0x3A}, {"dec sp", 0x3B}, 
    {"inc a", 0x3C}, {"dec a", 0x3D}, {"ld a, n", 0x3E}, {"ccf", 0x3F}, 

    // 8-bit loads
    {"ld b, b", 0x40}, {"ld b, c", 0x41}, {"ld b, d", 0x42}, {"ld b, e", 0x43}, {"ld b, h", 0x44}, 
    {"ld b, l", 0x45}, {"ld b, (hl)", 0x46}, {"ld b, a", 0x47}, {"ld c, b", 0x48}, {"ld c, c", 0x49}, 
    {"ld c, d", 0x4A}, {"ld c, e", 0x4B}, {"ld c, h", 0x4C}, {"ld c, l", 0x4D}, {"ld c, (hl)", 0x4E}, 
    {"ld c, a", 0x4F}, 

    {"ld d, b", 0x50}, {"ld d, c", 0x51}, {"ld d, d", 0x52}, {"ld d, e", 0x53}, {"ld d, h", 0x54}, 
    {"ld d, l", 0x55}, {"ld d, (hl)", 0x56}, {"ld d, a", 0x57}, {"ld e, b", 0x58}, {"ld e, c", 0x59}, 
    {"ld e, d", 0x5A}, {"ld e, e", 0x5B}, {"ld e, h", 0x5C}, {"ld e, l", 0x5D}, {"ld e, (hl)", 0x5E}, 
    {"ld e, a", 0x5F}, 

    {"ld h, b", 0x60}, {"ld h, c", 0x61}, {"ld h, d", 0x62}, {"ld h, e", 0x63}, {"ld h, h", 0x64}, 
    {"ld h, l", 0x65}, {"ld h, (hl)", 0x66}, {"ld h, a", 0x67}, {"ld l, b", 0x68}, {"ld l, c", 0x69}, 
    {"ld l, d", 0x6A}, {"ld l, e", 0x6B}, {"ld l, h", 0x6C}, {"ld l, l", 0x6D}, {"ld l, (hl)", 0x6E}, 
    {"ld l, a", 0x6F}, 

    {"ld (hl), b", 0x70}, {"ld (hl), c", 0x71}, {"ld (hl), d", 0x72}, {"ld (hl), e", 0x73}, 
    {"ld (hl), h", 0x74}, {"ld (hl), l", 0x75}, {"halt", 0x76}, {"ld (hl), a", 0x77}, 
    {"ld a, b", 0x78}, {"ld a, c", 0x79}, {"ld a, d", 0x7A}, {"ld a, e", 0x7B}, {"ld a, h", 0x7C}, 
    {"ld a, l", 0x7D}, {"ld a, (hl)", 0x7E}, {"ld a, a", 0x7F}, 

    // 8-bit ALU
    {"add a, b", 0x80}, {"add a, c", 0x81}, {"add a, d", 0x82}, {"add a, e", 0x83}, {"add a, h", 0x84}, 
    {"add a, l", 0x85}, {"add a, (hl)", 0x86}, {"add a, a", 0x87}, {"adc a, b", 0x88}, {"adc a, c", 0x89}, 
    {"adc a, d", 0x8A}, {"adc a, e", 0x8B}, {"adc a, h", 0x8C}, {"adc a, l", 0x8D}, {"adc a, (hl)", 0x8E}, 
    {"adc a, a", 0x8F}, 

    {"sub b", 0x90}, {"sub c", 0x91}, {"sub d", 0x92}, {"sub e", 0x93}, {"sub h", 0x94}, 
    {"sub l", 0x95}, {"sub (hl)", 0x96}, {"sub a", 0x97}, {"sbc a, b", 0x98}, {"sbc a, c", 0x99}, 
    {"sbc a, d", 0x9A}, {"sbc a, e", 0x9B}, {"sbc a, h", 0x9C}, {"sbc a, l", 0x9D}, 
    {"sbc a, (hl)", 0x9E}, {"sbc a, a", 0x9F}, 

    {"and b", 0xA0}, {"and c", 0xA1}, {"and d", 0xA2}, {"and e", 0xA3}, {"and h", 0xA4}, 
    {"and l", 0xA5}, {"and (hl)", 0xA6}, {"and a", 0xA7}, {"xor b", 0xA8}, {"xor c", 0xA9}, 
    {"xor d", 0xAA}, {"xor e", 0xAB}, {"xor h", 0xAC}, {"xor l", 0xAD}, {"xor (hl)", 0xAE}, 
    {"xor a", 0xAF}, 

    {"or b", 0xB0}, {"or c", 0xB1}, {"or d", 0xB2}, {"or e", 0xB3}, {"or h", 0xB4}, 
    {"or l", 0xB5}, {"or (hl)", 0xB6}, {"or a", 0xB7}, {"cp b", 0xB8}, {"cp c", 0xB9}, 
    {"cp d", 0xBA}, {"cp e", 0xBB}, {"cp h", 0xBC}, {"cp l", 0xBD}, {"cp (hl)", 0xBE}, 
    {"cp a", 0xBF}, 

    // 16-bit arithmetic
    {"ret nz", 0xC0}, {"pop bc", 0xC1}, {"jp nz, nn", 0xC2}, {"jp nn", 0xC3}, {"call nz, nn", 0xC4}, 
    {"push bc", 0xC5}, {"add a, n", 0xC6}, {"rst 00h", 0xC7}, {"ret z", 0xC8}, {"ret", 0xC9}, 
    {"jp z, nn", 0xCA}, {"cb", 0xCB}, {"call z, nn", 0xCC}, {"call nn", 0xCD}, {"adc a, n", 0xCE}, 
    {"rst 08h", 0xCF}, 

    {"ret nc", 0xD0}, {"pop de", 0xD1}, {"jp nc, nn", 0xD2}, {"out (n), a", 0xD3}, 
    {"call nc, nn", 0xD4}, {"push de", 0xD5}, {"sub n", 0xD6}, {"rst 10h", 0xD7}, 
    {"ret c", 0xD8}, {"exx", 0xD9}, {"jp c, nn", 0xDA}, {"in a, (n)", 0xDB}, {"call c, nn", 0xDC}, 
    {"dd", 0xDD}, {"sbc a, n", 0xDE}, {"rst 18h", 0xDF}, 

    {"ret po", 0xE0}, {"pop hl", 0xE1}, {"jp po, nn", 0xE2}, {"ex (sp), hl", 0xE3}, 
    {"call po, nn", 0xE4}, {"push hl", 0xE5}, {"and n", 0xE6}, {"rst 20h", 0xE7}, 
    {"ret pe", 0xE8}, {"jp (hl)", 0xE9}, {"jp pe, nn", 0xEA}, {"ex de, hl", 0xEB}, 
    {"call pe, nn", 0xEC}, {"ed", 0xED}, {"xor n", 0xEE}, {"rst 28h", 0xEF}, 

    {"ret p", 0xF0}, {"pop af", 0xF1}, {"jp p, nn", 0xF2}, {"di", 0xF3}, {"call p, nn", 0xF4}, 
    {"push af", 0xF5}, {"or n", 0xF6}, {"rst 30h", 0xF7}, {"ret m", 0xF8}, {"ld sp, hl", 0xF9}, 
    {"jp m, nn", 0xFA}, {"ei", 0xFB}, {"call m, nn", 0xFC}, {"fd", 0xFD}, {"cp n", 0xFE}, 
    {"rst 38h", 0xFF}, 

    // Bit instructions (CB)
    {"rlc b", 0x00}, {"rlc c", 0x01}, {"rlc d", 0x02}, {"rlc e", 0x03}, {"rlc h", 0x04}, 
    {"rlc l", 0x05}, {"rlc (hl)", 0x06}, {"rlc a", 0x07}, {"rrc b", 0x08}, {"rrc c", 0x09}, 
    {"rrc d", 0x0A}, {"rrc e", 0x0B}, {"rrc h", 0x0C}, {"rrc l", 0x0D}, {"rrc (hl)", 0x0E}, 
    {"rrc a", 0x0F}, 

    {"rl b", 0x10}, {"rl c", 0x11}, {"rl d", 0x12}, {"rl e", 0x13}, {"rl h", 0x14}, 
    {"rl l", 0x15}, {"rl (hl)", 0x16}, {"rl a", 0x17}, {"rr b", 0x18}, {"rr c", 0x19}, 
    {"rr d", 0x1A}, {"rr e", 0x1B}, {"rr h", 0x1C}, {"rr l", 0x1D}, {"rr (hl)", 0x1E}, 
    {"rr a", 0x1F}, 

    {"sla b", 0x20}, {"sla c", 0x21}, {"sla d", 0x22}, {"sla e", 0x23}, {"sla h", 0x24}, 
    {"sla l", 0x25}, {"sla (hl)", 0x26}, {"sla a", 0x27}, {"sra b", 0x28}, {"sra c", 0x29}, 
    {"sra d", 0x2A}, {"sra e", 0x2B}, {"sra h", 0x2C}, {"sra l", 0x2D}, {"sra (hl)", 0x2E}, 
    {"sra a", 0x2F}, 

    {"sll b", 0x30}, {"sll c", 0x31}, {"sll d", 0x32}, {"sll e", 0x33}, {"sll h", 0x34}, 
    {"sll l", 0x35}, {"sll (hl)", 0x36}, {"sll a", 0x37}, {"srl b", 0x38}, {"srl c", 0x39}, 
    {"srl d", 0x3A}, {"srl e", 0x3B}, {"srl h", 0x3C}, {"srl l", 0x3D}, {"srl (hl)", 0x3E}, 
    {"srl a", 0x3F}, 

    {"bit 0, b", 0x40}, {"bit 0, c", 0x41}, {"bit 0, d", 0x42}, {"bit 0, e", 0x43}, {"bit 0, h", 0x44}, 
    {"bit 0, l", 0x45}, {"bit 0, (hl)", 0x46}, {"bit 0, a", 0x47}, {"bit 1, b", 0x48}, {"bit 1, c", 0x49}, 
    {"bit 1, d", 0x4A}, {"bit 1, e", 0x4B}, {"bit 1, h", 0x4C}, {"bit 1, l", 0x4D}, {"bit 1, (hl)", 0x4E}, 
    {"bit 1, a", 0x4F}, 

    {"bit 2, b", 0x50}, {"bit 2, c", 0x51}, {"bit 2, d", 0x52}, {"bit 2, e", 0x53}, {"bit 2, h", 0x54}, 
    {"bit 2, l", 0x55}, {"bit 2, (hl)", 0x56}, {"bit 2, a", 0x57}, {"bit 3, b", 0x58}, {"bit 3, c", 0x59}, 
    {"bit 3, d", 0x5A}, {"bit 3, e", 0x5B}, {"bit 3, h", 0x5C}, {"bit 3, l", 0x5D}, {"bit 3, (hl)", 0x5E}, 
    {"bit 3, a", 0x5F}, 

    {"bit 4, b", 0x60}, {"bit 4, c", 0x61}, {"bit 4, d", 0x62}, {"bit 4, e", 0x63}, {"bit 4, h", 0x64}, 
    {"bit 4, l", 0x65}, {"bit 4, (hl)", 0x66}, {"bit 4, a", 0x67}, {"bit 5, b", 0x68}, {"bit 5, c", 0x69}, 
    {"bit 5, d", 0x6A}, {"bit 5, e", 0x6B}, {"bit 5, h", 0x6C}, {"bit 5, l", 0x6D}, {"bit 5, (hl)", 0x6E}, 
    {"bit 5, a", 0x6F}, 

    {"bit 6, b", 0x70}, {"bit 6, c", 0x71}, {"bit 6, d", 0x72}, {"bit 6, e", 0x73}, {"bit 6, h", 0x74}, 
    {"bit 6, l", 0x75}, {"bit 6, (hl)", 0x76}, {"bit 6, a", 0x77}, {"bit 7, b", 0x78}, {"bit 7, c", 0x79}, 
    {"bit 7, d", 0x7A}, {"bit 7, e", 0x7B}, {"bit 7, h", 0x7C}, {"bit 7, l", 0x7D}, {"bit 7, (hl)", 0x7E}, 
    {"bit 7, a", 0x7F}, 

    {"res 0, b", 0x80}, {"res 0, c", 0x81}, {"res 0, d", 0x82}, {"res 0, e", 0x83}, {"res 0, h", 0x84}, 
    {"res 0, l", 0x85}, {"res 0, (hl)", 0x86}, {"res 0, a", 0x87}, {"res 1, b", 0x88}, {"res 1, c", 0x89}, 
    {"res 1, d", 0x8A}, {"res 1, e", 0x8B}, {"res 1, h", 0x8C}, {"res 1, l", 0x8D}, {"res 1, (hl)", 0x8E}, 
    {"res 1, a", 0x8F}, 

    {"res 2, b", 0x90}, {"res 2, c", 0x91}, {"res 2, d", 0x92}, {"res 2, e", 0x93}, {"res 2, h", 0x94}, 
    {"res 2, l", 0x95}, {"res 2, (hl)", 0x96}, {"res 2, a", 0x97}, {"res 3, b", 0x98}, {"res 3, c", 0x99}, 
    {"res 3, d", 0x9A}, {"res 3, e", 0x9B}, {"res 3, h", 0x9C}, {"res 3, l", 0x9D}, {"res 3, (hl)", 0x9E}, 
    {"res 3, a", 0x9F}, 

    {"res 4, b", 0xA0}, {"res 4, c", 0xA1}, {"res 4, d", 0xA2}, {"res 4, e", 0xA3}, {"res 4, h", 0xA4}, 
    {"res 4, l", 0xA5}, {"res 4, (hl)", 0xA6}, {"res 4, a", 0xA7}, {"res 5, b", 0xA8}, {"res 5, c", 0xA9}, 
    {"res 5, d", 0xAA}, {"res 5, e", 0xAB}, {"res 5, h", 0xAC}, {"res 5, l", 0xAD}, {"res 5, (hl)", 0xAE}, 
    {"res 5, a", 0xAF}, 

    {"res 6, b", 0xB0}, {"res 6, c", 0xB1}, {"res 6, d", 0xB2}, {"res 6, e", 0xB3}, {"res 6, h", 0xB4}, 
    {"res 6, l", 0xB5}, {"res 6, (hl)", 0xB6}, {"res 6, a", 0xB7}, {"res 7, b", 0xB8}, {"res 7, c", 0xB9}, 
    {"res 7, d", 0xBA}, {"res 7, e", 0xBB}, {"res 7, h", 0xBC}, {"res 7, l", 0xBD}, {"res 7, (hl)", 0xBE}, 
    {"res 7, a", 0xBF}, 

    {"set 0, b", 0xC0}, {"set 0, c", 0xC1}, {"set 0, d", 0xC2}, {"set 0, e", 0xC3}, {"set 0, h", 0xC4}, 
    {"set 0, l", 0xC5}, {"set 0, (hl)", 0xC6}, {"set 0, a", 0xC7}, {"set 1, b", 0xC8}, {"set 1, c", 0xC9}, 
    {"set 1, d", 0xCA}, {"set 1, e", 0xCB}, {"set 1, h", 0xCC}, {"set 1, l", 0xCD}, {"set 1, (hl)", 0xCE}, 
    {"set 1, a", 0xCF}, 

    {"set 2, b", 0xD0}, {"set 2, c", 0xD1}, {"set 2, d", 0xD2}, {"set 2, e", 0xD3}, {"set 2, h", 0xD4}, 
    {"set 2, l", 0xD5}, {"set 2, (hl)", 0xD6}, {"set 2, a", 0xD7}, {"set 3, b", 0xD8}, {"set 3, c", 0xD9}, 
    {"set 3, d", 0xDA}, {"set 3, e", 0xDB}, {"set 3, h", 0xDC}, {"set 3, l", 0xDD}, {"set 3, (hl)", 0xDE}, 
    {"set 3, a", 0xDF}, 

    {"set 4, b", 0xE0}, {"set 4, c", 0xE1}, {"set 4, d", 0xE2}, {"set 4, e", 0xE3}, {"set 4, h", 0xE4}, 
    {"set 4, l", 0xE5}, {"set 4, (hl)", 0xE6}, {"set 4, a", 0xE7}, {"set 5, b", 0xE8}, {"set 5, c", 0xE9}, 
    {"set 5, d", 0xEA}, {"set 5, e", 0xEB}, {"set 5, h", 0xEC}, {"set 5, l", 0xED}, {"set 5, (hl)", 0xEE}, 
    {"set 5, a", 0xEF}, 

    {"set 6, b", 0xF0}, {"set 6, c", 0xF1}, {"set 6, d", 0xF2}, {"set 6, e", 0xF3}, {"set 6, h", 0xF4}, 
    {"set 6, l", 0xF5}, {"set 6, (hl)", 0xF6}, {"set 6, a", 0xF7}, {"set 7, b", 0xF8}, {"set 7, c", 0xF9}, 
    {"set 7, d", 0xFA}, {"set 7, e", 0xFB}, {"set 7, h", 0xFC}, {"set 7, l", 0xFD}, {"set 7, (hl)", 0xFE}, 
    {"set 7, a", 0xFF}, 

    // IX instructions (DD)
    {"ld ix, nn", 0x21}, {"ld (nn), ix", 0x22}, {"inc ix", 0x23}, {"inc ixh", 0x24}, {"dec ixh", 0x25}, 
    {"ld ixh, n", 0x26}, {"add ix, ix", 0x29}, {"ld ix, (nn)", 0x2A}, {"dec ix", 0x2B}, {"inc ixl", 0x2C}, 
    {"dec ixl", 0x2D}, {"ld ixl, n", 0x2E}, {"inc (ix+d)", 0x34}, {"dec (ix+d)", 0x35}, 
    {"ld (ix+d), n", 0x36}, {"add ix, sp", 0x39}, 

    {"ld b, ixh", 0x44}, {"ld b, ixl", 0x45}, {"ld b, (ix+d)", 0x46}, {"ld c, ixh", 0x4C}, 
    {"ld c, ixl", 0x4D}, {"ld c, (ix+d)", 0x4E}, {"ld d, ixh", 0x54}, {"ld d, ixl", 0x55}, 
    {"ld d, (ix+d)", 0x56}, {"ld e, ixh", 0x5C}, {"ld e, ixl", 0x5D}, {"ld e, (ix+d)", 0x5E}, 
    {"ld ixh, b", 0x60}, {"ld ixh, c", 0x61}, {"ld ixh, d", 0x62}, {"ld ixh, e", 0x63}, 
    {"ld ixh, ixh", 0x64}, {"ld ixh, ixl", 0x65}, {"ld h, (ix+d)", 0x66}, {"ld ixh, a", 0x67}, 
    {"ld ixl, b", 0x68}, {"ld ixl, c", 0x69}, {"ld ixl, d", 0x6A}, {"ld ixl, e", 0x6B}, 
    {"ld ixl, ixh", 0x6C}, {"ld ixl, ixl", 0x6D}, {"ld l, (ix+d)", 0x6E}, {"ld ixl, a", 0x6F}, 
    {"ld (ix+d), b", 0x70}, {"ld (ix+d), c", 0x71}, {"ld (ix+d), d", 0x72}, {"ld (ix+d), e", 0x73}, 
    {"ld (ix+d), h", 0x74}, {"ld (ix+d), l", 0x75}, {"ld (ix+d), a", 0x77}, 

    {"ld a, ixh", 0x7C}, {"ld a, ixl", 0x7D}, {"ld a, (ix+d)", 0x7E}, {"add a, ixh", 0x84}, 
    {"add a, ixl", 0x85}, {"add a, (ix+d)", 0x86}, {"adc a, ixh", 0x8C}, {"adc a, ixl", 0x8D}, 
    {"adc a, (ix+d)", 0x8E}, {"sub ixh", 0x94}, {"sub ixl", 0x95}, {"sub (ix+d)", 0x96}, 
    {"sbc a, ixh", 0x9C}, {"sbc a, ixl", 0x9D}, {"sbc a, (ix+d)", 0x9E}, {"and ixh", 0xA4}, 
    {"and ixl", 0xA5}, {"and (ix+d)", 0xA6}, {"xor ixh", 0xAC}, {"xor ixl", 0xAD}, 
    {"xor (ix+d)", 0xAE}, {"or ixh", 0xB4}, {"or ixl", 0xB5}, {"or (ix+d)", 0xB6}, 
    {"cp ixh", 0xBC}, {"cp ixl", 0xBD}, {"cp (ix+d)", 0xBE}, 

    {"pop ix", 0xE1}, {"ex (sp), ix", 0xE3}, {"push ix", 0xE5}, {"jp (ix)", 0xE9}, 

    // IX bit instructions (DD CB)
    {"rlc (ix+d), b", 0x00}, {"rlc (ix+d), c", 0x01}, {"rlc (ix+d), d", 0x02}, {"rlc (ix+d), e", 0x03}, 
    {"rlc (ix+d), h", 0x04}, {"rlc (ix+d), l", 0x05}, {"rlc (ix+d)", 0x06}, {"rlc (ix+d), a", 0x07}, 
    {"rrc (ix+d), b", 0x08}, {"rrc (ix+d), c", 0x09}, {"rrc (ix+d), d", 0x0A}, {"rrc (ix+d), e", 0x0B}, 
    {"rrc (ix+d), h", 0x0C}, {"rrc (ix+d), l", 0x0D}, {"rrc (ix+d)", 0x0E}, {"rrc (ix+d), a", 0x0F}, 

    {"rl (ix+d), b", 0x10}, {"rl (ix+d), c", 0x11}, {"rl (ix+d), d", 0x12}, {"rl (ix+d), e", 0x13}, 
    {"rl (ix+d), h", 0x14}, {"rl (ix+d), l", 0x15}, {"rl (ix+d)", 0x16}, {"rl (ix+d), a", 0x17}, 
    {"rr (ix+d), b", 0x18}, {"rr (ix+d), c", 0x19}, {"rr (ix+d), d", 0x1A}, {"rr (ix+d), e", 0x1B}, 
    {"rr (ix+d), h", 0x1C}, {"rr (ix+d), l", 0x1D}, {"rr (ix+d)", 0x1E}, {"rr (ix+d), a", 0x1F}, 

    {"sla (ix+d), b", 0x20}, {"sla (ix+d), c", 0x21}, {"sla (ix+d), d", 0x22}, {"sla (ix+d), e", 0x23}, 
    {"sla (ix+d), h", 0x24}, {"sla (ix+d), l", 0x25}, {"sla (ix+d)", 0x26}, {"sla (ix+d), a", 0x27}, 
    {"sra (ix+d), b", 0x28}, {"sra (ix+d), c", 0x29}, {"sra (ix+d), d", 0x2A}, {"sra (ix+d), e", 0x2B}, 
    {"sra (ix+d), h", 0x2C}, {"sra (ix+d), l", 0x2D}, {"sra (ix+d)", 0x2E}, {"sra (ix+d), a", 0x2F}, 

    {"sll (ix+d), b", 0x30}, {"sll (ix+d), c", 0x31}, {"sll (ix+d), d", 0x32}, {"sll (ix+d), e", 0x33}, 
    {"sll (ix+d), h", 0x34}, {"sll (ix+d), l", 0x35}, {"sll (ix+d)", 0x36}, {"sll (ix+d), a", 0x37}, 
    {"srl (ix+d), b", 0x38}, {"srl (ix+d), c", 0x39}, {"srl (ix+d), d", 0x3A}, {"srl (ix+d), e", 0x3B}, 
    {"srl (ix+d), h", 0x3C}, {"srl (ix+d), l", 0x3D}, {"srl (ix+d)", 0x3E}, {"srl (ix+d), a", 0x3F}, 

    {"bit 0, (ix+d)", 0x40}, {"bit 0, (ix+d)", 0x41}, {"bit 0, (ix+d)", 0x42}, {"bit 0, (ix+d)", 0x43}, 
    {"bit 0, (ix+d)", 0x44}, {"bit 0, (ix+d)", 0x45}, {"bit 0, (ix+d)", 0x46}, {"bit 0, (ix+d)", 0x47}, 
    {"bit 1, (ix+d)", 0x48}, {"bit 1, (ix+d)", 0x49}, {"bit 1, (ix+d)", 0x4A}, {"bit 1, (ix+d)", 0x4B}, 
    {"bit 1, (ix+d)", 0x4C}, {"bit 1, (ix+d)", 0x4D}, {"bit 1, (ix+d)", 0x4E}, {"bit 1, (ix+d)", 0x4F}, 

    {"bit 2, (ix+d)", 0x50}, {"bit 2, (ix+d)", 0x51}, {"bit 2, (ix+d)", 0x52}, {"bit 2, (ix+d)", 0x53}, 
    {"bit 2, (ix+d)", 0x54}, {"bit 2, (ix+d)", 0x55}, {"bit 2, (ix+d)", 0x56}, {"bit 2, (ix+d)", 0x57}, 
    {"bit 3, (ix+d)", 0x58}, {"bit 3, (ix+d)", 0x59}, {"bit 3, (ix+d)", 0x5A}, {"bit 3, (ix+d)", 0x5B}, 
    {"bit 3, (ix+d)", 0x5C}, {"bit 3, (ix+d)", 0x5D}, {"bit 3, (ix+d)", 0x5E}, {"bit 3, (ix+d)", 0x5F}, 

    {"bit 4, (ix+d)", 0x60}, {"bit 4, (ix+d)", 0x61}, {"bit 4, (ix+d)", 0x62}, {"bit 4, (ix+d)", 0x63}, 
    {"bit 4, (ix+d)", 0x64}, {"bit 4, (ix+d)", 0x65}, {"bit 4, (ix+d)", 0x66}, {"bit 4, (ix+d)", 0x67}, 
    {"bit 5, (ix+d)", 0x68}, {"bit 5, (ix+d)", 0x69}, {"bit 5, (ix+d)", 0x6A}, {"bit 5, (ix+d)", 0x6B}, 
    {"bit 5, (ix+d)", 0x6C}, {"bit 5, (ix+d)", 0x6D}, {"bit 5, (ix+d)", 0x6E}, {"bit 5, (ix+d)", 0x6F}, 

    {"bit 6, (ix+d)", 0x70}, {"bit 6, (ix+d)", 0x71}, {"bit 6, (ix+d)", 0x72}, {"bit 6, (ix+d)", 0x73}, 
    {"bit 6, (ix+d)", 0x74}, {"bit 6, (ix+d)", 0x75}, {"bit 6, (ix+d)", 0x76}, {"bit 6, (ix+d)", 0x77}, 
    {"bit 7, (ix+d)", 0x78}, {"bit 7, (ix+d)", 0x79}, {"bit 7, (ix+d)", 0x7A}, {"bit 7, (ix+d)", 0x7B}, 
    {"bit 7, (ix+d)", 0x7C}, {"bit 7, (ix+d)", 0x7D}, {"bit 7, (ix+d)", 0x7E}, {"bit 7, (ix+d)", 0x7F}, 

    {"res 0, (ix+d), b", 0x80}, {"res 0, (ix+d), c", 0x81}, {"res 0, (ix+d), d", 0x82}, 
    {"res 0, (ix+d), e", 0x83}, {"res 0, (ix+d), h", 0x84}, {"res 0, (ix+d), l", 0x85}, {"res 0, (ix+d)", 0x86}, 
    {"res 0, (ix+d), a", 0x87}, {"res 1, (ix+d), b", 0x88}, {"res 1, (ix+d), c", 0x89}, 
    {"res 1, (ix+d), d", 0x8A}, {"res 1, (ix+d), e", 0x8B}, {"res 1, (ix+d), h", 0x8C}, 
    {"res 1, (ix+d), l", 0x8D}, {"res 1, (ix+d)", 0x8E}, {"res 1, (ix+d), a", 0x8F}, 
    {"res 2, (ix+d), b", 0x90}, {"res 2, (ix+d), c", 0x91}, {"res 2, (ix+d), d", 0x92}, 
    {"res 2, (ix+d), e", 0x93}, {"res 2, (ix+d), h", 0x94}, {"res 2, (ix+d), l", 0x95}, 
    {"res 2, (ix+d)", 0x96}, {"res 2, (ix+d), a", 0x97}, {"res 3, (ix+d), b", 0x98}, 
    {"res 3, (ix+d), c", 0x99}, {"res 3, (ix+d), d", 0x9A}, {"res 3, (ix+d), e", 0x9B}, 
    {"res 3, (ix+d), h", 0x9C}, {"res 3, (ix+d), l", 0x9D}, {"res 3, (ix+d)", 0x9E}, 
    {"res 3, (ix+d), a", 0x9F}, 

    {"res 4, (ix+d), b", 0xA0}, {"res 4, (ix+d), c", 0xA1}, {"res 4, (ix+d), d", 0xA2}, 
    {"res 4, (ix+d), e", 0xA3}, {"res 4, (ix+d), h", 0xA4}, {"res 4, (ix+d), l", 0xA5}, 
    {"res 4, (ix+d)", 0xA6}, {"res 4, (ix+d), a", 0xA7}, {"res 5, (ix+d), b", 0xA8}, 
    {"res 5, (ix+d), c", 0xA9}, {"res 5, (ix+d), d", 0xAA}, {"res 5, (ix+d), e", 0xAB}, 
    {"res 5, (ix+d), h", 0xAC}, {"res 5, (ix+d), l", 0xAD}, {"res 5, (ix+d)", 0xAE}, 
    {"res 5, (ix+d), a", 0xAF}, 

    {"res 6, (ix+d), b", 0xB0}, {"res 6, (ix+d), c", 0xB1}, {"res 6, (ix+d), d", 0xB2}, 
    {"res 6, (ix+d), e", 0xB3}, {"res 6, (ix+d), h", 0xB4}, {"res 6, (ix+d), l", 0xB5}, 
    {"res 6, (ix+d)", 0xB6}, {"res 6, (ix+d), a", 0xB7}, {"res 7, (ix+d), b", 0xB8}, 
    {"res 7, (ix+d), c", 0xB9}, {"res 7, (ix+d), d", 0xBA}, {"res 7, (ix+d), e", 0xBB}, 
    {"res 7, (ix+d), h", 0xBC}, {"res 7, (ix+d), l", 0xBD}, {"res 7, (ix+d)", 0xBE}, 
    {"res 7, (ix+d), a", 0xBF}, 

    {"set 0, (ix+d), b", 0xC0}, {"set 0, (ix+d), c", 0xC1}, {"set 0, (ix+d), d", 0xC2}, 
    {"set 0, (ix+d), e", 0xC3}, {"set 0, (ix+d), h", 0xC4}, {"set 0, (ix+d), l", 0xC5}, 
    {"set 0, (ix+d)", 0xC6}, {"set 0, (ix+d), a", 0xC7}, {"set 1, (ix+d), b", 0xC8}, 
    {"set 1, (ix+d), c", 0xC9}, {"set 1, (ix+d), d", 0xCA}, {"set 1, (ix+d), e", 0xCB}, 
    {"set 1, (ix+d), h", 0xCC}, {"set 1, (ix+d), l", 0xCD}, {"set 1, (ix+d)", 0xCE}, 
    {"set 1, (ix+d), a", 0xCF}, 

    {"set 2, (ix+d), b", 0xD0}, {"set 2, (ix+d), c", 0xD1}, {"set 2, (ix+d), d", 0xD2}, 
    {"set 2, (ix+d), e", 0xD3}, {"set 2, (ix+d), h", 0xD4}, {"set 2, (ix+d), l", 0xD5}, 
    {"set 2, (ix+d)", 0xD6}, {"set 2, (ix+d), a", 0xD7}, {"set 3, (ix+d), b", 0xD8}, 
    {"set 3, (ix+d), c", 0xD9}, {"set 3, (ix+d), d", 0xDA}, {"set 3, (ix+d), e", 0xDB}, 
    {"set 3, (ix+d), h", 0xDC}, {"set 3, (ix+d), l", 0xDD}, {"set 3, (ix+d)", 0xDE}, 
    {"set 3, (ix+d), a", 0xDF}, 

    {"set 4, (ix+d), b", 0xE0}, {"set 4, (ix+d), c", 0xE1}, {"set 4, (ix+d), d", 0xE2}, 
    {"set 4, (ix+d), e", 0xE3}, {"set 4, (ix+d), h", 0xE4}, {"set 4, (ix+d), l", 0xE5}, 
    {"set 4, (ix+d)", 0xE6}, {"set 4, (ix+d), a", 0xE7}, {"set 5, (ix+d), b", 0xE8}, 
    {"set 5, (ix+d), c", 0xE9}, {"set 5, (ix+d), d", 0xEA}, {"set 5, (ix+d), e", 0xEB}, 
    {"set 5, (ix+d), h", 0xEC}, {"set 5, (ix+d), l", 0xED}, {"set 5, (ix+d)", 0xEE}, 
    {"set 5, (ix+d), a", 0xEF}, 

    {"set 6, (ix+d), b", 0xF0}, {"set 6, (ix+d), c", 0xF1}, {"set 6, (ix+d), d", 0xF2}, 
    {"set 6, (ix+d), e", 0xF3}, {"set 6, (ix+d), h", 0xF4}, {"set 6, (ix+d), l", 0xF5}, 
    {"set 6, (ix+d)", 0xF6}, {"set 6, (ix+d), a", 0xF7}, {"set 7, (ix+d), b", 0xF8}, 
    {"set 7, (ix+d), c", 0xF9}, {"set 7, (ix+d), d", 0xFA}, {"set 7, (ix+d), e", 0xFB}, 
    {"set 7, (ix+d), h", 0xFC}, {"set 7, (ix+d), l", 0xFD}, {"set 7, (ix+d)", 0xFE}, 
    {"set 7, (ix+d), a", 0xFF}, 

    // Misc instructions (ED)
    {"in0 b, (n)", 0x40}, {"out0 (n), b", 0x41}, {"tst b", 0x44}, {"in0 c, (n)", 0x48}, 
    {"out0 (n), c", 0x49}, {"tst c", 0x4C}, {"in0 d, (n)", 0x50}, {"out0 (n), d", 0x51}, 
    {"tst d", 0x54}, {"in0 e, (n)", 0x58}, {"out0 (n), e", 0x59}, {"tst e", 0x5C}, 
    {"in0 h, (n)", 0x60}, {"out0 (n), h", 0x61}, {"tst h", 0x64}, {"in0 l, (n)", 0x68}, 
    {"out0 (n), l", 0x69}, {"tst l", 0x6C}, {"tst (hl)", 0x74}, {"in0 a, (n)", 0x78}, 
    {"out0 (n), a", 0x79}, {"tst a", 0x7C}, 

    {"in b, (c)", 0x40}, {"out (c), b", 0x41}, {"sbc hl, bc", 0x42}, {"ld (nn), bc", 0x43}, 
    {"neg", 0x44}, {"retn", 0x45}, {"im 0", 0x46}, {"ld i, a", 0x47}, {"in c, (c)", 0x48}, 
    {"out (c), c", 0x49}, {"adc hl, bc", 0x4A}, {"ld bc, (nn)", 0x4B}, {"mlt bc", 0x4C}, 
    {"reti", 0x4D}, {"ld r, a", 0x4E}, {"in d, (c)", 0x50}, {"out (c), d", 0x51}, {"sbc hl, de", 0x52}, 
    {"ld (nn), de", 0x53}, {"im 1", 0x56}, {"ld a, i", 0x57}, {"in e, (c)", 0x58}, {"out (c), e", 0x59}, 
    {"adc hl, de", 0x5A}, {"ld de, (nn)", 0x5B}, {"mlt de", 0x5C}, {"im 2", 0x5E}, {"ld a, r", 0x5F}, 

    {"in h, (c)", 0x60}, {"out (c), h", 0x61}, {"sbc hl, hl", 0x62}, {"ld (nn), hl", 0x63}, 
    {"tst n", 0x64}, {"rrd", 0x67}, {"in l, (c)", 0x68}, {"out (c), l", 0x69}, {"adc hl, hl", 0x6A}, 
    {"ld hl, (nn)", 0x6B}, {"mlt hl", 0x6C}, {"rld", 0x6F}, {"in (c)", 0x70}, {"out (c), 0", 0x71}, 
    {"sbc hl, sp", 0x72}, {"ld (nn), sp", 0x73}, {"tstio n", 0x74}, {"slp", 0x76}, {"in a, (c)", 0x78}, 
    {"out (c), a", 0x79}, {"adc hl, sp", 0x7A}, {"ld sp, (nn)", 0x7B}, {"mlt sp", 0x7C}, 

    {"otim", 0xED}, {"otdm", 0xED}, {"otimr", 0xED}, {"otdmr", 0xED}, 

    {"ldi", 0xA0}, {"cpi", 0xA1}, {"ini", 0xA2}, {"outi", 0xA3}, {"ldd", 0xA8}, {"cpd", 0xA9}, 
    {"ind", 0xAA}, {"outd", 0xAB}, {"ldir", 0xB0}, {"cpir", 0xB1}, {"inir", 0xB2}, {"otir", 0xB3}, 

    // IY instructions (FD)
    {"ld iy, nn", 0x21}, {"ld (nn), iy", 0x22}, {"inc iy", 0x23}, {"inc iyh", 0x24}, {"dec iyh", 0x25}, 
    {"ld iyh, n", 0x26}, {"add iy, iy", 0x29}, {"ld iy, (nn)", 0x2A}, {"dec iy", 0x2B}, {"inc iyl", 0x2C}, 
    {"dec iyl", 0x2D}, {"ld iyl, n", 0x2E}, {"inc (iy+d)", 0x34}, {"dec (iy+d)", 0x35}, 
    {"ld (iy+d), n", 0x36}, {"add iy, sp", 0x39}, 

    {"ld b, iyh", 0x44}, {"ld b, iyl", 0x45}, {"ld b, (iy+d)", 0x46}, {"ld c, iyh", 0x4C}, 
    {"ld c, iyl", 0x4D}, {"ld c, (iy+d)", 0x4E}, {"ld d, iyh", 0x54}, {"ld d, iyl", 0x55}, 
    {"ld d, (iy+d)", 0x56}, {"ld e, iyh", 0x5C}, {"ld e, iyl", 0x5D}, {"ld e, (iy+d)", 0x5E},  
    {"ld iyh, b", 0x60}, {"ld iyh, c", 0x61}, {"ld iyh, d", 0x62}, {"ld iyh, e", 0x63}, 
    {"ld iyh, iyh", 0x64}, {"ld iyh, iyl", 0x65}, {"ld h, (iy+d)", 0x66}, {"ld iyh, a", 0x67}, 
    {"ld iyl, b", 0x68}, {"ld iyl, c", 0x69}, {"ld iyl, d", 0x6A}, {"ld iyl, e", 0x6B}, 
    {"ld iyl, iyh", 0x6C}, {"ld iyl, iyl", 0x6D}, {"ld l, (iy+d)", 0x6E}, {"ld iyl, a", 0x6F}, 
    {"ld (iy+d), b", 0x70}, {"ld (iy+d), c", 0x71}, {"ld (iy+d), d", 0x72}, {"ld (iy+d), e", 0x73}, 
    {"ld (iy+d), h", 0x74}, {"ld (iy+d), l", 0x75}, {"ld (iy+d), a", 0x77}, 

    {"ld a, iyh", 0x7C}, {"ld a, iyl", 0x7D}, {"ld a, (iy+d)", 0x7E}, {"add a, iyh", 0x84},  
    {"add a, iyl", 0x85}, {"add a, (iy+d)", 0x86}, {"adc a, iyh", 0x8C}, {"adc a, iyl", 0x8D}, 
    {"adc a, (iy+d)", 0x8E}, {"sub iyh", 0x94}, {"sub iyl", 0x95}, {"sub (iy+d)", 0x96}, 
    {"sbc a, iyh", 0x9C}, {"sbc a, iyl", 0x9D}, {"sbc a, (iy+d)", 0x9E}, {"and iyh", 0xA4}, 
    {"and iyl", 0xA5}, {"and (iy+d)", 0xA6}, {"xor iyh", 0xAC}, {"xor iyl", 0xAD}, 
    {"xor (iy+d)", 0xAE}, {"or iyh", 0xB4}, {"or iyl", 0xB5}, {"or (iy+d)", 0xB6}, 
    {"cp iyh", 0xBC}, {"cp iyl", 0xBD}, {"cp (iy+d)", 0xBE}, 

    {"pop iy", 0xE1}, {"ex (sp), iy", 0xE3}, {"push iy", 0xE5}, {"jp (iy)", 0xE9}, 

    // IY bit instructions (FD CB)
    {"rlc (iy+d), b", 0x00}, {"rlc (iy+d), c", 0x01}, {"rlc (iy+d), d", 0x02}, {"rlc (iy+d), e", 0x03}, 
    {"rlc (iy+d), h", 0x04}, {"rlc (iy+d), l", 0x05}, {"rlc (iy+d)", 0x06}, {"rlc (iy+d), a", 0x07},  
    {"rrc (iy+d), b", 0x08}, {"rrc (iy+d), c", 0x09}, {"rrc (iy+d), d", 0x0A}, {"rrc (iy+d), e", 0x0B}, 
    {"rrc (iy+d), h", 0x0C}, {"rrc (iy+d), l", 0x0D}, {"rrc (iy+d)", 0x0E}, {"rrc (iy+d), a", 0x0F}, 

    {"rl (iy+d), b", 0x10}, {"rl (iy+d), c", 0x11}, {"rl (iy+d), d", 0x12}, {"rl (iy+d), e", 0x13}, 
    {"rl (iy+d), h", 0x14}, {"rl (iy+d), l", 0x15}, {"rl (iy+d)", 0x16}, {"rl (iy+d), a", 0x17}, 
    {"rr (iy+d), b", 0x18}, {"rr (iy+d), c", 0x19}, {"rr (iy+d), d", 0x1A}, {"rr (iy+d), e", 0x1B}, 
    {"rr (iy+d), h", 0x1C}, {"rr (iy+d), l", 0x1D}, {"rr (iy+d)", 0x1E}, {"rr (iy+d), a", 0x1F}, 

    {"sla (iy+d), b", 0x20}, {"sla (iy+d), c", 0x21}, {"sla (iy+d), d", 0x22}, {"sla (iy+d), e", 0x23}, 
    {"sla (iy+d), h", 0x24}, {"sla (iy+d), l", 0x25}, {"sla (iy+d)", 0x26}, {"sla (iy+d), a", 0x27}, 
    {"sra (iy+d), b", 0x28}, {"sra (iy+d), c", 0x29}, {"sra (iy+d), d", 0x2A}, {"sra (iy+d), e", 0x2B}, 
    {"sra (iy+d), h", 0x2C}, {"sra (iy+d), l", 0x2D}, {"sra (iy+d)", 0x2E}, {"sra (iy+d), a", 0x2F}, 

    {"sll (iy+d), b", 0x30}, {"sll (iy+d), c", 0x31}, {"sll (iy+d), d", 0x32}, {"sll (iy+d), e", 0x33}, 
    {"sll (iy+d), h", 0x34}, {"sll (iy+d), l", 0x35}, {"sll (iy+d)", 0x36}, {"sll (iy+d), a", 0x37}, 
    {"srl (iy+d), b", 0x38}, {"srl (iy+d), c", 0x39}, {"srl (iy+d), d", 0x3A}, {"srl (iy+d), e", 0x3B}, 
    {"srl (iy+d), h", 0x3C}, {"srl (iy+d), l", 0x3D}, {"srl (iy+d)", 0x3E}, {"srl (iy+d), a", 0x3F}, 

    {"bit 0, (iy+d)", 0x40}, {"bit 0, (iy+d)", 0x41}, {"bit 0, (iy+d)", 0x42}, {"bit 0, (iy+d)", 0x43},  
    {"bit 0, (iy+d)", 0x44}, {"bit 0, (iy+d)", 0x45}, {"bit 0, (iy+d)", 0x46}, {"bit 0, (iy+d)", 0x47}, 
    {"bit 1, (iy+d)", 0x48}, {"bit 1, (iy+d)", 0x49}, {"bit 1, (iy+d)", 0x4A}, {"bit 1, (iy+d)", 0x4B}, 
    {"bit 1, (iy+d)", 0x4C}, {"bit 1, (iy+d)", 0x4D}, {"bit 1, (iy+d)", 0x4E}, {"bit 1, (iy+d)", 0x4F}, 

    {"bit 2, (iy+d)", 0x50}, {"bit 2, (iy+d)", 0x51}, {"bit 2, (iy+d)", 0x52}, {"bit 2, (iy+d)", 0x53}, 
    {"bit 2, (iy+d)", 0x54}, {"bit 2, (iy+d)", 0x55}, {"bit 2, (iy+d)", 0x56}, {"bit 2, (iy+d)", 0x57},  
    {"bit 3, (iy+d)", 0x58}, {"bit 3, (iy+d)", 0x59}, {"bit 3, (iy+d)", 0x5A}, {"bit 3, (iy+d)", 0x5B}, 
    {"bit 3, (iy+d)", 0x5C}, {"bit 3, (iy+d)", 0x5D}, {"bit 3, (iy+d)", 0x5E}, {"bit 3, (iy+d)", 0x5F}, 

    {"bit 4, (iy+d)", 0x60}, {"bit 4, (iy+d)", 0x61}, {"bit 4, (iy+d)", 0x62}, {"bit 4, (iy+d)", 0x63}, 
    {"bit 4, (iy+d)", 0x64}, {"bit 4, (iy+d)", 0x65}, {"bit 4, (iy+d)", 0x66}, {"bit 4, (iy+d)", 0x67}, 
    {"bit 5, (iy+d)", 0x68}, {"bit 5, (iy+d)", 0x69}, {"bit 5, (iy+d)", 0x6A}, {"bit 5, (iy+d)", 0x6B},  
    {"bit 5, (iy+d)", 0x6C}, {"bit 5, (iy+d)", 0x6D}, {"bit 5, (iy+d)", 0x6E}, {"bit 5, (iy+d)", 0x6F}, 

    {"bit 6, (iy+d)", 0x70}, {"bit 6, (iy+d)", 0x71}, {"bit 6, (iy+d)", 0x72}, {"bit 6, (iy+d)", 0x73}, 
    {"bit 6, (iy+d)", 0x74}, {"bit 6, (iy+d)", 0x75}, {"bit 6, (iy+d)", 0x76}, {"bit 6, (iy+d)", 0x77}, 
    {"bit 7, (iy+d)", 0x78}, {"bit 7, (iy+d)", 0x79}, {"bit 7, (iy+d)", 0x7A}, {"bit 7, (iy+d)", 0x7B}, 
    {"bit 7, (iy+d)", 0x7C}, {"bit 7, (iy+d)", 0x7D}, {"bit 7, (iy+d)", 0x7E}, {"bit 7, (iy+d)", 0x7F}, 

    {"res 0, (iy+d), b", 0x80}, {"res 0, (iy+d), c", 0x81}, {"res 0, (iy+d), d", 0x82},  
    {"res 0, (iy+d), e", 0x83}, {"res 0, (iy+d), h", 0x84}, {"res 0, (iy+d), l", 0x85}, {"res 0, (iy+d)", 0x86}, 
    {"res 0, (iy+d), a", 0x87}, {"res 1, (iy+d), b", 0x88}, {"res 1, (iy+d), c", 0x89},  
    {"res 1, (iy+d), d", 0x8A}, {"res 1, (iy+d), e", 0x8B}, {"res 1, (iy+d), h", 0x8C}, 
    {"res 1, (iy+d), l", 0x8D}, {"res 1, (iy+d)", 0x8E}, {"res 1, (iy+d), a", 0x8F}, 

    {"res 2, (iy+d), b", 0x90}, {"res 2, (iy+d), c", 0x91}, {"res 2, (iy+d), d", 0x92}, 
    {"res 2, (iy+d), e", 0x93}, {"res 2, (iy+d), h", 0x94}, {"res 2, (iy+d), l", 0x95}, 
    {"res 2, (iy+d)", 0x96}, {"res 2, (iy+d), a", 0x97}, {"res 3, (iy+d), b", 0x98},  
    {"res 3, (iy+d), c", 0x99}, {"res 3, (iy+d), d", 0x9A}, {"res 3, (iy+d), e", 0x9B}, 
    {"res 3, (iy+d), h", 0x9C}, {"res 3, (iy+d), l", 0x9D}, {"res 3, (iy+d)", 0x9E}, 
    {"res 3, (iy+d), a", 0x9F}, 

    {"res 4, (iy+d), b", 0xA0}, {"res 4, (iy+d), c", 0xA1}, {"res 4, (iy+d), d", 0xA2}, 
    {"res 4, (iy+d), e", 0xA3}, {"res 4, (iy+d), h", 0xA4}, {"res 4, (iy+d), l", 0xA5}, 
    {"res 4, (iy+d)", 0xA6}, {"res 4, (iy+d), a", 0xA7}, {"res 5, (iy+d), b", 0xA8}, 
    {"res 5, (iy+d), c", 0xA9}, {"res 5, (iy+d), d", 0xAA}, {"res 5, (iy+d), e", 0xAB},  
    {"res 5, (iy+d), h", 0xAC}, {"res 5, (iy+d), l", 0xAD}, {"res 5, (iy+d)", 0xAE}, 
    {"res 5, (iy+d), a", 0xAF}, 

    {"res 6, (iy+d), b", 0xB0}, {"res 6, (iy+d), c", 0xB1}, {"res 6, (iy+d), d", 0xB2}, 
    {"res 6, (iy+d), e", 0xB3}, {"res 6, (iy+d), h", 0xB4}, {"res 6, (iy+d), l", 0xB5}, 
    {"res 6, (iy+d)", 0xB6}, {"res 6, (iy+d), a", 0xB7}, {"res 7, (iy+d), b", 0xB8}, 
    {"res 7, (iy+d), c", 0xB9}, {"res 7, (iy+d), d", 0xBA}, {"res 7, (iy+d), e", 0xBB},  
    {"res 7, (iy+d), h", 0xBC}, {"res 7, (iy+d), l", 0xBD}, {"res 7, (iy+d)", 0xBE}, 
    {"res 7, (iy+d), a", 0xBF}, 

    {"set 0, (iy+d), b", 0xC0}, {"set 0, (iy+d), c", 0xC1}, {"set 0, (iy+d), d", 0xC2}, 
    {"set 0, (iy+d), e", 0xC3}, {"set 0, (iy+d), h", 0xC4}, {"set 0, (iy+d), l", 0xC5}, 
    {"set 0, (iy+d)", 0xC6}, {"set 0, (iy+d), a", 0xC7}, {"set 1, (iy+d), b", 0xC8},  
    {"set 1, (iy+d), c", 0xC9}, {"set 1, (iy+d), d", 0xCA}, {"set 1, (iy+d), e", 0xCB}, 
    {"set 1, (iy+d), h", 0xCC}, {"set 1, (iy+d), l", 0xCD}, {"set 1, (iy+d)", 0xCE}, 
    {"set 1, (iy+d), a", 0xCF}, 

    {"set 2, (iy+d), b", 0xD0}, {"set 2, (iy+d), c", 0xD1}, {"set 2, (iy+d), d", 0xD2}, 
    {"set 2, (iy+d), e", 0xD3}, {"set 2, (iy+d), h", 0xD4}, {"set 2, (iy+d), l", 0xD5}, 
    {"set 2, (iy+d)", 0xD6}, {"set 2, (iy+d), a", 0xD7}, {"set 3, (iy+d), b", 0xD8},  
    {"set 3, (iy+d), c", 0xD9}, {"set 3, (iy+d), d", 0xDA}, {"set 3, (iy+d), e", 0xDB}, 
    {"set 3, (iy+d), h", 0xDC}, {"set 3, (iy+d), l", 0xDD}, {"set 3, (iy+d)", 0xDE}, 
    {"set 3, (iy+d), a", 0xDF}, 

    {"set 4, (iy+d), b", 0xE0}, {"set 4, (iy+d), c", 0xE1}, {"set 4, (iy+d), d", 0xE2},  
    {"set 4, (iy+d), e", 0xE3}, {"set 4, (iy+d), h", 0xE4}, {"set 4, (iy+d), l", 0xE5}, 
    {"set 4, (iy+d)", 0xE6}, {"set 4, (iy+d), a", 0xE7}, {"set 5, (iy+d), b", 0xE8}, 
    {"set 5, (iy+d), c", 0xE9}, {"set 5, (iy+d), d", 0xEA}, {"set 5, (iy+d), e", 0xEB}, 
    {"set 5, (iy+d), h", 0xEC}, {"set 5, (iy+d), l", 0xED}, {"set 5, (iy+d)", 0xEE}, 
    {"set 5, (iy+d), a", 0xEF}, 

    {"set 6, (iy+d), b", 0xF0}, {"set 6, (iy+d), c", 0xF1}, {"set 6, (iy+d), d", 0xF2}, 
    {"set 6, (iy+d), e", 0xF3}, {"set 6, (iy+d), h", 0xF4}, {"set 6, (iy+d), l", 0xF5}, 
    {"set 6, (iy+d)", 0xF6}, {"set 6, (iy+d), a", 0xF7}, {"set 7, (iy+d), b", 0xF8}, 
    {"set 7, (iy+d), c", 0xF9}, {"set 7, (iy+d), d", 0xFA}, {"set 7, (iy+d), e", 0xFB}, 
    {"set 7, (iy+d), h", 0xFC}, {"set 7, (iy+d), l", 0xFD}, {"set 7, (iy+d)", 0xFE}, 
    {"set 7, (iy+d), a", 0xFF}
};

// This doesn't really need to be a map, but I can't be assed
// Used for fast lookups to determine if an opcode starts with CB
ubyte[string] cbMap = {
    {"rlc b", 0x00}, {"rlc c", 0x01}, {"rlc d", 0x02}, {"rlc e", 0x03}, {"rlc h", 0x04}, 
    {"rlc l", 0x05}, {"rlc (hl)", 0x06}, {"rlc a", 0x07}, {"rrc b", 0x08}, {"rrc c", 0x09}, 
    {"rrc d", 0x0A}, {"rrc e", 0x0B}, {"rrc h", 0x0C}, {"rrc l", 0x0D}, {"rrc (hl)", 0x0E}, 
    {"rrc a", 0x0F}, 

    {"rl b", 0x10}, {"rl c", 0x11}, {"rl d", 0x12}, {"rl e", 0x13}, {"rl h", 0x14}, 
    {"rl l", 0x15}, {"rl (hl)", 0x16}, {"rl a", 0x17}, {"rr b", 0x18}, {"rr c", 0x19}, 
    {"rr d", 0x1A}, {"rr e", 0x1B}, {"rr h", 0x1C}, {"rr l", 0x1D}, {"rr (hl)", 0x1E}, 
    {"rr a", 0x1F}, 

    {"sla b", 0x20}, {"sla c", 0x21}, {"sla d", 0x22}, {"sla e", 0x23}, {"sla h", 0x24}, 
    {"sla l", 0x25}, {"sla (hl)", 0x26}, {"sla a", 0x27}, {"sra b", 0x28}, {"sra c", 0x29}, 
    {"sra d", 0x2A}, {"sra e", 0x2B}, {"sra h", 0x2C}, {"sra l", 0x2D}, {"sra (hl)", 0x2E}, 
    {"sra a", 0x2F}, 

    {"sll b", 0x30}, {"sll c", 0x31}, {"sll d", 0x32}, {"sll e", 0x33}, {"sll h", 0x34}, 
    {"sll l", 0x35}, {"sll (hl)", 0x36}, {"sll a", 0x37}, {"srl b", 0x38}, {"srl c", 0x39}, 
    {"srl d", 0x3A}, {"srl e", 0x3B}, {"srl h", 0x3C}, {"srl l", 0x3D}, {"srl (hl)", 0x3E}, 
    {"srl a", 0x3F}, 

    {"bit 0, b", 0x40}, {"bit 0, c", 0x41}, {"bit 0, d", 0x42}, {"bit 0, e", 0x43}, {"bit 0, h", 0x44}, 
    {"bit 0, l", 0x45}, {"bit 0, (hl)", 0x46}, {"bit 0, a", 0x47}, {"bit 1, b", 0x48}, {"bit 1, c", 0x49}, 
    {"bit 1, d", 0x4A}, {"bit 1, e", 0x4B}, {"bit 1, h", 0x4C}, {"bit 1, l", 0x4D}, {"bit 1, (hl)", 0x4E}, 
    {"bit 1, a", 0x4F}, 

    {"bit 2, b", 0x50}, {"bit 2, c", 0x51}, {"bit 2, d", 0x52}, {"bit 2, e", 0x53}, {"bit 2, h", 0x54}, 
    {"bit 2, l", 0x55}, {"bit 2, (hl)", 0x56}, {"bit 2, a", 0x57}, {"bit 3, b", 0x58}, {"bit 3, c", 0x59}, 
    {"bit 3, d", 0x5A}, {"bit 3, e", 0x5B}, {"bit 3, h", 0x5C}, {"bit 3, l", 0x5D}, {"bit 3, (hl)", 0x5E}, 
    {"bit 3, a", 0x5F}, 

    {"bit 4, b", 0x60}, {"bit 4, c", 0x61}, {"bit 4, d", 0x62}, {"bit 4, e", 0x63}, {"bit 4, h", 0x64}, 
    {"bit 4, l", 0x65}, {"bit 4, (hl)", 0x66}, {"bit 4, a", 0x67}, {"bit 5, b", 0x68}, {"bit 5, c", 0x69}, 
    {"bit 5, d", 0x6A}, {"bit 5, e", 0x6B}, {"bit 5, h", 0x6C}, {"bit 5, l", 0x6D}, {"bit 5, (hl)", 0x6E}, 
    {"bit 5, a", 0x6F}, 

    {"bit 6, b", 0x70}, {"bit 6, c", 0x71}, {"bit 6, d", 0x72}, {"bit 6, e", 0x73}, {"bit 6, h", 0x74}, 
    {"bit 6, l", 0x75}, {"bit 6, (hl)", 0x76}, {"bit 6, a", 0x77}, {"bit 7, b", 0x78}, {"bit 7, c", 0x79}, 
    {"bit 7, d", 0x7A}, {"bit 7, e", 0x7B}, {"bit 7, h", 0x7C}, {"bit 7, l", 0x7D}, {"bit 7, (hl)", 0x7E}, 
    {"bit 7, a", 0x7F}, 

    {"res 0, b", 0x80}, {"res 0, c", 0x81}, {"res 0, d", 0x82}, {"res 0, e", 0x83}, {"res 0, h", 0x84}, 
    {"res 0, l", 0x85}, {"res 0, (hl)", 0x86}, {"res 0, a", 0x87}, {"res 1, b", 0x88}, {"res 1, c", 0x89}, 
    {"res 1, d", 0x8A}, {"res 1, e", 0x8B}, {"res 1, h", 0x8C}, {"res 1, l", 0x8D}, {"res 1, (hl)", 0x8E}, 
    {"res 1, a", 0x8F}, 

    {"res 2, b", 0x90}, {"res 2, c", 0x91}, {"res 2, d", 0x92}, {"res 2, e", 0x93}, {"res 2, h", 0x94}, 
    {"res 2, l", 0x95}, {"res 2, (hl)", 0x96}, {"res 2, a", 0x97}, {"res 3, b", 0x98}, {"res 3, c", 0x99}, 
    {"res 3, d", 0x9A}, {"res 3, e", 0x9B}, {"res 3, h", 0x9C}, {"res 3, l", 0x9D}, {"res 3, (hl)", 0x9E}, 
    {"res 3, a", 0x9F}, 

    {"res 4, b", 0xA0}, {"res 4, c", 0xA1}, {"res 4, d", 0xA2}, {"res 4, e", 0xA3}, {"res 4, h", 0xA4}, 
    {"res 4, l", 0xA5}, {"res 4, (hl)", 0xA6}, {"res 4, a", 0xA7}, {"res 5, b", 0xA8}, {"res 5, c", 0xA9}, 
    {"res 5, d", 0xAA}, {"res 5, e", 0xAB}, {"res 5, h", 0xAC}, {"res 5, l", 0xAD}, {"res 5, (hl)", 0xAE}, 
    {"res 5, a", 0xAF}, 

    {"res 6, b", 0xB0}, {"res 6, c", 0xB1}, {"res 6, d", 0xB2}, {"res 6, e", 0xB3}, {"res 6, h", 0xB4}, 
    {"res 6, l", 0xB5}, {"res 6, (hl)", 0xB6}, {"res 6, a", 0xB7}, {"res 7, b", 0xB8}, {"res 7, c", 0xB9}, 
    {"res 7, d", 0xBA}, {"res 7, e", 0xBB}, {"res 7, h", 0xBC}, {"res 7, l", 0xBD}, {"res 7, (hl)", 0xBE}, 
    {"res 7, a", 0xBF}, 

    {"set 0, b", 0xC0}, {"set 0, c", 0xC1}, {"set 0, d", 0xC2}, {"set 0, e", 0xC3}, {"set 0, h", 0xC4}, 
    {"set 0, l", 0xC5}, {"set 0, (hl)", 0xC6}, {"set 0, a", 0xC7}, {"set 1, b", 0xC8}, {"set 1, c", 0xC9}, 
    {"set 1, d", 0xCA}, {"set 1, e", 0xCB}, {"set 1, h", 0xCC}, {"set 1, l", 0xCD}, {"set 1, (hl)", 0xCE}, 
    {"set 1, a", 0xCF}, 

    {"set 2, b", 0xD0}, {"set 2, c", 0xD1}, {"set 2, d", 0xD2}, {"set 2, e", 0xD3}, {"set 2, h", 0xD4}, 
    {"set 2, l", 0xD5}, {"set 2, (hl)", 0xD6}, {"set 2, a", 0xD7}, {"set 3, b", 0xD8}, {"set 3, c", 0xD9}, 
    {"set 3, d", 0xDA}, {"set 3, e", 0xDB}, {"set 3, h", 0xDC}, {"set 3, l", 0xDD}, {"set 3, (hl)", 0xDE}, 
    {"set 3, a", 0xDF}, 

    {"set 4, b", 0xE0}, {"set 4, c", 0xE1}, {"set 4, d", 0xE2}, {"set 4, e", 0xE3}, {"set 4, h", 0xE4}, 
    {"set 4, l", 0xE5}, {"set 4, (hl)", 0xE6}, {"set 4, a", 0xE7}, {"set 5, b", 0xE8}, {"set 5, c", 0xE9}, 
    {"set 5, d", 0xEA}, {"set 5, e", 0xEB}, {"set 5, h", 0xEC}, {"set 5, l", 0xED}, {"set 5, (hl)", 0xEE}, 
    {"set 5, a", 0xEF}, 

    {"set 6, b", 0xF0}, {"set 6, c", 0xF1}, {"set 6, d", 0xF2}, {"set 6, e", 0xF3}, {"set 6, h", 0xF4}, 
    {"set 6, l", 0xF5}, {"set 6, (hl)", 0xF6}, {"set 6, a", 0xF7}, {"set 7, b", 0xF8}, {"set 7, c", 0xF9}, 
    {"set 7, d", 0xFA}, {"set 7, e", 0xFB}, {"set 7, h", 0xFC}, {"set 7, l", 0xFD}, {"set 7, (hl)", 0xFE}, 
    {"set 7, a", 0xFF}
};

// Same shit as cbMap
ubyte[string] ddMap = {
    {"ld ix, nn", 0x21}, {"ld (nn), ix", 0x22}, {"inc ix", 0x23}, {"inc ixh", 0x24}, {"dec ixh", 0x25}, 
    {"ld ixh, n", 0x26}, {"add ix, ix", 0x29}, {"ld ix, (nn)", 0x2A}, {"dec ix", 0x2B}, {"inc ixl", 0x2C}, 
    {"dec ixl", 0x2D}, {"ld ixl, n", 0x2E}, {"inc (ix+d)", 0x34}, {"dec (ix+d)", 0x35}, 
    {"ld (ix+d), n", 0x36}, {"add ix, sp", 0x39}, 

    {"ld b, ixh", 0x44}, {"ld b, ixl", 0x45}, {"ld b, (ix+d)", 0x46}, {"ld c, ixh", 0x4C}, 
    {"ld c, ixl", 0x4D}, {"ld c, (ix+d)", 0x4E}, {"ld d, ixh", 0x54}, {"ld d, ixl", 0x55}, 
    {"ld d, (ix+d)", 0x56}, {"ld e, ixh", 0x5C}, {"ld e, ixl", 0x5D}, {"ld e, (ix+d)", 0x5E}, 
    {"ld ixh, b", 0x60}, {"ld ixh, c", 0x61}, {"ld ixh, d", 0x62}, {"ld ixh, e", 0x63}, 
    {"ld ixh, ixh", 0x64}, {"ld ixh, ixl", 0x65}, {"ld h, (ix+d)", 0x66}, {"ld ixh, a", 0x67}, 
    {"ld ixl, b", 0x68}, {"ld ixl, c", 0x69}, {"ld ixl, d", 0x6A}, {"ld ixl, e", 0x6B}, 
    {"ld ixl, ixh", 0x6C}, {"ld ixl, ixl", 0x6D}, {"ld l, (ix+d)", 0x6E}, {"ld ixl, a", 0x6F}, 
    {"ld (ix+d), b", 0x70}, {"ld (ix+d), c", 0x71}, {"ld (ix+d), d", 0x72}, {"ld (ix+d), e", 0x73}, 
    {"ld (ix+d), h", 0x74}, {"ld (ix+d), l", 0x75}, {"ld (ix+d), a", 0x77}, 

    {"ld a, ixh", 0x7C}, {"ld a, ixl", 0x7D}, {"ld a, (ix+d)", 0x7E}, {"add a, ixh", 0x84}, 
    {"add a, ixl", 0x85}, {"add a, (ix+d)", 0x86}, {"adc a, ixh", 0x8C}, {"adc a, ixl", 0x8D}, 
    {"adc a, (ix+d)", 0x8E}, {"sub ixh", 0x94}, {"sub ixl", 0x95}, {"sub (ix+d)", 0x96}, 
    {"sbc a, ixh", 0x9C}, {"sbc a, ixl", 0x9D}, {"sbc a, (ix+d)", 0x9E}, {"and ixh", 0xA4}, 
    {"and ixl", 0xA5}, {"and (ix+d)", 0xA6}, {"xor ixh", 0xAC}, {"xor ixl", 0xAD}, 
    {"xor (ix+d)", 0xAE}, {"or ixh", 0xB4}, {"or ixl", 0xB5}, {"or (ix+d)", 0xB6}, 
    {"cp ixh", 0xBC}, {"cp ixl", 0xBD}, {"cp (ix+d)", 0xBE}, 

    {"pop ix", 0xE1}, {"ex (sp), ix", 0xE3}, {"push ix", 0xE5}, {"jp (ix)", 0xE9}
};

// Same shit as cbMap
ubyte[string] ddcbMap = {
    {"rlc (ix+d), b", 0x00}, {"rlc (ix+d), c", 0x01}, {"rlc (ix+d), d", 0x02}, {"rlc (ix+d), e", 0x03}, 
    {"rlc (ix+d), h", 0x04}, {"rlc (ix+d), l", 0x05}, {"rlc (ix+d)", 0x06}, {"rlc (ix+d), a", 0x07}, 
    {"rrc (ix+d), b", 0x08}, {"rrc (ix+d), c", 0x09}, {"rrc (ix+d), d", 0x0A}, {"rrc (ix+d), e", 0x0B}, 
    {"rrc (ix+d), h", 0x0C}, {"rrc (ix+d), l", 0x0D}, {"rrc (ix+d)", 0x0E}, {"rrc (ix+d), a", 0x0F}, 

    {"rl (ix+d), b", 0x10}, {"rl (ix+d), c", 0x11}, {"rl (ix+d), d", 0x12}, {"rl (ix+d), e", 0x13}, 
    {"rl (ix+d), h", 0x14}, {"rl (ix+d), l", 0x15}, {"rl (ix+d)", 0x16}, {"rl (ix+d), a", 0x17}, 
    {"rr (ix+d), b", 0x18}, {"rr (ix+d), c", 0x19}, {"rr (ix+d), d", 0x1A}, {"rr (ix+d), e", 0x1B}, 
    {"rr (ix+d), h", 0x1C}, {"rr (ix+d), l", 0x1D}, {"rr (ix+d)", 0x1E}, {"rr (ix+d), a", 0x1F}, 

    {"sla (ix+d), b", 0x20}, {"sla (ix+d), c", 0x21}, {"sla (ix+d), d", 0x22}, {"sla (ix+d), e", 0x23}, 
    {"sla (ix+d), h", 0x24}, {"sla (ix+d), l", 0x25}, {"sla (ix+d)", 0x26}, {"sla (ix+d), a", 0x27}, 
    {"sra (ix+d), b", 0x28}, {"sra (ix+d), c", 0x29}, {"sra (ix+d), d", 0x2A}, {"sra (ix+d), e", 0x2B}, 
    {"sra (ix+d), h", 0x2C}, {"sra (ix+d), l", 0x2D}, {"sra (ix+d)", 0x2E}, {"sra (ix+d), a", 0x2F}, 

    {"sll (ix+d), b", 0x30}, {"sll (ix+d), c", 0x31}, {"sll (ix+d), d", 0x32}, {"sll (ix+d), e", 0x33}, 
    {"sll (ix+d), h", 0x34}, {"sll (ix+d), l", 0x35}, {"sll (ix+d)", 0x36}, {"sll (ix+d), a", 0x37}, 
    {"srl (ix+d), b", 0x38}, {"srl (ix+d), c", 0x39}, {"srl (ix+d), d", 0x3A}, {"srl (ix+d), e", 0x3B}, 
    {"srl (ix+d), h", 0x3C}, {"srl (ix+d), l", 0x3D}, {"srl (ix+d)", 0x3E}, {"srl (ix+d), a", 0x3F}, 

    {"bit 0, (ix+d)", 0x40}, {"bit 0, (ix+d)", 0x41}, {"bit 0, (ix+d)", 0x42}, {"bit 0, (ix+d)", 0x43}, 
    {"bit 0, (ix+d)", 0x44}, {"bit 0, (ix+d)", 0x45}, {"bit 0, (ix+d)", 0x46}, {"bit 0, (ix+d)", 0x47}, 
    {"bit 1, (ix+d)", 0x48}, {"bit 1, (ix+d)", 0x49}, {"bit 1, (ix+d)", 0x4A}, {"bit 1, (ix+d)", 0x4B}, 
    {"bit 1, (ix+d)", 0x4C}, {"bit 1, (ix+d)", 0x4D}, {"bit 1, (ix+d)", 0x4E}, {"bit 1, (ix+d)", 0x4F}, 

    {"bit 2, (ix+d)", 0x50}, {"bit 2, (ix+d)", 0x51}, {"bit 2, (ix+d)", 0x52}, {"bit 2, (ix+d)", 0x53}, 
    {"bit 2, (ix+d)", 0x54}, {"bit 2, (ix+d)", 0x55}, {"bit 2, (ix+d)", 0x56}, {"bit 2, (ix+d)", 0x57}, 
    {"bit 3, (ix+d)", 0x58}, {"bit 3, (ix+d)", 0x59}, {"bit 3, (ix+d)", 0x5A}, {"bit 3, (ix+d)", 0x5B}, 
    {"bit 3, (ix+d)", 0x5C}, {"bit 3, (ix+d)", 0x5D}, {"bit 3, (ix+d)", 0x5E}, {"bit 3, (ix+d)", 0x5F}, 

    {"bit 4, (ix+d)", 0x60}, {"bit 4, (ix+d)", 0x61}, {"bit 4, (ix+d)", 0x62}, {"bit 4, (ix+d)", 0x63}, 
    {"bit 4, (ix+d)", 0x64}, {"bit 4, (ix+d)", 0x65}, {"bit 4, (ix+d)", 0x66}, {"bit 4, (ix+d)", 0x67}, 
    {"bit 5, (ix+d)", 0x68}, {"bit 5, (ix+d)", 0x69}, {"bit 5, (ix+d)", 0x6A}, {"bit 5, (ix+d)", 0x6B}, 
    {"bit 5, (ix+d)", 0x6C}, {"bit 5, (ix+d)", 0x6D}, {"bit 5, (ix+d)", 0x6E}, {"bit 5, (ix+d)", 0x6F}, 

    {"bit 6, (ix+d)", 0x70}, {"bit 6, (ix+d)", 0x71}, {"bit 6, (ix+d)", 0x72}, {"bit 6, (ix+d)", 0x73}, 
    {"bit 6, (ix+d)", 0x74}, {"bit 6, (ix+d)", 0x75}, {"bit 6, (ix+d)", 0x76}, {"bit 6, (ix+d)", 0x77}, 
    {"bit 7, (ix+d)", 0x78}, {"bit 7, (ix+d)", 0x79}, {"bit 7, (ix+d)", 0x7A}, {"bit 7, (ix+d)", 0x7B}, 
    {"bit 7, (ix+d)", 0x7C}, {"bit 7, (ix+d)", 0x7D}, {"bit 7, (ix+d)", 0x7E}, {"bit 7, (ix+d)", 0x7F}, 

    {"res 0, (ix+d), b", 0x80}, {"res 0, (ix+d), c", 0x81}, {"res 0, (ix+d), d", 0x82}, 
    {"res 0, (ix+d), e", 0x83}, {"res 0, (ix+d), h", 0x84}, {"res 0, (ix+d), l", 0x85}, {"res 0, (ix+d)", 0x86}, 
    {"res 0, (ix+d), a", 0x87}, {"res 1, (ix+d), b", 0x88}, {"res 1, (ix+d), c", 0x89}, 
    {"res 1, (ix+d), d", 0x8A}, {"res 1, (ix+d), e", 0x8B}, {"res 1, (ix+d), h", 0x8C}, 
    {"res 1, (ix+d), l", 0x8D}, {"res 1, (ix+d)", 0x8E}, {"res 1, (ix+d), a", 0x8F}, 
    {"res 2, (ix+d), b", 0x90}, {"res 2, (ix+d), c", 0x91}, {"res 2, (ix+d), d", 0x92}, 
    {"res 2, (ix+d), e", 0x93}, {"res 2, (ix+d), h", 0x94}, {"res 2, (ix+d), l", 0x95}, 
    {"res 2, (ix+d)", 0x96}, {"res 2, (ix+d), a", 0x97}, {"res 3, (ix+d), b", 0x98}, 
    {"res 3, (ix+d), c", 0x99}, {"res 3, (ix+d), d", 0x9A}, {"res 3, (ix+d), e", 0x9B}, 
    {"res 3, (ix+d), h", 0x9C}, {"res 3, (ix+d), l", 0x9D}, {"res 3, (ix+d)", 0x9E}, 
    {"res 3, (ix+d), a", 0x9F}, 

    {"res 4, (ix+d), b", 0xA0}, {"res 4, (ix+d), c", 0xA1}, {"res 4, (ix+d), d", 0xA2}, 
    {"res 4, (ix+d), e", 0xA3}, {"res 4, (ix+d), h", 0xA4}, {"res 4, (ix+d), l", 0xA5}, 
    {"res 4, (ix+d)", 0xA6}, {"res 4, (ix+d), a", 0xA7}, {"res 5, (ix+d), b", 0xA8}, 
    {"res 5, (ix+d), c", 0xA9}, {"res 5, (ix+d), d", 0xAA}, {"res 5, (ix+d), e", 0xAB}, 
    {"res 5, (ix+d), h", 0xAC}, {"res 5, (ix+d), l", 0xAD}, {"res 5, (ix+d)", 0xAE}, 
    {"res 5, (ix+d), a", 0xAF}, 

    {"res 6, (ix+d), b", 0xB0}, {"res 6, (ix+d), c", 0xB1}, {"res 6, (ix+d), d", 0xB2}, 
    {"res 6, (ix+d), e", 0xB3}, {"res 6, (ix+d), h", 0xB4}, {"res 6, (ix+d), l", 0xB5}, 
    {"res 6, (ix+d)", 0xB6}, {"res 6, (ix+d), a", 0xB7}, {"res 7, (ix+d), b", 0xB8}, 
    {"res 7, (ix+d), c", 0xB9}, {"res 7, (ix+d), d", 0xBA}, {"res 7, (ix+d), e", 0xBB}, 
    {"res 7, (ix+d), h", 0xBC}, {"res 7, (ix+d), l", 0xBD}, {"res 7, (ix+d)", 0xBE}, 
    {"res 7, (ix+d), a", 0xBF}, 

    {"set 0, (ix+d), b", 0xC0}, {"set 0, (ix+d), c", 0xC1}, {"set 0, (ix+d), d", 0xC2}, 
    {"set 0, (ix+d), e", 0xC3}, {"set 0, (ix+d), h", 0xC4}, {"set 0, (ix+d), l", 0xC5}, 
    {"set 0, (ix+d)", 0xC6}, {"set 0, (ix+d), a", 0xC7}, {"set 1, (ix+d), b", 0xC8}, 
    {"set 1, (ix+d), c", 0xC9}, {"set 1, (ix+d), d", 0xCA}, {"set 1, (ix+d), e", 0xCB}, 
    {"set 1, (ix+d), h", 0xCC}, {"set 1, (ix+d), l", 0xCD}, {"set 1, (ix+d)", 0xCE}, 
    {"set 1, (ix+d), a", 0xCF}, 

    {"set 2, (ix+d), b", 0xD0}, {"set 2, (ix+d), c", 0xD1}, {"set 2, (ix+d), d", 0xD2}, 
    {"set 2, (ix+d), e", 0xD3}, {"set 2, (ix+d), h", 0xD4}, {"set 2, (ix+d), l", 0xD5}, 
    {"set 2, (ix+d)", 0xD6}, {"set 2, (ix+d), a", 0xD7}, {"set 3, (ix+d), b", 0xD8}, 
    {"set 3, (ix+d), c", 0xD9}, {"set 3, (ix+d), d", 0xDA}, {"set 3, (ix+d), e", 0xDB}, 
    {"set 3, (ix+d), h", 0xDC}, {"set 3, (ix+d), l", 0xDD}, {"set 3, (ix+d)", 0xDE}, 
    {"set 3, (ix+d), a", 0xDF}, 

    {"set 4, (ix+d), b", 0xE0}, {"set 4, (ix+d), c", 0xE1}, {"set 4, (ix+d), d", 0xE2}, 
    {"set 4, (ix+d), e", 0xE3}, {"set 4, (ix+d), h", 0xE4}, {"set 4, (ix+d), l", 0xE5}, 
    {"set 4, (ix+d)", 0xE6}, {"set 4, (ix+d), a", 0xE7}, {"set 5, (ix+d), b", 0xE8}, 
    {"set 5, (ix+d), c", 0xE9}, {"set 5, (ix+d), d", 0xEA}, {"set 5, (ix+d), e", 0xEB}, 
    {"set 5, (ix+d), h", 0xEC}, {"set 5, (ix+d), l", 0xED}, {"set 5, (ix+d)", 0xEE}, 
    {"set 5, (ix+d), a", 0xEF}, 

    {"set 6, (ix+d), b", 0xF0}, {"set 6, (ix+d), c", 0xF1}, {"set 6, (ix+d), d", 0xF2}, 
    {"set 6, (ix+d), e", 0xF3}, {"set 6, (ix+d), h", 0xF4}, {"set 6, (ix+d), l", 0xF5}, 
    {"set 6, (ix+d)", 0xF6}, {"set 6, (ix+d), a", 0xF7}, {"set 7, (ix+d), b", 0xF8}, 
    {"set 7, (ix+d), c", 0xF9}, {"set 7, (ix+d), d", 0xFA}, {"set 7, (ix+d), e", 0xFB}, 
    {"set 7, (ix+d), h", 0xFC}, {"set 7, (ix+d), l", 0xFD}, {"set 7, (ix+d)", 0xFE}, 
    {"set 7, (ix+d), a", 0xFF}
};

// Same shit as cbMap
ubyte[string] edMap = {
    {"in0 b, (n)", 0x40}, {"out0 (n), b", 0x41}, {"tst b", 0x44}, {"in0 c, (n)", 0x48}, 
    {"out0 (n), c", 0x49}, {"tst c", 0x4C}, {"in0 d, (n)", 0x50}, {"out0 (n), d", 0x51}, 
    {"tst d", 0x54}, {"in0 e, (n)", 0x58}, {"out0 (n), e", 0x59}, {"tst e", 0x5C}, 
    {"in0 h, (n)", 0x60}, {"out0 (n), h", 0x61}, {"tst h", 0x64}, {"in0 l, (n)", 0x68}, 
    {"out0 (n), l", 0x69}, {"tst l", 0x6C}, {"tst (hl)", 0x74}, {"in0 a, (n)", 0x78}, 
    {"out0 (n), a", 0x79}, {"tst a", 0x7C}, 

    {"in b, (c)", 0x40}, {"out (c), b", 0x41}, {"sbc hl, bc", 0x42}, {"ld (nn), bc", 0x43}, 
    {"neg", 0x44}, {"retn", 0x45}, {"im 0", 0x46}, {"ld i, a", 0x47}, {"in c, (c)", 0x48}, 
    {"out (c), c", 0x49}, {"adc hl, bc", 0x4A}, {"ld bc, (nn)", 0x4B}, {"mlt bc", 0x4C}, 
    {"reti", 0x4D}, {"ld r, a", 0x4E}, {"in d, (c)", 0x50}, {"out (c), d", 0x51}, {"sbc hl, de", 0x52}, 
    {"ld (nn), de", 0x53}, {"im 1", 0x56}, {"ld a, i", 0x57}, {"in e, (c)", 0x58}, {"out (c), e", 0x59}, 
    {"adc hl, de", 0x5A}, {"ld de, (nn)", 0x5B}, {"mlt de", 0x5C}, {"im 2", 0x5E}, {"ld a, r", 0x5F}, 

    {"in h, (c)", 0x60}, {"out (c), h", 0x61}, {"sbc hl, hl", 0x62}, {"ld (nn), hl", 0x63}, 
    {"tst n", 0x64}, {"rrd", 0x67}, {"in l, (c)", 0x68}, {"out (c), l", 0x69}, {"adc hl, hl", 0x6A}, 
    {"ld hl, (nn)", 0x6B}, {"mlt hl", 0x6C}, {"rld", 0x6F}, {"in (c)", 0x70}, {"out (c), 0", 0x71}, 
    {"sbc hl, sp", 0x72}, {"ld (nn), sp", 0x73}, {"tstio n", 0x74}, {"slp", 0x76}, {"in a, (c)", 0x78}, 
    {"out (c), a", 0x79}, {"adc hl, sp", 0x7A}, {"ld sp, (nn)", 0x7B}, {"mlt sp", 0x7C}, 

    {"otim", 0xED}, {"otdm", 0xED}, {"otimr", 0xED}, {"otdmr", 0xED}, 

    {"ldi", 0xA0}, {"cpi", 0xA1}, {"ini", 0xA2}, {"outi", 0xA3}, {"ldd", 0xA8}, {"cpd", 0xA9}, 
    {"ind", 0xAA}, {"outd", 0xAB}, {"ldir", 0xB0}, {"cpir", 0xB1}, {"inir", 0xB2}, {"otir", 0xB3}
};

// Same shit as cbMap
ubyte[string] fdMap = {
    {"ld iy, nn", 0x21}, {"ld (nn), iy", 0x22}, {"inc iy", 0x23}, {"inc iyh", 0x24}, {"dec iyh", 0x25}, 
    {"ld iyh, n", 0x26}, {"add iy, iy", 0x29}, {"ld iy, (nn)", 0x2A}, {"dec iy", 0x2B}, {"inc iyl", 0x2C}, 
    {"dec iyl", 0x2D}, {"ld iyl, n", 0x2E}, {"inc (iy+d)", 0x34}, {"dec (iy+d)", 0x35}, 
    {"ld (iy+d), n", 0x36}, {"add iy, sp", 0x39}, 

    {"ld b, iyh", 0x44}, {"ld b, iyl", 0x45}, {"ld b, (iy+d)", 0x46}, {"ld c, iyh", 0x4C}, 
    {"ld c, iyl", 0x4D}, {"ld c, (iy+d)", 0x4E}, {"ld d, iyh", 0x54}, {"ld d, iyl", 0x55}, 
    {"ld d, (iy+d)", 0x56}, {"ld e, iyh", 0x5C}, {"ld e, iyl", 0x5D}, {"ld e, (iy+d)", 0x5E},  
    {"ld iyh, b", 0x60}, {"ld iyh, c", 0x61}, {"ld iyh, d", 0x62}, {"ld iyh, e", 0x63}, 
    {"ld iyh, iyh", 0x64}, {"ld iyh, iyl", 0x65}, {"ld h, (iy+d)", 0x66}, {"ld iyh, a", 0x67}, 
    {"ld iyl, b", 0x68}, {"ld iyl, c", 0x69}, {"ld iyl, d", 0x6A}, {"ld iyl, e", 0x6B}, 
    {"ld iyl, iyh", 0x6C}, {"ld iyl, iyl", 0x6D}, {"ld l, (iy+d)", 0x6E}, {"ld iyl, a", 0x6F}, 
    {"ld (iy+d), b", 0x70}, {"ld (iy+d), c", 0x71}, {"ld (iy+d), d", 0x72}, {"ld (iy+d), e", 0x73}, 
    {"ld (iy+d), h", 0x74}, {"ld (iy+d), l", 0x75}, {"ld (iy+d), a", 0x77}, 

    {"ld a, iyh", 0x7C}, {"ld a, iyl", 0x7D}, {"ld a, (iy+d)", 0x7E}, {"add a, iyh", 0x84},  
    {"add a, iyl", 0x85}, {"add a, (iy+d)", 0x86}, {"adc a, iyh", 0x8C}, {"adc a, iyl", 0x8D}, 
    {"adc a, (iy+d)", 0x8E}, {"sub iyh", 0x94}, {"sub iyl", 0x95}, {"sub (iy+d)", 0x96}, 
    {"sbc a, iyh", 0x9C}, {"sbc a, iyl", 0x9D}, {"sbc a, (iy+d)", 0x9E}, {"and iyh", 0xA4}, 
    {"and iyl", 0xA5}, {"and (iy+d)", 0xA6}, {"xor iyh", 0xAC}, {"xor iyl", 0xAD}, 
    {"xor (iy+d)", 0xAE}, {"or iyh", 0xB4}, {"or iyl", 0xB5}, {"or (iy+d)", 0xB6}, 
    {"cp iyh", 0xBC}, {"cp iyl", 0xBD}, {"cp (iy+d)", 0xBE}, 

    {"pop iy", 0xE1}, {"ex (sp), iy", 0xE3}, {"push iy", 0xE5}, {"jp (iy)", 0xE9}
};

// Same shit as cbMap
ubyte[string] fdcbMap = {
    {"rlc (iy+d), b", 0x00}, {"rlc (iy+d), c", 0x01}, {"rlc (iy+d), d", 0x02}, {"rlc (iy+d), e", 0x03}, 
    {"rlc (iy+d), h", 0x04}, {"rlc (iy+d), l", 0x05}, {"rlc (iy+d)", 0x06}, {"rlc (iy+d), a", 0x07},  
    {"rrc (iy+d), b", 0x08}, {"rrc (iy+d), c", 0x09}, {"rrc (iy+d), d", 0x0A}, {"rrc (iy+d), e", 0x0B}, 
    {"rrc (iy+d), h", 0x0C}, {"rrc (iy+d), l", 0x0D}, {"rrc (iy+d)", 0x0E}, {"rrc (iy+d), a", 0x0F}, 

    {"rl (iy+d), b", 0x10}, {"rl (iy+d), c", 0x11}, {"rl (iy+d), d", 0x12}, {"rl (iy+d), e", 0x13}, 
    {"rl (iy+d), h", 0x14}, {"rl (iy+d), l", 0x15}, {"rl (iy+d)", 0x16}, {"rl (iy+d), a", 0x17}, 
    {"rr (iy+d), b", 0x18}, {"rr (iy+d), c", 0x19}, {"rr (iy+d), d", 0x1A}, {"rr (iy+d), e", 0x1B}, 
    {"rr (iy+d), h", 0x1C}, {"rr (iy+d), l", 0x1D}, {"rr (iy+d)", 0x1E}, {"rr (iy+d), a", 0x1F}, 

    {"sla (iy+d), b", 0x20}, {"sla (iy+d), c", 0x21}, {"sla (iy+d), d", 0x22}, {"sla (iy+d), e", 0x23}, 
    {"sla (iy+d), h", 0x24}, {"sla (iy+d), l", 0x25}, {"sla (iy+d)", 0x26}, {"sla (iy+d), a", 0x27}, 
    {"sra (iy+d), b", 0x28}, {"sra (iy+d), c", 0x29}, {"sra (iy+d), d", 0x2A}, {"sra (iy+d), e", 0x2B}, 
    {"sra (iy+d), h", 0x2C}, {"sra (iy+d), l", 0x2D}, {"sra (iy+d)", 0x2E}, {"sra (iy+d), a", 0x2F}, 

    {"sll (iy+d), b", 0x30}, {"sll (iy+d), c", 0x31}, {"sll (iy+d), d", 0x32}, {"sll (iy+d), e", 0x33}, 
    {"sll (iy+d), h", 0x34}, {"sll (iy+d), l", 0x35}, {"sll (iy+d)", 0x36}, {"sll (iy+d), a", 0x37}, 
    {"srl (iy+d), b", 0x38}, {"srl (iy+d), c", 0x39}, {"srl (iy+d), d", 0x3A}, {"srl (iy+d), e", 0x3B}, 
    {"srl (iy+d), h", 0x3C}, {"srl (iy+d), l", 0x3D}, {"srl (iy+d)", 0x3E}, {"srl (iy+d), a", 0x3F}, 

    {"bit 0, (iy+d)", 0x40}, {"bit 0, (iy+d)", 0x41}, {"bit 0, (iy+d)", 0x42}, {"bit 0, (iy+d)", 0x43},  
    {"bit 0, (iy+d)", 0x44}, {"bit 0, (iy+d)", 0x45}, {"bit 0, (iy+d)", 0x46}, {"bit 0, (iy+d)", 0x47}, 
    {"bit 1, (iy+d)", 0x48}, {"bit 1, (iy+d)", 0x49}, {"bit 1, (iy+d)", 0x4A}, {"bit 1, (iy+d)", 0x4B}, 
    {"bit 1, (iy+d)", 0x4C}, {"bit 1, (iy+d)", 0x4D}, {"bit 1, (iy+d)", 0x4E}, {"bit 1, (iy+d)", 0x4F}, 

    {"bit 2, (iy+d)", 0x50}, {"bit 2, (iy+d)", 0x51}, {"bit 2, (iy+d)", 0x52}, {"bit 2, (iy+d)", 0x53}, 
    {"bit 2, (iy+d)", 0x54}, {"bit 2, (iy+d)", 0x55}, {"bit 2, (iy+d)", 0x56}, {"bit 2, (iy+d)", 0x57},  
    {"bit 3, (iy+d)", 0x58}, {"bit 3, (iy+d)", 0x59}, {"bit 3, (iy+d)", 0x5A}, {"bit 3, (iy+d)", 0x5B}, 
    {"bit 3, (iy+d)", 0x5C}, {"bit 3, (iy+d)", 0x5D}, {"bit 3, (iy+d)", 0x5E}, {"bit 3, (iy+d)", 0x5F}, 

    {"bit 4, (iy+d)", 0x60}, {"bit 4, (iy+d)", 0x61}, {"bit 4, (iy+d)", 0x62}, {"bit 4, (iy+d)", 0x63}, 
    {"bit 4, (iy+d)", 0x64}, {"bit 4, (iy+d)", 0x65}, {"bit 4, (iy+d)", 0x66}, {"bit 4, (iy+d)", 0x67}, 
    {"bit 5, (iy+d)", 0x68}, {"bit 5, (iy+d)", 0x69}, {"bit 5, (iy+d)", 0x6A}, {"bit 5, (iy+d)", 0x6B},  
    {"bit 5, (iy+d)", 0x6C}, {"bit 5, (iy+d)", 0x6D}, {"bit 5, (iy+d)", 0x6E}, {"bit 5, (iy+d)", 0x6F}, 

    {"bit 6, (iy+d)", 0x70}, {"bit 6, (iy+d)", 0x71}, {"bit 6, (iy+d)", 0x72}, {"bit 6, (iy+d)", 0x73}, 
    {"bit 6, (iy+d)", 0x74}, {"bit 6, (iy+d)", 0x75}, {"bit 6, (iy+d)", 0x76}, {"bit 6, (iy+d)", 0x77}, 
    {"bit 7, (iy+d)", 0x78}, {"bit 7, (iy+d)", 0x79}, {"bit 7, (iy+d)", 0x7A}, {"bit 7, (iy+d)", 0x7B}, 
    {"bit 7, (iy+d)", 0x7C}, {"bit 7, (iy+d)", 0x7D}, {"bit 7, (iy+d)", 0x7E}, {"bit 7, (iy+d)", 0x7F}, 

    {"res 0, (iy+d), b", 0x80}, {"res 0, (iy+d), c", 0x81}, {"res 0, (iy+d), d", 0x82},  
    {"res 0, (iy+d), e", 0x83}, {"res 0, (iy+d), h", 0x84}, {"res 0, (iy+d), l", 0x85}, {"res 0, (iy+d)", 0x86}, 
    {"res 0, (iy+d), a", 0x87}, {"res 1, (iy+d), b", 0x88}, {"res 1, (iy+d), c", 0x89},  
    {"res 1, (iy+d), d", 0x8A}, {"res 1, (iy+d), e", 0x8B}, {"res 1, (iy+d), h", 0x8C}, 
    {"res 1, (iy+d), l", 0x8D}, {"res 1, (iy+d)", 0x8E}, {"res 1, (iy+d), a", 0x8F}, 

    {"res 2, (iy+d), b", 0x90}, {"res 2, (iy+d), c", 0x91}, {"res 2, (iy+d), d", 0x92}, 
    {"res 2, (iy+d), e", 0x93}, {"res 2, (iy+d), h", 0x94}, {"res 2, (iy+d), l", 0x95}, 
    {"res 2, (iy+d)", 0x96}, {"res 2, (iy+d), a", 0x97}, {"res 3, (iy+d), b", 0x98},  
    {"res 3, (iy+d), c", 0x99}, {"res 3, (iy+d), d", 0x9A}, {"res 3, (iy+d), e", 0x9B}, 
    {"res 3, (iy+d), h", 0x9C}, {"res 3, (iy+d), l", 0x9D}, {"res 3, (iy+d)", 0x9E}, 
    {"res 3, (iy+d), a", 0x9F}, 

    {"res 4, (iy+d), b", 0xA0}, {"res 4, (iy+d), c", 0xA1}, {"res 4, (iy+d), d", 0xA2}, 
    {"res 4, (iy+d), e", 0xA3}, {"res 4, (iy+d), h", 0xA4}, {"res 4, (iy+d), l", 0xA5}, 
    {"res 4, (iy+d)", 0xA6}, {"res 4, (iy+d), a", 0xA7}, {"res 5, (iy+d), b", 0xA8}, 
    {"res 5, (iy+d), c", 0xA9}, {"res 5, (iy+d), d", 0xAA}, {"res 5, (iy+d), e", 0xAB},  
    {"res 5, (iy+d), h", 0xAC}, {"res 5, (iy+d), l", 0xAD}, {"res 5, (iy+d)", 0xAE}, 
    {"res 5, (iy+d), a", 0xAF}, 

    {"res 6, (iy+d), b", 0xB0}, {"res 6, (iy+d), c", 0xB1}, {"res 6, (iy+d), d", 0xB2}, 
    {"res 6, (iy+d), e", 0xB3}, {"res 6, (iy+d), h", 0xB4}, {"res 6, (iy+d), l", 0xB5}, 
    {"res 6, (iy+d)", 0xB6}, {"res 6, (iy+d), a", 0xB7}, {"res 7, (iy+d), b", 0xB8}, 
    {"res 7, (iy+d), c", 0xB9}, {"res 7, (iy+d), d", 0xBA}, {"res 7, (iy+d), e", 0xBB},  
    {"res 7, (iy+d), h", 0xBC}, {"res 7, (iy+d), l", 0xBD}, {"res 7, (iy+d)", 0xBE}, 
    {"res 7, (iy+d), a", 0xBF}, 

    {"set 0, (iy+d), b", 0xC0}, {"set 0, (iy+d), c", 0xC1}, {"set 0, (iy+d), d", 0xC2}, 
    {"set 0, (iy+d), e", 0xC3}, {"set 0, (iy+d), h", 0xC4}, {"set 0, (iy+d), l", 0xC5}, 
    {"set 0, (iy+d)", 0xC6}, {"set 0, (iy+d), a", 0xC7}, {"set 1, (iy+d), b", 0xC8},  
    {"set 1, (iy+d), c", 0xC9}, {"set 1, (iy+d), d", 0xCA}, {"set 1, (iy+d), e", 0xCB}, 
    {"set 1, (iy+d), h", 0xCC}, {"set 1, (iy+d), l", 0xCD}, {"set 1, (iy+d)", 0xCE}, 
    {"set 1, (iy+d), a", 0xCF}, 

    {"set 2, (iy+d), b", 0xD0}, {"set 2, (iy+d), c", 0xD1}, {"set 2, (iy+d), d", 0xD2}, 
    {"set 2, (iy+d), e", 0xD3}, {"set 2, (iy+d), h", 0xD4}, {"set 2, (iy+d), l", 0xD5}, 
    {"set 2, (iy+d)", 0xD6}, {"set 2, (iy+d), a", 0xD7}, {"set 3, (iy+d), b", 0xD8},  
    {"set 3, (iy+d), c", 0xD9}, {"set 3, (iy+d), d", 0xDA}, {"set 3, (iy+d), e", 0xDB}, 
    {"set 3, (iy+d), h", 0xDC}, {"set 3, (iy+d), l", 0xDD}, {"set 3, (iy+d)", 0xDE}, 
    {"set 3, (iy+d), a", 0xDF}, 

    {"set 4, (iy+d), b", 0xE0}, {"set 4, (iy+d), c", 0xE1}, {"set 4, (iy+d), d", 0xE2},  
    {"set 4, (iy+d), e", 0xE3}, {"set 4, (iy+d), h", 0xE4}, {"set 4, (iy+d), l", 0xE5}, 
    {"set 4, (iy+d)", 0xE6}, {"set 4, (iy+d), a", 0xE7}, {"set 5, (iy+d), b", 0xE8}, 
    {"set 5, (iy+d), c", 0xE9}, {"set 5, (iy+d), d", 0xEA}, {"set 5, (iy+d), e", 0xEB}, 
    {"set 5, (iy+d), h", 0xEC}, {"set 5, (iy+d), l", 0xED}, {"set 5, (iy+d)", 0xEE}, 
    {"set 5, (iy+d), a", 0xEF}, 

    {"set 6, (iy+d), b", 0xF0}, {"set 6, (iy+d), c", 0xF1}, {"set 6, (iy+d), d", 0xF2}, 
    {"set 6, (iy+d), e", 0xF3}, {"set 6, (iy+d), h", 0xF4}, {"set 6, (iy+d), l", 0xF5}, 
    {"set 6, (iy+d)", 0xF6}, {"set 6, (iy+d), a", 0xF7}, {"set 7, (iy+d), b", 0xF8}, 
    {"set 7, (iy+d), c", 0xF9}, {"set 7, (iy+d), d", 0xFA}, {"set 7, (iy+d), e", 0xFB}, 
    {"set 7, (iy+d), h", 0xFC}, {"set 7, (iy+d), l", 0xFD}, {"set 7, (iy+d)", 0xFE}, 
    {"set 7, (iy+d), a", 0xFF}
};

public template asm80(string[] tokenList)
{
    private void lexLikeLuthor()
    {

    }

    private string parse()
    {
        if (opcode > OpCode.slp)
            throw new Exception("Assembler encountered invalid Z80 opcode '"~opcode~"'");
        
        foreach (string tokenLine; tokenList)
        {
            string[] tokens = tokenLine.split(" ");

            if (tokens.Length == 0)
                continue;

            
        }
    }

    public const string asm80 = parse();
}