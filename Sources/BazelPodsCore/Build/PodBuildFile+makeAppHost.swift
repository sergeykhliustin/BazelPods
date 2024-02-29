//
//  PodBuildFile+makeAppHost.swift
//  BazelPodsCore
//
//  Created by Sergey Khliustin on 27.02.2024.
//

import Foundation

extension PodBuildFile {
    static func makeAppHost(spec: PodSpec,
                            testspec: TestSpec,
                            targetName: TargetName,
                            info: BaseAnalyzer<TestSpec>.Result,
                            options: BuildOptions) -> [BazelTarget] {

        let appName = targetName.appHostName(spec.name, testspec: testspec.name)
        let mainMName = targetName.appHostMainM(spec.name, testspec: testspec.name)
        let libName = targetName.appHostLib(spec.name, testspec: testspec.name)
        let launchScreenName = targetName.appHostLaunchScreen(spec.name, testspec: testspec.name)
        let infoPlistName = targetName.appHostInfoplist(spec.name, testspec: testspec.name)

        let mainM = GenRule(name: mainMName, fileExtension: "m", fileContent: mainMContent)
        let lib = AppHostObjcLibrary(name: libName, mainM: mainMName)
        let launchScreen = GenRule(name: launchScreenName,
                                   fileName: "LaunchScreen",
                                   fileExtension: "storyboard",
                                   fileContent: launchScreenStoryboardContent)
        let infoPlist = InfoPlist(name: infoPlistName, appHost: info)
        let appHost = iOSAppHost(name: appName,
                                 minimumOSVersion: info.minimumOsVersion,
                                 infoPlist: infoPlistName,
                                 resources: [launchScreenName],
                                 deps: [libName])
        return [
            mainM,
            lib,
            launchScreen,
            infoPlist,
            appHost
        ]
    }
}

private let mainMContent = """
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CPTestAppHostAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@end

@implementation CPTestAppHostAppDelegate

- (BOOL)application:(UIApplication *)__unused application didFinishLaunchingWithOptions:(NSDictionary *)__unused launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [UIViewController new];

    [self.window makeKeyAndVisible];

    return YES;
}

@end

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([CPTestAppHostAppDelegate class]));
    }
}
"""
// swiftlint:disable line_length
private let launchScreenStoryboardContent = """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="13122.16" systemVersion="17A277" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
  <dependencies>
    <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="13104.12"/>
    <capability name="Safe area layout guides" minToolsVersion="9.0"/>
    <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
  </dependencies>
  <scenes>
    <!--View Controller-->
    <scene sceneID="EHf-IW-A2E">
      <objects>
        <viewController id="01J-lp-oVM" sceneMemberID="viewController">
          <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
            <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
            <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
            <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
            <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
          </view>
        </viewController>
        <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
      </objects>
      <point key="canvasLocation" x="53" y="375"/>
    </scene>
  </scenes>
</document>
"""
// swiftlint:enable line_length
