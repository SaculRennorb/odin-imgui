// BEGIN WIN32 STRUCT SHIM

typedef unsigned int DWORD;
typedef int LONG;

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
