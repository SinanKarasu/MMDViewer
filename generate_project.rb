#!/usr/bin/env ruby

require "fileutils"
require "xcodeproj"

root = File.expand_path(__dir__)
project_path = File.join(root, "MMDViewer.xcodeproj")
abort "Refusing to replace existing #{project_path}" if File.exist?(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastUpgradeCheck"] = "2700"

target = project.new_target(:application, "MMDViewer", :ios, "26.0")
group = project.main_group.new_group("MMDViewer", "MMDViewer")
source = group.new_file("MMDViewerApp.swift")
group.new_file("MMDViewer.entitlements")
target.source_build_phase.add_file_reference(source)

package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package.relative_path = "../../Packages/MMDWorkbench"
project.root_object.package_references << package

product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product.package = package
product.product_name = "MMDWorkbench"
target.package_product_dependencies << product

framework = project.new(Xcodeproj::Project::Object::PBXBuildFile)
framework.product_ref = product
target.frameworks_build_phase.files << framework

target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["DEVELOPMENT_TEAM"] = "4HVP45GV3U"
  settings["ENABLE_APP_SANDBOX"] = "YES"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "26.0"
  settings["MACOSX_DEPLOYMENT_TARGET"] = "26.0"
  settings["MARKETING_VERSION"] = "1.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.sinankarasu.MMDViewer"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SDKROOT"] = "auto"
  settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator macosx"
  settings["SUPPORTS_MACCATALYST"] = "NO"
  settings["SWIFT_DEFAULT_ACTOR_ISOLATION"] = "MainActor"
  settings["SWIFT_VERSION"] = "6.0"
  settings["TARGETED_DEVICE_FAMILY"] = "2"
  settings["CODE_SIGN_ENTITLEMENTS[sdk=macosx*]"] = "MMDViewer/MMDViewer.entitlements"
  settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*]"] = "YES"
  settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphoneos*]"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*]"] = "YES"
  settings["INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad"] = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(target, nil, launch_target: true)
scheme.save_as(project_path, "MMDViewer", true)

puts "Created #{project_path}"
