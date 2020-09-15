# BitTorrent-iOS

This library provides a built library "libtorrent.a" and dependent header files for iOS.

## Requirements

- iOS 8.0 or later
- C++11 or later

## Dependencies

> There are 4 architectures included (armv7, arm64, i386 and x86_64) for the dependent libraries. So if you need more architecture(s), you need to replace the dependent libraries with your built files or contact us to get them.

- libtorrent 1.1.14
- boost 1.66.0
- libstdc++ / libc++

## Installation

### Manual installation

Clone this repository and drag the directories "include" and "libs" to the project navigator of you projectm, then add "$(SRCROOT)/include" to "Header Search Paths" in the build settings (non-recursive).


### Installation with CocoaPods

#### Pod (private)

```Ruby
platform :ios, '8.0'
pod 'BitTorrent', '~> 1.1.14'
```

#### Development pod

Clone this repository and specify the library directory.

Podfile example:

```Ruby
platform :ios, '8.0'
pod 'BitTorrent', :path => '../BitTorrent-iOS'
```

## How To Use

See [libtorrent.org](http://libtorrent.org/) for more detailed usage instructions.
