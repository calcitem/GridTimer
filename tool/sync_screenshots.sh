#!/bin/bash

# Script to copy screenshots from 'screenshots/' to 'fastlane/metadata/android/'
# It maps language codes (e.g., 'bn' -> 'bn-BD') and renames files based on their index (01 -> 1.png).

declare -A mapping
mapping=(
    ["ar"]="ar"
    ["bn"]="bn-BD"
    ["de"]="de-DE"
    ["en"]="en-US"
    ["es"]="es-ES"
    ["fr"]="fr-FR"
    ["hi"]="hi-IN"
    ["id"]="id"
    ["it"]="it-IT"
    ["ja"]="ja-JP"
    ["ko"]="ko-KR"
    ["pt"]="pt-PT"
    ["pt_BR"]="pt-BR"
    ["ru"]="ru-RU"
    ["th"]="th-TH"
    ["tr"]="tr-TR"
    ["vi"]="vi-VN"
    ["zh"]="zh-CN"
    ["zh_Hant"]="zh-TW"
)

for key in "${!mapping[@]}"; do
    srcDir="screenshots/$key"
    destDir="fastlane/metadata/android/${mapping[$key]}/images/phoneScreenshots"

    if [ -d "$srcDir" ]; then
        echo "Processing $key -> ${mapping[$key]}..."
        mkdir -p "$destDir"
        for file in "$srcDir"/*.png; do
            [ -e "$file" ] || continue
            filename=$(basename "$file")
            if [[ "$filename" == *"_01_"* ]]; then
                cp "$file" "$destDir/1.png"
            elif [[ "$filename" == *"_02_"* ]]; then
                cp "$file" "$destDir/2.png"
            elif [[ "$filename" == *"_03_"* ]]; then
                cp "$file" "$destDir/3.png"
            elif [[ "$filename" == *"_04_"* ]]; then
                cp "$file" "$destDir/4.png"
            fi
        done
    else
        echo "Warning: Source directory $srcDir not found."
    fi
done

echo "Screenshot sync complete."
