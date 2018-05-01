#define __OSX_AVAILABLE_STARTING(_osx, _ios)
#include "libunwind.h"

#if defined __x86_64__

#define UNW_LOCAL_ONLY
#define UNW_TARGET              x86_64

#define UNW_PASTE2(x,y)    x##y
#define UNW_PASTE(x,y)    UNW_PASTE2(x,y)
#define UNW_OBJ(fn)    UNW_PASTE(UNW_PREFIX, fn)
#define UNW_ARCH_OBJ(fn) UNW_PASTE(UNW_PASTE(UNW_PASTE(_U,UNW_TARGET),_), fn)

#ifdef UNW_LOCAL_ONLY
# define UNW_PREFIX    UNW_PASTE(UNW_PASTE(_UL,UNW_TARGET),_)
#else /* !UNW_LOCAL_ONLY */
# define UNW_PREFIX    UNW_PASTE(UNW_PASTE(_U,UNW_TARGET),_)
#endif /* !UNW_LOCAL_ONLY */

extern int         UNW_ARCH_OBJ(getcontext)(unw_context_t*);
extern int         UNW_OBJ(init_local)(unw_cursor_t*, unw_context_t*);
extern int         UNW_OBJ(step)(unw_cursor_t*);
extern int         UNW_OBJ(get_reg)(unw_cursor_t*, unw_regnum_t, unw_word_t*);
extern int         UNW_OBJ(get_fpreg)(unw_cursor_t*, unw_regnum_t, unw_fpreg_t*);
extern int         UNW_OBJ(set_reg)(unw_cursor_t*, unw_regnum_t, unw_word_t);
extern int         UNW_OBJ(set_fpreg)(unw_cursor_t*, unw_regnum_t, unw_fpreg_t);
extern int         UNW_OBJ(resume)(unw_cursor_t*);

extern const char* UNW_ARCH_OBJ(regname)(unw_cursor_t*, unw_regnum_t);
extern int         UNW_OBJ(get_proc_info)(unw_cursor_t*, unw_proc_info_t*);
extern int         UNW_ARCH_OBJ(is_fpreg)(unw_cursor_t*, unw_regnum_t);
extern int         UNW_OBJ(is_signal_frame)(unw_cursor_t*);
extern int         UNW_OBJ(get_proc_name)(unw_cursor_t*, char*, size_t, unw_word_t*);

typedef enum
{
    UNW_X86_64_RIP = 16,
#ifdef CONFIG_MSABI_SUPPORT
    UNW_X86_64_XMM0,
    UNW_X86_64_XMM1,
    UNW_X86_64_XMM2,
    UNW_X86_64_XMM3,
    UNW_X86_64_XMM4,
    UNW_X86_64_XMM5,
    UNW_X86_64_XMM6,
    UNW_X86_64_XMM7,
    UNW_X86_64_XMM8,
    UNW_X86_64_XMM9,
    UNW_X86_64_XMM10,
    UNW_X86_64_XMM11,
    UNW_X86_64_XMM12,
    UNW_X86_64_XMM13,
    UNW_X86_64_XMM14,
    UNW_X86_64_XMM15,
    UNW_TDEP_LAST_REG = UNW_X86_64_XMM15,
#else
    UNW_TDEP_LAST_REG = UNW_X86_64_RIP,
#endif

    /* XXX Add other regs here */

    /* frame info (read-only) */
    UNW_X86_64_CFA,

    UNW_TDEP_IP = UNW_X86_64_RIP,
    UNW_TDEP_SP = UNW_X86_64_RSP,
    UNW_TDEP_BP = UNW_X86_64_RBP,
    UNW_TDEP_EH = UNW_X86_64_RAX
}
x86_64_regnum_t;

#endif
