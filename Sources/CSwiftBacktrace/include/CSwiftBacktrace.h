#include <stddef.h>
#include <stdint.h>
#include <execinfo.h>

#ifdef __cplusplus
extern "C" {
#endif

// Calls dladdr(3) and returns `Dl_info.dli_fname`
const char* _Nullable dli_fname(const void* _Null_unspecified addr);

// demangle c++ mangled name by using `abi::__cxa_demangle()`
char* _Nullable cxx_demangle(const char* _Nonnull mangledName,
                                   char* _Nullable outputBuffer,
                                   size_t* _Nullable outputBufferSize,
                                   int* _Nullable status);

// `swift_demangle` is implemented in libswiftCore
extern char* _Nullable swift_demangle(const char* _Nonnull mangledName,
                                     size_t mangledNameLength,
                                     char* _Nullable outputBuffer,
                                     size_t* _Nullable outputBufferSize,
                                     uint32_t flags);

#ifdef __cplusplus
} // extern "C"
#endif
