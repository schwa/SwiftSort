install:
    swift build --configuration release
    sudo cp -f .build/release/SwiftSort /usr/local/bin/swiftsort
