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

// END STD SHIM

// BEGIN WIN32 STRUCT SHIM

typedef void* HANDLE;
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
// END WIN32 STRUCT SHIM
