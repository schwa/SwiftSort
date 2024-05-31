install: build-release
    sudo cp -f .build/release/SwiftSort /usr/local/bin/swiftsort

build-release:
    swift build --configuration release

run DIR: build-release
    #!/usr/bin/env fish

    for PATH in (fd '\.swift' {{DIR}})
        echo $PATH
        .build/release/SwiftSort $PATH > /dev/null; or exit
    end

run-projects:
    just run ~/Projects
