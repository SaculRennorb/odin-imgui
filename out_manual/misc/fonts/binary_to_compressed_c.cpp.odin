package imgui

// dear imgui
// (binary_to_compressed_c.cpp)
// Helper tool to turn a file into a C array, if you want to embed font data in your source code.

// The data is first compressed with stb_compress() to reduce source code size.
// Then stored in a C array:
// - Base85:   ~5 bytes of source code for 4 bytes of input data. 5 bytes stored in binary (suggested by @mmalex).
// - As int:  ~11 bytes of source code for 4 bytes of input data. 4 bytes stored in binary. Endianness dependant, need swapping on big-endian CPU.
// - As char: ~12 bytes of source code for 4 bytes of input data. 4 bytes stored in binary. Not endianness dependant.
// Load compressed TTF fonts with ImGui::GetIO().Fonts.AddFontFromMemoryCompressedTTF()

// Build with, e.g:
//   # cl.exe binary_to_compressed_c.cpp
//   # g++ binary_to_compressed_c.cpp
//   # clang++ binary_to_compressed_c.cpp
// You can also find a precompiled Windows binary in the binary/demo package available from https://github.com/ocornut/imgui

// Usage:
//   binary_to_compressed_c.exe [-nocompress] [-nostatic] [-base85] <inputfile> <symbolname>
// Usage example:
//   # binary_to_compressed_c.exe myfont.ttf MyFont > myfont.cpp
//   # binary_to_compressed_c.exe -base85 myfont.ttf MyFont > myfont.cpp
// Note:
//   Base85 encoding will be obsoleted by future version of Dear ImGui!

_CRT_SECURE_NO_WARNINGS :: true

// stb_compress* from stb.h - declaration
stb_uint :: u32
stb_uchar :: u8
stb_uint stb_compress(stb_uchar* out, stb_uchar* in, stb_uint len);

SourceEncoding :: enum i32
{
    U8,      // New default since 2024/11
    U32,
    Base85,
};

bool binary_to_compressed_c(const u8* filename, const u8* symbol, SourceEncoding source_encoding, bool use_compression, bool use_static);

main :: proc(argc : i32, argv : ^^u8) -> i32
{
    if (argc < 3)
    {
        printf("Syntax: %s [-u8|-u32|-base85] [-nocompress] [-nostatic] <inputfile> <symbolname>\n", argv[0]);
        printf("Source encoding types:\n");
        printf(" -u8     = ~12 bytes of source per 4 bytes of data. 4 bytes in binary.\n");
        printf(" -u32    = ~11 bytes of source per 4 bytes of data. 4 bytes in binary. Need endianness swapping on big-endian.\n");
        printf(" -base85 =  ~5 bytes of source per 4 bytes of data. 5 bytes in binary. Need decoder.\n");
        return 0;
    }

    argn := 1;
    use_compression := true;
    use_static := true;
    source_encoding := SourceEncoding_U8; // New default
    for (argn < (argc - 2) && argv[argn][0] == '-')
    {
        if (strcmp(argv[argn], "-u8") == 0) { source_encoding = SourceEncoding_U8; argn += 1; }
        else if (strcmp(argv[argn], "-u32") == 0) { source_encoding = SourceEncoding_U32; argn += 1; }
        else if (strcmp(argv[argn], "-base85") == 0) { source_encoding = SourceEncoding_Base85; argn += 1; }
        else if (strcmp(argv[argn], "-nocompress") == 0) { use_compression = false; argn += 1; }
        else if (strcmp(argv[argn], "-nostatic") == 0) { use_static = false; argn += 1; }
        else
        {
            fprintf(stderr, "Unknown argument: '%s'\n", argv[argn]);
            return 1;
        }
    }

    ret := binary_to_compressed_c(argv[argn], argv[argn + 1], source_encoding, use_compression, use_static);
    if (!ret) {
        fprintf(stderr, "Error opening or reading file: '%s'\n", argv[argn]);
    }

    return ret ? 0 : 1;
}

Encode85Byte :: proc(x : u32) -> u8
{
    x = (x % 85) + 35;
    return (u8)((x >= '\\') ? x + 1 : x);
}

binary_to_compressed_c :: proc(filename : ^u8, symbol : ^u8, source_encoding : SourceEncoding, use_compression : bool, use_static : bool) -> bool
{
    // Read file
    f := fopen(filename, "rb");
    if (!f) return false;
    data_sz : i32
    if (fseek(f, 0, SEEK_END) || (data_sz = cast(i32) ftell(f)) == -1 || fseek(f, 0, SEEK_SET)) { fclose(f); return false; }
    data := new u8[data_sz + 4];
    if (fread(data, 1, data_sz, f) != cast(int) data_sz) { fclose(f); delete[] data; return false; }
    memset((rawptr)(((u8*)data) + data_sz), 0, 4);
    fclose(f);

    // Compress
    maxlen := data_sz + 512 + (data_sz >> 2) + size_of(i32); // total guess
    compressed := use_compression ? new u8[maxlen] : data;
    compressed_sz := use_compression ? stb_compress((stb_uchar*)compressed, (stb_uchar*)data, data_sz) : data_sz;
    if (use_compression) {
        memset(compressed + compressed_sz, 0, maxlen - compressed_sz);
    }

    // Output as Base85 encoded
    out := stdout;
    fprintf(out, "// File: '%s' (%d bytes)\n", filename, cast(int) data_sz);
    static_str := use_static ? "static " : "";
    compressed_str := use_compression ? "compressed_" : "";
    if (source_encoding == SourceEncoding_Base85)
    {
        fprintf(out, "// Exported using binary_to_compressed_c.exe -base85 \"%s\" %s\n", filename, symbol);
        fprintf(out, "%sconst u8 %s_%sdata_base85[%d+1] =\n    \"", static_str, symbol, compressed_str, (i32)((compressed_sz + 3) / 4)*5);
        prev_c := 0;
        for src_i := 0; src_i < compressed_sz; src_i += 4
        {
            // This is made a little more complicated by the fact that ??X sequences are interpreted as trigraphs by old C/C++ compilers. So we need to escape pairs of ??.
            d := *(u32*)(compressed + src_i);
            for u32 n5 = 0; n5 < 5; n5++, d /= 85
            {
                c := Encode85Byte(d);
                fprintf(out, (c == '?' && prev_c == '?') ? "\\%c" : "%c", c);
                prev_c = c;
            }
            if ((src_i % 112) == 112 - 4) {
                fprintf(out, "\"\n    \"");
            }

        }
        fprintf(out, "\";\n\n");
    }
    else if (source_encoding == SourceEncoding_U8)
    {
        // As individual bytes, not subject to endianness issues.
        fprintf(out, "// Exported using binary_to_compressed_c.exe -u8 \"%s\" %s\n", filename, symbol);
        fprintf(out, "%sconst u32 %s_%ssize = %d;\n", static_str, symbol, compressed_str, cast(i32) compressed_sz);
        fprintf(out, "%sconst u8 %s_%sdata[%d] =\n{", static_str, symbol, compressed_str, cast(i32) compressed_sz);
        column := 0;
        for i := 0; i < compressed_sz; i += 1
        {
            d := *(u8*)(compressed + i);
            if (column == 0)   do fprintf(out, "\n    ")
            column += fprintf(out, "%d,", d);
            if (column >= 180)   do column = 0
        }
        fprintf(out, "\n};\n\n");
    }
    else if (source_encoding == SourceEncoding_U32)
    {
        // As integers
        fprintf(out, "// Exported using binary_to_compressed_c.exe -u32 \"%s\" %s\n", filename, symbol);
        fprintf(out, "%sconst u32 %s_%ssize = %d;\n", static_str, symbol, compressed_str, cast(i32) compressed_sz);
        fprintf(out, "%sconst u32 %s_%sdata[%d/4] =\n{", static_str, symbol, compressed_str, (i32)((compressed_sz + 3) / 4)*4);
        column := 0;
        for i := 0; i < compressed_sz; i += 4
        {
            d := *(u32*)(compressed + i);
            if ((column++ % 14) == 0) {
                fprintf(out, "\n    0x%08x, ", d);
            }

            else
                fprintf(out, "0x%08x, ", d);
        }
        fprintf(out, "\n};\n\n");
    }

    // Cleanup
    delete[] data;
    if (use_compression)   do delete[] compressed
    return true;
}

// stb_compress* from stb.h - definition

////////////////////           compressor         ///////////////////////

stb_adler32 :: proc(adler32 : stb_uint, stb_uchar *buffer, buflen : stb_uint) -> stb_uint
{
    const unsigned long ADLER_MOD = 65521;
    unsigned long s1 = adler32 & 0xffff, s2 = adler32 >> 16;
    unsigned long blocklen, i;

    blocklen = buflen % 5552;
    for (buflen) {
        for (i=0; i + 7 < blocklen; i += 8) {
            s1 += buffer[0], s2 += s1;
            s1 += buffer[1], s2 += s1;
            s1 += buffer[2], s2 += s1;
            s1 += buffer[3], s2 += s1;
            s1 += buffer[4], s2 += s1;
            s1 += buffer[5], s2 += s1;
            s1 += buffer[6], s2 += s1;
            s1 += buffer[7], s2 += s1;

            buffer += 8;
        }

        for ; i < blocklen; ++i
            s1 += *buffer++, s2 += s1;

        s1 %= ADLER_MOD, s2 %= ADLER_MOD;
        buflen -= blocklen;
        blocklen = 5552;
    }
    return (s2 << 16) + s1;
}

stb_matchlen :: proc(stb_uchar *m1, stb_uchar *m2, maxlen : stb_uint) -> u32
{
    i : stb_uint
    for i=0; i < maxlen; ++i
        if (m1[i] != m2[i]) return i;
    return i;
}

// simple implementation that just takes the source data in a big block

stb_uchar *stb__out;
FILE      *stb__outfile;
stb__outbytes : stb_uint

stb__write :: proc(v : u8)
{
    fputc(v, stb__outfile);
    ++stb__outbytes;
}

//#define stb_out(v)    (stb__out ? *stb__out++ = (stb_uchar) (v) : stb__write((stb_uchar) (v)))
#define stb_out(v)    do { if (stb__out) *stb__out++ = (stb_uchar) (v); else stb__write((stb_uchar) (v)); } while (0)

void stb_out2(stb_uint v) { stb_out(v >> 8); stb_out(v); }
void stb_out3(stb_uint v) { stb_out(v >> 16); stb_out(v >> 8); stb_out(v); }
void stb_out4(stb_uint v) { stb_out(v >> 24); stb_out(v >> 16); stb_out(v >> 8 ); stb_out(v); }

outliterals :: proc(stb_uchar *in, numlit : i32)
{
    for (numlit > 65536) {
        outliterals(in,65536);
        in     += 65536;
        numlit -= 65536;
    }

    if      (numlit ==     0)    ;
    else if (numlit <=    32)    stb_out (0x000020 + numlit-1);
    else if (numlit <=  2048)    stb_out2(0x000800 + numlit-1);
    else /*  numlit <= 65536) */ stb_out3(0x070000 + numlit-1);

    if (stb__out) {
        memcpy(stb__out,in,numlit);
        stb__out += numlit;
    } else
        fwrite(in, 1, numlit, stb__outfile);
}

i32 stb__window = 0x40000; // 256K

stb_not_crap :: proc(best : i32, dist : i32) -> i32
{
    return   ((best > 2  &&  dist <= 0x00100)
        || (best > 5  &&  dist <= 0x04000)
        || (best > 7  &&  dist <= 0x80000));
}

 stb__hashsize := 32768;

// note that you can play with the hashing functions all you
// want without needing to change the decompressor
#define stb__hc(q,h,c)      (((h) << 7) + ((h) >> 25) + q[c])
#define stb__hc2(q,h,c,d)   (((h) << 14) + ((h) >> 18) + (q[c] << 7) + q[d])
#define stb__hc3(q,c,d,e)   ((q[c] << 14) + (q[d] << 7) + q[e])

stb__running_adler : u32

i32 stb_compress_chunk(stb_uchar *history,
    stb_uchar *start,
    stb_uchar *end,
    i32 length,
    i32 *pending_literals,
    stb_uchar **chash,
    stb_uint mask)
{
    (void)history;
    window := stb__window;
    match_max : stb_uint
    stb_uchar *lit_start = start - *pending_literals;
    stb_uchar *q = start;

#define STB__SCRAMBLE(h)   (((h) + ((h) >> 16)) & mask)

    // stop short of the end so we don't scan off the end doing
    // the hashing; this means we won't compress the last few bytes
    // unless they were part of something longer
    for (q < start+length && q+12 < end) {
        m : i32
        h1,h2,h3,h4, h : stb_uint
        stb_uchar *t;
        best := 2, dist=0;

        if (q+65536 > end) {
            match_max = (stb_uint)(end-q);
        }

        else
            match_max = 65536;

#define stb__nc(b,d)  ((d) <= window && ((b) > 9 || stb_not_crap((int)(b),(int)(d))))

#define STB__TRY(t,p)  /* avoid retrying a match we already tried */ \
    if (p ? dist != (i32)(q-t) : 1)                             \
    if ((m = stb_matchlen(t, q, match_max)) > best)     \
    if (stb__nc(m,q-(t)))                                \
    best = m, dist = (i32)(q - (t))

        // rather than search for all matches, only try 4 candidate locations,
        // chosen based on 4 different hash functions of different lengths.
        // this strategy is inspired by LZO; hashing is unrolled here using the
        // 'hc' macro
        h = stb__hc3(q,0, 1, 2); h1 = STB__SCRAMBLE(h);
        t = chash[h1]; if (t) STB__TRY(t,0);
        h = stb__hc2(q,h, 3, 4); h2 = STB__SCRAMBLE(h);
        h = stb__hc2(q,h, 5, 6);        t = chash[h2]; if (t) STB__TRY(t,1);
        h = stb__hc2(q,h, 7, 8); h3 = STB__SCRAMBLE(h);
        h = stb__hc2(q,h, 9,10);        t = chash[h3]; if (t) STB__TRY(t,1);
        h = stb__hc2(q,h,11,12); h4 = STB__SCRAMBLE(h);
        t = chash[h4]; if (t) STB__TRY(t,1);

        // because we use a shared hash table, can only update it
        // _after_ we've probed all of them
        chash[h1] = chash[h2] = chash[h3] = chash[h4] = q;

        if (best > 2)   do assert(dist > 0)

        // see if our best match qualifies
        if (best < 3) { // fast path literals
            ++q;
        } else if (best > 2  &&  best <= 0x80    &&  dist <= 0x100) {
            outliterals(lit_start, (i32)(q-lit_start)); lit_start = (q += best);
            stb_out(0x80 + best-1);
            stb_out(dist-1);
        } else if (best > 5  &&  best <= 0x100   &&  dist <= 0x4000) {
            outliterals(lit_start, (i32)(q-lit_start)); lit_start = (q += best);
            stb_out2(0x4000 + dist-1);
            stb_out(best-1);
        } else if (best > 7  &&  best <= 0x100   &&  dist <= 0x80000) {
            outliterals(lit_start, (i32)(q-lit_start)); lit_start = (q += best);
            stb_out3(0x180000 + dist-1);
            stb_out(best-1);
        } else if (best > 8  &&  best <= 0x10000 &&  dist <= 0x80000) {
            outliterals(lit_start, (i32)(q-lit_start)); lit_start = (q += best);
            stb_out3(0x100000 + dist-1);
            stb_out2(best-1);
        } else if (best > 9                      &&  dist <= 0x1000000) {
            if (best > 65536) best = 65536;
            outliterals(lit_start, (i32)(q-lit_start)); lit_start = (q += best);
            if (best <= 0x100) {
                stb_out(0x06);
                stb_out3(dist-1);
                stb_out(best-1);
            } else {
                stb_out(0x04);
                stb_out3(dist-1);
                stb_out2(best-1);
            }
        } else {  // fallback literals if no match was a balanced tradeoff
            ++q;
        }
    }

    // if we didn't get all the way, add the rest to literals
    if (q-start < length)   do q = start+length

    // the literals are everything from lit_start to q
    pending_literals^ = (i32)(q - lit_start);

    stb__running_adler = stb_adler32(stb__running_adler, start, (stb_uint)(q - start));
    return (i32)(q - start);
}

stb_compress_inner :: proc(stb_uchar *input, length : stb_uint) -> i32
{
    literals := 0;
    len,i : stb_uint

    stb_uchar **chash;
    chash = (stb_uchar**) malloc(stb__hashsize * size_of(stb_uchar*));
    if (chash == nullptr) return 0; // failure
    for i=0; i < stb__hashsize; ++i
        chash[i] = nullptr;

    // stream signature
    stb_out(0x57); stb_out(0xbc);
    stb_out2(0);

    stb_out4(0);       // 64-bit length requires 32-bit leading 0
    stb_out4(length);
    stb_out4(stb__window);

    stb__running_adler = 1;

    len = stb_compress_chunk(input, input, input+length, length, &literals, chash, stb__hashsize-1);
    assert(len == length);

    outliterals(input+length - literals, literals);

    free(chash);

    stb_out2(0x05fa); // end opcode

    stb_out4(stb__running_adler);

    return 1; // success
}

stb_compress :: proc(stb_uchar *out, stb_uchar *input, length : stb_uint) -> stb_uint
{
    stb__out = out;
    stb__outfile = nullptr;

    stb_compress_inner(input, length);

    return (stb_uint)(stb__out - out);
}
