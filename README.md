# stellar-ios-mac-sdk

The soneso open source stellar SDK for iOS &amp; Mac provides APIs to build transactions and connect to [Horizon](https://github.com/stellar/horizon).

## Disclaimer
The SDK is not yet ready for third-party use. It is still work in progress and not tested.

## Installation

We don't support yet CocoaPods or Carthage. The recommended setup is adding the SDK project as a subproject, and having the SDK as a target dependencies. Here is a step by step that we recommend:

1. Clone this repo (as a submodule or in a different directory, it's up to you);
2. Drag `stellarsdk.xcodeproj` as a subproject;
3. In your main `.xcodeproj` file, select the desired target(s);
4. Go to **Build Phases**, expand Target Dependencies, and add `stellarsdk`;
5. In Swift, `import stellarsdk` and you are good to go! 


## Basic Usage
coming soon

## Documentation
coming soon

# How to contribute

Please read our [Contribution Guide](https://github.com/Soneso/stellar-ios-mac-sdk/blob/master/CONTRIBUTING.md).

Then please [sign the Contributor License Agreement](https://goo.gl/forms/hS2KOI8d7WcelI892).

## License

stellar-ios-mac-sdk is licensed under an Apache-2.0 license. See the [LICENSE](https://github.com/soneso/stellar-ios-mac-sdk/blob/master/LICENSE) file for details.

## Donations
Send lumens to: GBD7Z2JSVGD2CWNMULKEROA75E6QXCAIERITPICSV77VMRDXNWIXNGLL 
thank you :)
