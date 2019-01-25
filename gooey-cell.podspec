#
# Be sure to run `pod lib lint gooey-cell.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'gooey-cell'
  s.version          = '0.1.0'
  s.summary          = 'UITableVIewCell with gooey effect animation'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Cuberto/gooey-cell'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Прегер Глеб' => 'gleb.preger@cuberto.ru' }
  s.source           = { :git => 'https://github.com/Cuberto/gooey-cell.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/cuberto'

  s.ios.deployment_target = '9.3'

  s.source_files = 'gooey-cell/Classes/**/*'
  
  # s.resource_bundles = {
  # 'gooey-cell' => ['gooey-cell/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'pop', '~> 1.0'
end
