#define __OSX_AVAILABLE_STARTING(_osx, _ios)
#include "libunwind.h"

#if defined __i386__
#define UNW_TARGET      x86

typedef enum
{
    UNW_X86_EIP = 8,        /* frame-register */

    UNW_TDEP_IP = UNW_X86_EIP,
    UNW_TDEP_SP = UNW_X86_ESP,
    UNW_TDEP_EH = UNW_X86_EAX
}
x86_regnum_t;


#elif defined __x86_64__
#define UNW_TARGET              x86_64

typedef enum
{
    UNW_X86_64_RIP = 16,

    UNW_TDEP_IP = UNW_X86_64_RIP,
    UNW_TDEP_SP = UNW_X86_64_RSP,
    UNW_TDEP_BP = UNW_X86_64_RBP,
    UNW_TDEP_EH = UNW_X86_64_RAX
}
x86_64_regnum_t;

#else
# error "Unsupported arch"
#endif

#define UNW_LOCAL_ONLY

#define UNW_PASTE2(x,y)    x##y
#define UNW_PASTE(x,y)    UNW_PASTE2(x,y)
#define UNW_OBJ(fn)    UNW_PASTE(UNW_PREFIX, fn)
#define UNW_ARCH_OBJ(fn) UNW_PASTE(UNW_PASTE(UNW_PASTE(_U,UNW_TARGET),_), fn)

#ifdef UNW_LOCAL_ONLY
# define UNW_PREFIX    UNW_PASTE(UNW_PASTE(_UL,UNW_TARGET),_)
#else /* !UNW_LOCAL_ONLY */
# define UNW_PREFIX    UNW_PASTE(UNW_PASTE(_U,UNW_TARGET),_)
#endif /* !UNW_LOCAL_ONLY */
