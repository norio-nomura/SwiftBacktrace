//
//  Unwind.swift
//  SwiftBacktrace
//
//  Created by 野村 憲男 on 5/1/18.
//

import Clibunwind
import CSwiftBacktrace

struct unw {
    @discardableResult
    static func getcontext(_ ucp: UnsafeMutablePointer<unw_context_t>) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_getcontext(ucp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._Ux86_64_getcontext(ucp)
    #endif
    }

    @discardableResult
    static func init_local(_ cp: UnsafeMutablePointer<unw_cursor_t>!,
                           _ ucp: UnsafeMutablePointer<unw_context_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_init_local(cp, ucp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_init_local(cp, ucp)
    #endif
    }

    @discardableResult
    static func step(_ cp: UnsafeMutablePointer<unw_cursor_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_step(cp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_step(cp)
    #endif
    }

    @discardableResult
    static func get_reg(_ cp: UnsafeMutablePointer<unw_cursor_t>!,
                        _ reg: unw_regnum_t,
                        _ valp: UnsafeMutablePointer<unw_word_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_get_reg(cp, reg, valp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_get_reg(cp, reg, valp)
    #endif
    }

    @discardableResult
    static func get_fpreg(_ cp: UnsafeMutablePointer<unw_cursor_t>!,
                          _ reg: unw_regnum_t,
                          _ valp: UnsafeMutablePointer<unw_fpreg_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_get_fpreg(cp, reg, valp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_get_fpreg(cp, reg, valp)
    #endif
    }

    @discardableResult
    static func set_reg(_ cp: UnsafeMutablePointer<unw_cursor_t>!, _ reg: unw_regnum_t, _ val: unw_word_t) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_set_reg(cp, reg, val)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_set_reg(cp, reg, val)
    #endif
    }

    @discardableResult
    static func set_fpreg(_ cp: UnsafeMutablePointer<unw_cursor_t>!, _ reg: unw_regnum_t, _ val: unw_fpreg_t) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_set_fpreg(cp, reg, val)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_set_fpreg(cp, reg, val)
    #endif
    }

    @discardableResult
    static func resume(_ cp: UnsafeMutablePointer<unw_cursor_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_resume(cp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_resume(cp)
    #endif
    }

    @discardableResult
    static func regname(_ cp: UnsafeMutablePointer<unw_cursor_t>!, _ reg: unw_regnum_t) -> UnsafePointer<Int8>! {
    #if os(macOS)
        return Clibunwind.unw_regname(cp, reg)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._Ux86_64_regname(cp, reg)
    #endif
    }

    @discardableResult
    static func get_proc_info(_ cp: UnsafeMutablePointer<unw_cursor_t>!,
                              _ pip: UnsafeMutablePointer<unw_proc_info_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_get_proc_info(cp, pip)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_get_proc_info(cp, pip)
    #endif
    }

    @discardableResult
    static func is_fpreg(_ cp: UnsafeMutablePointer<unw_cursor_t>!, _ reg: unw_regnum_t) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_is_fpreg(cp, reg)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._Ux86_64_is_fpreg(cp, reg)
    #endif
    }

    @discardableResult
    static func is_signal_frame(_ cp: UnsafeMutablePointer<unw_cursor_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_is_signal_frame(cp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_is_signal_frame(cp)
    #endif
    }

    @discardableResult
    static func get_proc_name(_ cp: UnsafeMutablePointer<unw_cursor_t>!,
                                  _ bufp: UnsafeMutablePointer<Int8>!,
                                  _ len: Int,
                                  _ offp: UnsafeMutablePointer<unw_word_t>!) -> Int32 {
    #if os(macOS)
        return Clibunwind.unw_get_proc_name(cp, bufp, len, offp)
    #elseif os(Linux) && arch(x86_64)
        return Clibunwind._ULx86_64_get_proc_name(cp, bufp, len, offp)
    #endif
    }
}
