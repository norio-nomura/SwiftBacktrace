#include <cxxabi.h>
#include <dlfcn.h>
#include "CSwiftBacktrace.h"

char* _Nullable cxx_demangle(const char* _Nonnull mangledName,
                             char* _Nullable outputBuffer,
                             size_t* _Nullable outputBufferSize,
                             int* status)
{
    return abi::__cxa_demangle(mangledName, outputBuffer, outputBufferSize, status);
}

const char* _Nullable dli_fname(const void* _Null_unspecified addr) {
    Dl_info info;
    return dladdr(addr, &info) ? info.dli_fname : NULL;
}

int cswift_backtrace_anchor() {
    return 0;
}
