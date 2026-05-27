const std = @import("std");

pub fn build(b: *std.Build) void {
    const disable_encode = b.option(bool, "disable-encode", "Disable the encoder") orelse false;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("theora", .{});
    const ogg = b.dependency("libogg", .{});

    const theora = b.addModule("theora", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    theora.linkLibrary(ogg.artifact("ogg"));
    theora.addIncludePath(upstream.path("include/"));
    theora.addCSourceFiles(.{
        .root = upstream.path("lib/"),
        .files = decoder_srcs,
    });
    theora.addCSourceFiles(.{
        .root = upstream.path("lib/"),
        .files = switch (target.result.cpu.arch) {
            .x86, .x86_64 => decoder_x86_srcs,
            else => &.{},
        },
    });

    if (disable_encode) {
        theora.addCSourceFiles(.{
            .root = upstream.path("lib/"),
            .files = encoder_disabled_srcs,
        });
    } else {
        theora.addCSourceFiles(.{
            .root = upstream.path("lib/"),
            .files = encoder_uniq_srcs,
        });

        theora.addCSourceFiles(.{
            .root = upstream.path("lib/"),
            .files = switch (target.result.cpu.arch) {
                .x86 => encoder_uniq_x86_srcs,
                .x86_64 => encoder_uniq_x86_srcs ++ encoder_uniq_x86_64_srcs,
                else => &.{},
            },
        });
        
    }
    
    const libtheora = b.addLibrary(.{
        .name = "theora",
        .root_module = theora,
    });
    libtheora.installHeadersDirectory(
        upstream.path("include"), 
        "",
        .{ .include_extensions = &.{".h"} },
    );

    b.installArtifact(libtheora);
}

const common_srcs: []const []const u8 = &.{
    "decapiwrapper.c",
    "decinfo.c",
    "decode.c",
    
    "huffdec.c",
    "mcenc.c",
};

const encoder_disabled_srcs: []const []const u8 = &.{
    "encoder_disabled.c",
};

const encoder_shared_x86_srcs: []const []const u8 = &.{
    "x86/x86cpu.c",
    "x86/mmxfrag.c",
    "x86/mmxidct.c",
    "x86/mmxstate.c",
    "x86/sse2idct.c",
    "x86/x86state.c",
};

const encoder_uniq_x86_srcs: []const []const u8 = &.{
    "x86/mmxencfrag.c",
    "x86/mmxfdct.c",
    "x86/sse2encfrag.c",
    "x86/x86enquant.c",
    "x86/x86enc.c",
};

const encoder_uniq_x86_64_srcs: []const []const u8 = &.{
    "x86/sse2fdct.c",
};

const encoder_uniq_srcs: []const []const u8 = &.{
    "analyze.c",
    "fdct.c",
    "encfrag.c",
    "encapiwrapper.c",
    "encinfo.c",
    "encode.c",
    "enquant.c",
    "huffenc.c",
    "mathops.c",
    "mcenc.c",
    "rate.c",
    "tokenize.c", 
};

const encoder_srcs: []const []const u8 = &.{
    "apiwrapper.c",
    "bitpack.c",
    "dequant.c",
    "fragment.c",
    "idct.c",
    "info.c",
    "internal.c",
    "state.c",
    "quant.c",
};

const decoder_x86_srcs: []const []const u8 = &.{
    "x86/x86cpu.c",
    "x86/mmxidct.c",
    "x86/mmxfrag.c",
    "x86/mmxstate.c",
    "x86/sse2idct.c",
    "x86/x86state.c",
};

const decoder_arm_srcs: []const []const u8 = &.{
    "arm/armcpu.c",
    "arm/armstate.c",
};

const decoder_srcs: []const []const u8 = &.{
    "apiwrapper.c",
    "bitpack.c",
    "decapiwrapper.c",
    "decinfo.c",
    "decode.c",
    "dequant.c",
    "fragment.c",
    "huffdec.c",
    "idct.c",
    "info.c",
    "internal.c",
    "quant.c",
    "state.c",
};
