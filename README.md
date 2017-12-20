# Snippet
[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)

Quickly extract your specific Github PRs with links last week (or earlier than last week) to markdown formats.

```console
$ snippet help

Snippet
--------------
Quickly extract your specific Github PRs with links last week (or earlier than last week) to markdown formats.

Usage:
- Specify an organization in Github. (The default is your all repositories.)
- Pass a past week number using the `--week`. (The default is `-1`)
- Register your access token for repo (Full control of private repositories) in Github using the `--token` at first.

Examples:
- snippet --week 0
- snippet Org
- snippet Org --week -4
- snippet Org --token [YOUR_PERSONAL_ACCESS_TOKEN]

$ snippet Org --week -2

2017-12-11 ~ 2017-12-18 in Org
---------------------------------------
Total count: 3

* [*Mon Dec 18*] [Org/repo] [#735](https://github.com/Org/repo/pull/735) Initial commit
* [*Fri Dec 15*] [Org/repo] [#733](https://github.com/Org/repo/pull/733) Update README
* [*Fri Dec 15*] [Org/repo] [#731](https://github.com/Org/repo/pull/731) Add new function
```

## Requirements

Snippet requires / supports the following environments:

- Swift 4.0 or later
- Git

## Installation

On macOS

### Makefile

```console
$ git clone git@github.com:pixyzehn/Snippet.git && cd Snippet
$ make
```

### SwiftPM

```console
$ git clone git@github.com:pixyzehn/Snippet.git && cd Snippet
$ swift build -c release -Xswiftc -static-stdlib
$ cp -f .build/release/Snippet /usr/local/bin/Snippet
```

On Linux

```console
$ git clone git@github.com:pixyzehn/Snippet.git && cd Snippet
$ swift build -c release
$ cp -f .build/release/Snippet /usr/local/bin/Snippet
```

## Contributing

1. Fork it ( https://github.com/pixyzehn/Snippet )
2. Create your feature branch (`git checkout -b new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin new-feature`)
5. Create a new Pull Request

## License
[MIT License](https://github.com/pixyzehn/Snippet/blob/master/LICENSE)
