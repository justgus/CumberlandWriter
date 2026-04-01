#!/usr/bin/env python3
"""
Generate @2x and @3x scaled versions of backplate images.

Uses macOS CoreGraphics via PyObjC (bundled with macOS system Python3)
for high-quality Lanczos resampling.

Input:  *@1x.{png,PNG} files in the same directory as this script
Output: *@2x.png and *@3x.png files alongside the originals

The exception file (Purple-Dark-Lines) which is not 1536x384 will first
be resized to 1536x384 at @1x, then scaled up for @2x and @3x.
"""

import os
import subprocess
import shutil
import sys
import tempfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CANONICAL_W = 1536
CANONICAL_H = 384


def resample_with_sips(src_path, dst_path, width, height):
    """Use sips (macOS built-in) for high-quality resampling."""
    # Copy source to destination first, then resample in-place
    shutil.copy2(src_path, dst_path)
    subprocess.run(
        [
            "sips",
            "--resampleHeightWidth", str(height), str(width),
            dst_path,
        ],
        capture_output=True,
        check=True,
    )


def get_dimensions(path):
    """Get pixel dimensions of an image using sips."""
    result = subprocess.run(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", path],
        capture_output=True,
        text=True,
        check=True,
    )
    w = h = None
    for line in result.stdout.splitlines():
        if "pixelWidth" in line:
            w = int(line.split(":")[1].strip())
        elif "pixelHeight" in line:
            h = int(line.split(":")[1].strip())
    return w, h


def main():
    # Collect all @1x source images
    sources = []
    for f in sorted(os.listdir(SCRIPT_DIR)):
        if "@1x" in f and f.lower().endswith(".png"):
            sources.append(f)

    if not sources:
        print("No @1x images found in", SCRIPT_DIR)
        sys.exit(1)

    print(f"Found {len(sources)} source images.\n")

    for filename in sources:
        src_path = os.path.join(SCRIPT_DIR, filename)
        w, h = get_dimensions(src_path)

        # Derive base name: everything before @1x
        base = filename.split("@1x")[0]

        # Determine if this is the non-standard size that needs normalization
        needs_normalize = (w != CANONICAL_W or h != CANONICAL_H)

        if needs_normalize:
            print(f"  {filename}: {w}x{h} (non-standard, will normalize to {CANONICAL_W}x{CANONICAL_H})")
            # Use a temp file to normalize, then use it as the source for scaling
            tmp_fd, tmp_path = tempfile.mkstemp(suffix=".png")
            os.close(tmp_fd)
            resample_with_sips(src_path, tmp_path, CANONICAL_W, CANONICAL_H)
            effective_src = tmp_path
            print(f"    -> Normalized copy created for scaling")
        else:
            print(f"  {filename}: {w}x{h}")
            effective_src = src_path
            tmp_path = None

        # Generate @2x
        out_2x = os.path.join(SCRIPT_DIR, f"{base}@2x.png")
        target_w_2x = CANONICAL_W * 2
        target_h_2x = CANONICAL_H * 2
        resample_with_sips(effective_src, out_2x, target_w_2x, target_h_2x)
        print(f"    -> @2x: {target_w_2x}x{target_h_2x}  ({base}@2x.png)")

        # Generate @3x
        out_3x = os.path.join(SCRIPT_DIR, f"{base}@3x.png")
        target_w_3x = CANONICAL_W * 3
        target_h_3x = CANONICAL_H * 3
        resample_with_sips(effective_src, out_3x, target_w_3x, target_h_3x)
        print(f"    -> @3x: {target_w_3x}x{target_h_3x}  ({base}@3x.png)")

        # Clean up temp file if we created one
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)

        print()

    print("Done! Generated @2x and @3x variants for all backplates.")


if __name__ == "__main__":
    main()
