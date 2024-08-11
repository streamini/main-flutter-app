#ln -s /Applications/streamini "./build/macos/Build/Products"


TARGET_DIR="./build/macos/Build/"

[ ! -d "/Applications/streamini/Products" ] && mkdir -p "/Applications/streamini/Products"

[ ! -d "$TARGET_DIR" ] && mkdir -p "$TARGET_DIR"
ln -s /Applications/streamini/Products "$TARGET_DIR"

echo "Linking done"