#!/bin/bash

echo "1. Start executing the clear_xattr.sh ..."

# Get the directory of the script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Array of target file paths
target_files=(
    "${script_dir}/arm64/Parfait"
    "${script_dir}/x86_64/Parfait"
    "${script_dir}/arm64/libsscronet.dylib"
    "${script_dir}/x86_64/libsscronet.dylib"
    "${script_dir}/arm64/ttnet_http_library.bundle/Contents/MacOS/ttnet_http_library"
    "${script_dir}/x86_64/ttnet_http_library.bundle/Contents/MacOS/ttnet_http_library"
)

echo ""
echo "2. Print target file paths ..."
for file in "${target_files[@]}"; do
    echo "$file"
done

echo ""
echo "3. View file attributes (before clearing) ..."

# Execute xattr command for each file
for file in "${target_files[@]}"; do
    xattr "$file"
done

echo ""
echo "4. Clear file attributes ..."

# Execute xattr -cr command for each file
for file in "${target_files[@]}"; do
    xattr -cr "$file"
done

echo ""
echo "5. View file attributes (after clearing) ..."

# Execute xattr command for each file
for file in "${target_files[@]}"; do
    xattr "$file"
done

echo ""
echo "6. Script execution finished ..."