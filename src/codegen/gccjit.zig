// Mostly copied from llvm.zig
const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.codegen);
const math = std.math;
const DW = std.dwarf;

//const Builder = @import("llvm/Builder.zig");
const gccjit = @import("gccjit/bindings.zig");
const link = @import("../link.zig");
const Compilation = @import("../Compilation.zig");
const build_options = @import("build_options");
const Zcu = @import("../Zcu.zig");
const InternPool = @import("../InternPool.zig");
const Package = @import("../Package.zig");
const Air = @import("../Air.zig");
const Liveness = @import("../Liveness.zig");
const Value = @import("../Value.zig");
const Type = @import("../Type.zig");
const x86_64_abi = @import("../arch/x86_64/abi.zig");
const wasm_c_abi = @import("../arch/wasm/abi.zig");
const aarch64_c_abi = @import("../arch/aarch64/abi.zig");
const arm_c_abi = @import("../arch/arm/abi.zig");
const riscv_c_abi = @import("../arch/riscv64/abi.zig");
const mips_c_abi = @import("../arch/mips/abi.zig");
const dev = @import("../dev.zig");

const Error = error{ OutOfMemory, CodegenFail };

pub fn getGCCJITenum_Types_FromInst_C_Only(inst: Air.Inst.Ref) ?gccjit.gcc_jit_types {
    switch (inst) {
        .bool_type,
        .u1_type,
        => return gccjit.GCC_JIT_TYPE_BOOL,
        .u8_type => return gccjit.GCC_JIT_TYPE_UINT8_T,
        .i8_type => return gccjit.GCC_JIT_TYPE_INT8_T,
        .u16_type => return gccjit.GCC_JIT_TYPE_UINT16_T,
        .i16_type => return gccjit.GCC_JIT_TYPE_INT16_T,
        .u32_type => return gccjit.GCC_JIT_TYPE_UINT32_T,
        .i32_type => return gccjit.GCC_JIT_TYPE_INT32_T,
        .u64_type => return gccjit.GCC_JIT_TYPE_UINT64_T,
        .i64_type => return gccjit.GCC_JIT_TYPE_INT64_T,
        .u128_type => return gccjit.GCC_JIT_TYPE_UINT128_T,
        .i128_type => return gccjit.GCC_JIT_TYPE_INT128_T,
        .c_char_type => return gccjit.GCC_JIT_TYPE_CHAR,
        .c_short_type => return gccjit.GCC_JIT_TYPE_SHORT,
        .c_ushort_type => return gccjit.GCC_JIT_TYPE_UNSIGNED_SHORT,
        .c_int_type => return gccjit.GCC_JIT_TYPE_INT,
        .c_uint_type => return gccjit.GCC_JIT_TYPE_UNSIGNED_INT,
        .c_long_type => return gccjit.GCC_JIT_TYPE_LONG,
        .c_ulong_type => return gccjit.GCC_JIT_TYPE_UNSIGNED_LONG,
        .c_longlong_type => return gccjit.GCC_JIT_TYPE_LONG_LONG,
        .c_ulonglong_type => return gccjit.GCC_JIT_TYPE_UNSIGNED_LONG_LONG,
        .f32_type => return gccjit.GCC_JIT_TYPE_FLOAT,
        .f64_type => return gccjit.GCC_JIT_TYPE_DOUBLE,
        else => return null,
    }
}

pub fn getGCCJITstruct_Type_FromInst_C_Only(ctxt: *gccjit.gcc_jit_context, inst: Air.Inst.Ref) ?*gccjit.gcc_jit_type {
    const enum_type_from_air: ?gccjit.gcc_jit_types = getGCCJITenum_Types_FromInst_C_Only(inst);
    if (enum_type_from_air == null) {
        return null;
    }
    return gccjit.gcc_jit_context_get_type(ctxt, @as(gccjit.gcc_jit_types, enum_type_from_air));
}
