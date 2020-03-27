#
#  Be sure to run `pod spec lint stellar-ios-mac-sdk.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "stellar-ios-mac-sdk"
  s.version      = "1.7.3"
  s.summary      = "Fully featured iOS and macOS SDK that provides APIs to build transactions and connect to Horizon server for the Stellar ecosystem."
  s.module_name  = 'stellarsdk'
  s.swift_version = '5.0'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
  The Soneso iOS and macOS Stellar SDK facilitates integration with the Stellar Horizon API server and submission of Stellar transactions, either in your iOS or macOS app. It has two main uses: querying Horizon and building, signing, and submitting transactions to the Stellar network. The SDK gives you access to all the endpoints exposed by Horizon. Using Horizon, many requests can be invoked in streaming mode. All available streaming endpoints are covered by the SDK and you can use the SDK streaming functions to listen for updates. The SDK also covers encoding and decoding of all XDR Objects available.
  DESC

  s.homepage     = "https://github.com/Soneso/stellar-ios-mac-sdk"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = { :type => "Apache 2.0", :file => "LICENSE" }
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "Soneso" => "stellarsdk@soneso.com" }
  # Or just: s.author    = "Razvan Chelemen"
  # s.authors            = { "Razvan Chelemen" => "chelemen.razvan@gmail.com" }
  # s.social_media_url   = "http://twitter.com/Razvan Chelemen"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  #s.platform     = :ios, "8.0"
  # s.platform     = :ios, "5.0"

  #  When using multiple platforms
   s.ios.deployment_target = "8.0"
   s.osx.deployment_target = "10.10"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/Soneso/stellar-ios-mac-sdk.git", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "stellarsdk/stellarsdk/**/*.{h,m,swift,c}"
  #s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
   s.preserve_paths = 'stellarsdk/stellarsdk/libs/**/*.{modulemap}'

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library = 'CommonCrypto'
  # s.libraries = "iconv", "xml2"

  # s.ios.vendored_libraries = 'stellarsdk/stellarsdk/libs/**/*'

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
  s.pod_target_xcconfig = {
      'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'           => '$(SRCROOT)/stellar-ios-mac-sdk/stellarsdk/stellarsdk/libs/ed25519-C/** $(SRCROOT)/stellar-ios-mac-sdk/stellarsdk/stellarsdk/iphone', 
      'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'    => '$(SRCROOT)/stellar-ios-mac-sdk/stellarsdk/stellarsdk/libs/ed25519-C/** $(SRCROOT)/stellar-ios-mac-sdk/stellarsdk/stellarsdk/simulator',
      'SWIFT_INCLUDE_PATHS[sdk=macosx*]'    => '$(SRCROOT)/stellar-ios-mac-sdk/stellarsdk/stellarsdk/libs/ed25519-C/** $(SRCROOT)/stellar-ios-mac-sdk/stellarsdk/stellarsdk/osx',
  }

end
