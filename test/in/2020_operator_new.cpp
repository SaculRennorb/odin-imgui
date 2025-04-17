struct A2020 {};
inline void* operator new(size_t, A2020, void* ptr) { return ptr; }
inline void  operator delete(void*, A2020, void*)   {}
