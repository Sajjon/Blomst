echo "Building blst as an xcframework"

cd "$(dirname "$0")"

echo "Removing xcframework from last time."
rm ../BLST.xcframework

./build.sh -Wno-error -shared flavour=macosx

xcodebuild -create-xcframework \
    -library libblst.dylib -headers include \
    -output ../BLST.xcframework

#rm libblst.a
#rm libblst.dylib

echo "Finished building BLST.xcframework"
