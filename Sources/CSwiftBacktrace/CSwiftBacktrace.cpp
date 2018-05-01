#include <dlfcn.h>
#include "CSwiftBacktrace.h"

const char* _Nullable dli_fname(const void* _Null_unspecified addr) {
    Dl_info info;
    return dladdr(addr, &info) ? info.dli_fname : NULL;
}

int cswift_backtrace_anchor() {
    return 0;
}
