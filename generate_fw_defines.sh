#!/bin/sh
# Generate libPS4/include/fw_defines.h from the centralized ps4-offsets submodule.
# Run this after updating the submodule to regenerate the K{VER}_* defines.

OFFSETS_DIR="$(dirname "$0")/ps4-offsets"
OUTPUT="$(dirname "$0")/libPS4/include/fw_defines.h"

if [ ! -d "$OFFSETS_DIR" ]; then
  echo "error: ps4-offsets submodule not found at $OFFSETS_DIR" >&2
  echo "  Run: git submodule update --init" >&2
  exit 1
fi

cat > "$OUTPUT" << 'HEADER'
#pragma once

#ifndef FW_DEFINES_H
#define FW_DEFINES_H

/*
 * AUTO-GENERATED from ps4-offsets submodule.
 * Do not edit manually. Run ./generate_fw_defines.sh to regenerate.
 */

// clang-format off
HEADER

# Mapping from centralized kern_off_* names to legacy K{VER}_ suffix names.
# The centralized repo uses lowercase kern_off_ prefix; the legacy consumer
# uses uppercase K{VER}_ prefix with uppercase symbol names.
#
# Format: kern_off_name -> LEGACY_SUFFIX

for hdr in "$OFFSETS_DIR"/[0-9]*.h; do
  ver=$(basename "$hdr" .h)

  # Determine the K-prefix version number
  # Versions < 1000 map directly (e.g. 505 -> K505)
  # Versions >= 1000 map directly too (e.g. 1100 -> K1100)
  kver="K${ver}"

  echo "" >> "$OUTPUT"
  echo "// Firmware ${ver}" >> "$OUTPUT"

  # Read each #define from the version header and re-export as K{VER}_{SYMBOL}
  grep '^#define kern_off_' "$hdr" | while IFS= read -r line; do
    # Extract: #define kern_off_SYMBOL VALUE
    symbol=$(echo "$line" | sed 's/#define kern_off_\([A-Za-z_0-9]*\).*/\1/')
    value=$(echo "$line" | sed 's/#define kern_off_[A-Za-z_0-9]* *\(.*\)/\1/')

    # Map kern_off_name to legacy UPPERCASE suffix
    case "$symbol" in
      xfast_syscall)          suffix="XFAST_SYSCALL" ;;
      prison0)                suffix="PRISON_0" ;;
      rootvnode)              suffix="ROOTVNODE" ;;
      copyout)                suffix="COPYOUT" ;;
      mmap_self_1)            suffix="MMAP_SELF_1" ;;
      mmap_self_2)            suffix="MMAP_SELF_2" ;;
      mmap_self_3)            suffix="MMAP_SELF_3" ;;
      disable_aslr)           suffix="DISABLE_ASLR" ;;
      reg_mgr_set_int)        suffix="REG_MGR_SET_INT" ;;
      set_time)               suffix="SET_TIME" ;;
      clear_time_diff)        suffix="CLEAR_TIME_DIFFERENCE" ;;
      target_id)              suffix="TARGET_ID" ;;
      icc_nvs_write)          suffix="ICC_NVS_WRITE" ;;
      npdrm_open)             suffix="NPDRM_OPEN" ;;
      npdrm_close)            suffix="NPDRM_CLOSE" ;;
      npdrm_ioctl)            suffix="NPDRM_IOCTL" ;;
      no_bd_patch)            suffix="NO_BD_PATCH" ;;
      *)                      continue ;;  # Skip symbols not used by legacy code
    esac

    printf '#define %-30s %s\n' "${kver}_${suffix}" "$value" >> "$OUTPUT"
  done
done

cat >> "$OUTPUT" << 'FOOTER'

// clang-format on

#endif
FOOTER

echo "Generated $OUTPUT"
