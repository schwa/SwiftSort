# swiftsort

Be the envy of your co-workers! Sort the top-level elements of your Swift files!

Top-level elements are sorted by "group" (currently ordered by imports, variables (let, var), types (enums, classes, actors, structs), extensions and then functions) and then alphabetically within each type.

## Installation

Hmm. Homebrew or something. Someone help me out here.

## Status

I wrote this code in an hour. It's probably going to fall over when you run it on your code. Bug reports are appreciated.

It currently does not sort top-level expressions (apart from let and var declarations).

There is no guarantee that this tool will not cause data loss. Run at your own risk. The tool currently does not overwrite the input file and merely outputs the sorted file to stdout.

## License

MIT

## Usage

```sh
swift run SwiftSort Sources/Support/Support.swift
```
