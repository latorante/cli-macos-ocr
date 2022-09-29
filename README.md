# mac-ocr-cli

`ocr-cli` is a command line utility for macOS 11+ to recognize text and text bounding box information from a image file.

## Build

```
swift build
.build/debug/ocr-cli file
```

## Info

```
OVERVIEW: Read text from an image file using native macOs Vision OCR

USAGE: ocr-cli <file-path> [--accurate] [--language-correction] [--single-line-output] [--json]

ARGUMENTS:
  <file-path>             Path to image file to read text from

OPTIONS:
  --accurate              Recognition level to accurate, default is fast
  --language-correction   Use language correction
  --single-line-output    Use single line output - works only if not using JSON output
  --json                  Outputs JSON object with boudning box information. This ignores --single-line-output
  -h, --help              Show help information.
```
