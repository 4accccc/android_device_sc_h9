#!/bin/bash
INPUT="out/target/product/k50sv1_64/recovery.img"
OUTPUT="$HOME/recovery_final.img"
TARGET_SIZE=16777216

if [ ! -f "$INPUT" ]; then
    echo "错误: 找不到 $INPUT"
    echo "请先编译镜像"
    exit 1
fi

cp "$INPUT" "$OUTPUT"
truncate -s $TARGET_SIZE "$OUTPUT"

SIZE=$(stat -c%s "$OUTPUT")
echo "完成: $OUTPUT ($SIZE bytes)"
