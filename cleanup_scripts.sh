#!/bin/bash

echo "🧹 Cleaning up unnecessary scripts..."
echo "Keeping only scripts referenced in codemagic.yaml"

# iOS directory - keep only ios_build.sh
echo "📱 Cleaning iOS scripts..."
cd lib/scripts/ios
for file in *.sh; do
    if [ "$file" != "ios_build.sh" ]; then
        echo "🗑️  Deleting: $file"
        rm -f "$file"
    else
        echo "✅ Keeping: $file"
    fi
done

# iOS-workflow directory - delete all (none referenced)
echo "📱 Cleaning iOS-workflow scripts..."
cd ../ios-workflow
for file in *.sh; do
    echo "🗑️  Deleting: $file"
    rm -f "$file"
done

# Android directory - keep only main.sh
echo "🤖 Cleaning Android scripts..."
cd ../android
for file in *.sh; do
    if [ "$file" != "main.sh" ]; then
        echo "🗑️  Deleting: $file"
        rm -f "$file"
    else
        echo "✅ Keeping: $file"
    fi
done

# Combined directory - keep only main.sh
echo "🌐 Cleaning Combined scripts..."
cd ../combined
for file in *.sh; do
    if [ "$file" != "main.sh" ]; then
        echo "🗑️  Deleting: $file"
        rm -f "$file"
    else
        echo "✅ Keeping: $file"
    fi
done

# Utils directory - keep all (referenced multiple times)
echo "🔧 Utils directory - keeping all scripts (referenced in codemagic.yaml)"

cd ../..
echo "✅ Cleanup completed!"
echo ""
echo "📋 Summary of kept scripts:"
echo "  - lib/scripts/ios/ios_build.sh"
echo "  - lib/scripts/android/main.sh"
echo "  - lib/scripts/combined/main.sh"
echo "  - lib/scripts/utils/*.sh (all utility scripts)"
echo ""
echo "🗑️  All other scripts have been removed as they were not referenced in codemagic.yaml"
