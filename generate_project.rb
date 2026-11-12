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
group.new_file("Info.plist")
target.source_build_phase.add_file_reference(source)
examples = group.new_file("Examples")
examples.last_known_file_type = "folder"
target.resources_build_phase.add_file_reference(examples)

package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
package.repositoryURL = "https://github.com/SinanKarasu/MMDWorkbench.git"
package.requirement = { "kind" => "branch", "branch" => "main" }
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
  settings["GENERATE_INFOPLIST_FILE"] = "NO"
  settings["INFOPLIST_FILE"] = "MMDViewer/Info.plist"
  settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.productivity"
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

def add_quick_look(project, app)
  root = project.main_group.new_group('QuickLook', 'QuickLook')
  root.new_file('QuickLook.entitlements')
  embed = app.new_copy_files_build_phase('Embed Quick Look Extensions')
  embed.dst_subfolder_spec = '13'
  { 'Preview' => 'PreviewController', 'Thumbnail' => 'ThumbnailProvider' }.each do |folder, source|
    name = "MMDQuickLook#{folder}"
    target = project.new_target(:app_extension, name, :osx, '26.0')
    group = root.new_group(folder, folder)
    group.new_file('Info.plist')
    target.source_build_phase.add_file_reference(group.new_file("#{source}.swift"))
    target.build_configurations.each do |config|
      settings = config.build_settings
      settings.merge!({
        'APPLICATION_EXTENSION_API_ONLY' => 'YES',
        'CODE_SIGN_ENTITLEMENTS' => 'QuickLook/QuickLook.entitlements',
        'CODE_SIGN_STYLE' => 'Automatic',
        'CURRENT_PROJECT_VERSION' => '1',
        'DEVELOPMENT_TEAM' => '4HVP45GV3U',
        'GENERATE_INFOPLIST_FILE' => 'YES',
        'INFOPLIST_FILE' => "QuickLook/#{folder}/Info.plist",
        'MARKETING_VERSION' => '1.0',
        'PRODUCT_BUNDLE_IDENTIFIER' => "com.sinankarasu.MMDViewer.QuickLook#{folder}",
        'SKIP_INSTALL' => 'YES',
        'SUPPORTED_PLATFORMS' => 'macosx',
        'SWIFT_VERSION' => '6.0'
      })
    end
    if folder == 'Preview'
      product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      product.package = project.root_object.package_references.first
      product.product_name = 'MMDWorkbench'
      target.package_product_dependencies << product
      framework = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      framework.product_ref = product
      target.frameworks_build_phase.files << framework
      bundle = root.new_file('MMDWorkbench_MMDWorkbench.bundle', 'BUILT_PRODUCTS_DIR')
      bundle.explicit_file_type = 'wrapper.cfbundle'
      target.resources_build_phase.add_file_reference(bundle)
    end
    file = embed.add_file_reference(target.product_reference, true)
    file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
    file.platform_filters = ['macos']
  end
end

add_quick_look(project, target)
project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(target, nil, launch_target: true)
scheme.save_as(project_path, "MMDViewer", true)

puts "Created #{project_path}"
