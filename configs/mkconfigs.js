#!/usr/bin/env node
/*
 * Copyright (C) 2021-2024 Yahweasel and contributors
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

const cproc = require("child_process");
const fs = require("fs");

const opus = ["parser-opus", "codec-libopus"];
const flac = ["format-flac", "parser-flac", "codec-flac"];
const mp3 = ["format-mp3", "decoder-mp3", "encoder-libmp3lame"];
const vp8 = ["parser-vp8", "codec-libvpx_vp8"];
const vp9 = ["parser-vp9", "codec-libvpx_vp9"];
// Hopefully, a faster AV1 encoder will become an option soon...
const aomav1 = ["parser-av1", "codec-libaom_av1"];
const aomsvtav1 = ["parser-av1", "decoder-libaom_av1", "encoder-libsvtav1"];

// Misanthropic Patent Extortion Gang (formats/codecs by reprobates)
const aac = ["format-aac", "parser-aac", "codec-aac"];
const h264 = ["parser-h264", "decoder-h264", "codec-libopenh264"];
const hevc = ["parser-hevc", "decoder-hevc"];

// Images
const images = [
    "format-image2",

    // JPEG, MJPEG
    "format-mjpeg", "demuxer-image_jpeg_pipe", "parser-mjpeg", "codec-mjpeg", 

    // DDS
    "decoder-dds", "demuxer-image_dds_pipe",

    // GIF
    "format-gif", "demuxer-image_gif_pipe", "parser-gif", "codec-gif",

    // PNG
    "codec-png", "parser-png", "demuxer-image_png_pipe",

    // WEBP
    "demuxer-image_webp_pipe", "muxer-webp", "parser-webp", "decoder-webp", "encoder-libwebp",

    // AVIF
    aomav1, "muxer-avif",

    // BMP
    "codec-bmp", "parser-bmp", "demuxer-image_bmp_pipe",

    // ICO,
    "format-ico",

    // todo: JPEGXL

    // TIFF
    "codec-tiff", "demuxer-image_tiff_pipe"
];

// all WAV formats under the sun
const wav = [
    "codec-pcm_s16le",
    "decoder-pcm_alaw",
    "decoder-pcm_bluray",
    "decoder-pcm_dvd",
    "decoder-pcm_f16le",
    "decoder-pcm_f24le",
    "decoder-pcm_f32be",
    "decoder-pcm_f32le",
    "decoder-pcm_f64be",
    "decoder-pcm_f64le",
    "decoder-pcm_lxf",
    "decoder-pcm_mulaw",
    "decoder-pcm_s16be",
    "decoder-pcm_s16be_planar",
    "decoder-pcm_s16le_planar",
    "decoder-pcm_s24be",
    "decoder-pcm_s24daud",
    "decoder-pcm_s24le",
    "decoder-pcm_s24le_planar",
    "decoder-pcm_s32be",
    "decoder-pcm_s32le",
    "decoder-pcm_s32le_planar",
    "decoder-pcm_s64be",
    "decoder-pcm_s64le",
    "decoder-pcm_s8",
    "decoder-pcm_s8_planar",
    "decoder-pcm_sga",
    "decoder-pcm_u16be",
    "decoder-pcm_u16le",
    "decoder-pcm_u24be",
    "decoder-pcm_u24le",
    "decoder-pcm_u32be",
    "decoder-pcm_u32le",
    "decoder-pcm_u8",
    "decoder-pcm_vidc",
    "demuxer-pcm_alaw",
    "demuxer-pcm_f32be",
    "demuxer-pcm_f32le",
    "demuxer-pcm_f64be",
    "demuxer-pcm_f64le",
    "demuxer-pcm_mulaw",
    "demuxer-pcm_s16be",
    "demuxer-pcm_s24be",
    "demuxer-pcm_s24le",
    "demuxer-pcm_s32be",
    "demuxer-pcm_s32le",
    "demuxer-pcm_s8",
    "demuxer-pcm_u16be",
    "demuxer-pcm_u16le",
    "demuxer-pcm_u24be",
    "demuxer-pcm_u24le",
    "demuxer-pcm_u32be",
    "demuxer-pcm_u32le",
    "demuxer-pcm_u8",
    "demuxer-pcm_vidc",
    "format-pcm_s16le",
    "format-wav"
];

const configsRaw = [
    // Audio sensible:
    ["default", [
        "format-ogg", "format-webm",
        opus, flac, "format-wav", "codec-pcm_f32le",
        "audio-filters"
    ], {cli: true}],

    ["opus", ["format-ogg", "format-webm", opus], {af: true}],
    ["flac", ["format-ogg", flac], {af: true}],
    ["wav", ["format-wav", "codec-pcm_f32le"], {af: true}],

    // Audio silly:
    ["obsolete", [
        // Modern:
        "format-ogg", "format-webm",
        opus, flac,

        // Timeless:
        "format-wav", "codec-pcm_f32le",

        // Obsolete:
        "codec-libvorbis", mp3,

        // (and filters)
        "audio-filters"
    ]],

    // Audio reprobate:
    ["aac", ["format-mp4", "format-aac", "format-webm", aac], {af: true}],

    // Video sensible:
    ["webm", [
        "format-ogg", "format-webm",
        opus, flac, "format-wav", "codec-pcm_f32le",
        "audio-filters",

        "libvpx", vp8,
        "swscale", "video-filters"
    ], {vp9: true, cli: true}],

    ["vp8-opus", ["format-ogg", "format-webm", opus, "libvpx", vp8], {avf: true}],
    ["vp9-opus", ["format-ogg", "format-webm", opus, "libvpx", vp9], {avf: true}],
    ["av1-opus", ["format-ogg", "format-webm", opus, aomav1], {avf: true}],

    // Video reprobate:
    ["h264-aac", ["format-mp4", "format-aac", "format-webm", aac, h264], {avf: true}],
    ["hevc-aac", ["format-mp4", "format-aac", "format-webm", aac, hevc], {avf: true}],

    // Mostly parsing:
    ["webcodecs", [
        "format-ogg", "format-webm", "format-mp4",
        opus, flac, "format-wav", "codec-pcm_f32le",
        "parser-aac",

        "parser-vp8", "parser-vp9", "parser-av1",
        "parser-h264", "parser-hevc",

        "bsf-extract_extradata",
        "bsf-vp9_metadata", "bsf-av1_metadata",
        "bsf-h264_metadata", "bsf-hevc_metadata"
    ], {avf: true}],

    // These are here so that "all" will have them for testing
    ["extras", [
        images,

        // Raw data
        "format-rawvideo", "codec-rawvideo",
        "format-pcm_f32le", "codec-pcm_f32le",

        // Apple-flavored lossless
        "codec-alac", "codec-prores", "codec-qtrle",

        // HLS
        "format-hls", "protocol-jsfetch"
    ]],

    ["encode",
        [
          // Images
            images,

          // Video formats
            "format-mov", "format-mp4",
            "format-matroska", "format-webm", "format-avi",
            "libvpx",
            "parser-vp8", "parser-vp9",

            aomav1,


          // Audio
            "muxer-ipod", "format-ogg", "muxer-opus",
            opus,

            // Apple-flavored lossless
            "codec-libvorbis", "codec-alac",
            "codec-prores", "codec-qtrle",

            flac, wav, aac, mp3,
            "codec-prores", "codec-qtrle",
          // Misc
            "audio-filters", "swscale",
        ], { cli: true }
    ],

    ["remux", [
        "format-mp3","format-mp4",
        "format-webm","format-ogg",
        "muxer-opus","parser-opus",
        "format-wav","muxer-ipod"
    ], { cli: true }],

    ["empty", []],
    ["all", null]
];
let all = Object.create(null);

function configGroup(configs, nameExt, parts) {
    const toAdd = configs.map(config =>
        [`${config[0]}-${nameExt}`, config[1].concat(parts)]
    );
    configs.push.apply(configs, toAdd);
}

// Process the configs into groups
const configs = [];
for (const config of configsRaw) {
    const [name, inParts, extra] = config;

    // Expand the parts
    const parts = inParts ? [] : null;
    if (inParts) {
        for (const part of inParts) {
            if (part instanceof Array)
                parts.push.apply(parts, part);
            else
                parts.push(part);
        }
    }

    // Expand the extras
    const toAdd = [[name, parts]];
    if (extra && extra.vp9)
        configGroup(toAdd, "vp9", vp9);
    if (extra && extra.af)
        configGroup(toAdd, "af", ["audio-filters"]);
    if (extra && extra.avf)
        configGroup(toAdd, "avf", ["audio-filters", "swscale", "video-filters"]);
    if (extra && extra.cli)
        configGroup(toAdd, "cli", ["cli"]);

    configs.push.apply(configs, toAdd);
}

// Process arguments
let createOnes = false;
for (const arg of process.argv.slice(2)) {
    if (arg === "--create-ones")
        createOnes = true;
    else {
        console.error(`Unrecognized argument ${arg}`);
        process.exit(1);
    }
}

async function main() {
    for (let [name, config] of configs) {
        if (name !== "all") {
            for (const fragment of config)
                all[fragment] = true;
        } else {
            config = Object.keys(all);
        }

        const p = cproc.spawn("./mkconfig.js", [name, JSON.stringify(config)], {
            stdio: "inherit"
        });
        await new Promise(res => p.on("close", res));
    }

    if (createOnes) {
        const allFragments = Object.keys(all).map(x => {
            // Split up codecs and formats
            const p = /^([^-]*)-(.*)$/.exec(x);
            if (!p)
                return [x];
            if (p[1] === "codec")
                return [`decoder-${p[2]}`, `encoder-${p[2]}`, x]
            else if (p[1] === "format")
                return [`demuxer-${p[2]}`, `muxer-${p[2]}`, x]
            else
                return [x];
        }).reduce((a, b) => a.concat(b));

        for (const fragment of allFragments) {
            // Fix fragment dependencies
            let fragments = [fragment];
            if (fragment.indexOf("libvpx") >= 0)
                fragments.unshift("libvpx");
            if (fragment === "parser-aac")
                fragments.push("parser-ac3");

            // And make the variant
            const p = cproc.spawn("./mkconfig.js", [
                `one-${fragment}`, JSON.stringify(fragments)
            ], {stdio: "inherit"});
            await new Promise(res => p.on("close", res));
        }
    }
}
main();
