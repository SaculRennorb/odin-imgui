// BEGIN STD SHIM

typedef unsigned long long int size_t;
typedef unsigned short int wchar_t;

typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long int uint64_t;

typedef signed char int8_t;
typedef signed short int int16_t;
typedef signed int int32_t;
typedef signed long long int int64_t;

int strlen(char*);
int strcmp(const char* lhs, const char* rhs);
int memcmp(const void* lhs, const void* rhs, size_t count);
int strncmp(const char* lhs, const char* rhs, size_t count);
int fseek(void* stream, long offset, int origin);
int fclose(void* stream);

int WEXITSTATUS(int a);

int offsetof(void* ex);
int sizeof(void* ex);

// END STD SHIM

// BEGIN STB SHIM

typedef int stbrp_coord;

struct stbrp_rect
{
   int            id;
   stbrp_coord    w, h;
   stbrp_coord    x, y;
   int            was_packed;
};

struct stbrp_node
{
   stbrp_coord  x,y;
   stbrp_node  *next;
};

struct stbrp_context
{
   int width;
   int height;
   int align;
   int init_mode;
   int heuristic;
   int num_nodes;
   stbrp_node *active_head;
   stbrp_node *free_head;
   stbrp_node extra[2]; // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
};


struct stbtt_aligned_quad
{
   float x0,y0,s0,t0;
   float x1,y1,s1,t1;
};


struct stbtt_packedchar
{
   unsigned short x0,y0,x1,y1;
   float xoff,yoff,xadvance;
   float xoff2,yoff2;
};

struct stbtt_pack_range
{
   float font_size;
   int first_unicode_codepoint_in_range;
   int *array_of_unicode_codepoints;
   int num_chars;
   stbtt_packedchar *chardata_for_range;
   unsigned char h_oversample, v_oversample;
};

struct stbtt__buf
{
   unsigned char *data;
   int cursor;
   int size;
};

struct stbtt_fontinfo
{
   void           * userdata;
   unsigned char  * data;              // pointer to .ttf file
   int              fontstart;         // offset of start of font

   int numGlyphs;                     // number of glyphs, needed for range checking

   int loca,head,glyf,hhea,hmtx,kern,gpos,svg; // table locations as offset from start of .ttf
   int index_map;                     // a cmap mapping for our chosen character encoding
   int indexToLocFormat;              // format needed to map from glyph index to glyph

   stbtt__buf cff;                    // cff font data
   stbtt__buf charstrings;            // the charstring index
   stbtt__buf gsubrs;                 // global charstring subroutines index
   stbtt__buf subrs;                  // private charstring subroutines index
   stbtt__buf fontdicts;              // array of font dicts
   stbtt__buf fdselect;               // map from glyph to fontdict
};

struct stbtt_pack_context {
   void *user_allocator_context;
   void *pack_info;
   int   width;
   int   height;
   int   stride_in_bytes;
   int   padding;
   int   skip_missing;
   unsigned int   h_oversample, v_oversample;
   unsigned char *pixels;
   void  *nodes;
};

namespace ImStb
{
   // need to forward declare some vars
   static char STB_TEXTEDIT_NEWLINE = '\n';
   
#define STB_TEXTEDIT_K_INSERT 0
#define STB_TEXTEDIT_K_TEXTSTART2 0
#define STB_TEXTEDIT_K_TEXTEND2 0
#define STB_TEXTEDIT_K_LINESTART2 0
#define STB_TEXTEDIT_K_LINEEND2 0

#define STB_TEXTEDIT_K_LEFT         0x200000 // keyboard input to move cursor left
#define STB_TEXTEDIT_K_RIGHT        0x200001 // keyboard input to move cursor right
#define STB_TEXTEDIT_K_UP           0x200002 // keyboard input to move cursor up
#define STB_TEXTEDIT_K_DOWN         0x200003 // keyboard input to move cursor down
#define STB_TEXTEDIT_K_LINESTART    0x200004 // keyboard input to move cursor to start of line
#define STB_TEXTEDIT_K_LINEEND      0x200005 // keyboard input to move cursor to end of line
#define STB_TEXTEDIT_K_TEXTSTART    0x200006 // keyboard input to move cursor to start of text
#define STB_TEXTEDIT_K_TEXTEND      0x200007 // keyboard input to move cursor to end of text
#define STB_TEXTEDIT_K_DELETE       0x200008 // keyboard input to delete selection or character under cursor
#define STB_TEXTEDIT_K_BACKSPACE    0x200009 // keyboard input to delete selection or character left of cursor
#define STB_TEXTEDIT_K_UNDO         0x20000A // keyboard input to perform undo
#define STB_TEXTEDIT_K_REDO         0x20000B // keyboard input to perform redo
#define STB_TEXTEDIT_K_WORDLEFT     0x20000C // keyboard input to move cursor left one word
#define STB_TEXTEDIT_K_WORDRIGHT    0x20000D // keyboard input to move cursor right one word
#define STB_TEXTEDIT_K_PGUP         0x20000E // keyboard input to move cursor up a page
#define STB_TEXTEDIT_K_PGDOWN       0x20000F // keyboard input to move cursor down a page
#define STB_TEXTEDIT_K_SHIFT        0x400000
}

int stbtt_InitFont(stbtt_fontinfo *info, const unsigned char *data, int offset);
int stbtt_FindGlyphIndex(const stbtt_fontinfo *info, int unicode_codepoint);

static bool STB_TEXTEDIT_INSERTCHARS(void* obj, int pos, const char* new_text, int new_text_len);

static bool STB_TEXTEDIT_IS_SPACE(char c); // not actually used, but the type inference gets sad if its not defined.

// END STB SHIM

// BEGIN WIN32 STRUCT SHIM

typedef void* FILE;
typedef void* HANDLE;
typedef HANDLE HWND;
typedef unsigned int DWORD;
typedef int LONG;
typedef unsigned short WCHAR;

struct POINT {
	LONG x, y;
};

struct RECT {
	LONG left, top, right, bottom;
};

struct COMPOSITIONFORM {
	DWORD dwStyle;
	POINT ptCurrentPos;
	RECT  rcArea;
};

struct CANDIDATEFORM {
	DWORD dwIndex;
	DWORD dwStyle;
	POINT ptCurrentPos;
	RECT  rcArea;
};

bool OpenClipboard(HWND hWndNewOwner);

// END WIN32 STRUCT SHIM
