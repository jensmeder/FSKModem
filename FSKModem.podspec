Pod::Spec.new do |s|
  s.name             = "FSKModem"
  s.version          = "0.1.0"
  s.summary          = "A short description of FSKModem."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       DESC

  s.homepage         = "https://github.com/jensmeder/FSKModem"
  s.license          = 'MIT'
  s.author           = { "Jens Meder" => "me@jensmeder.de" }
  s.source           = { :git => "https://github.com/jensmeder/FSKModem.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Source/**/*{h,m}'

  s.private_header_files = 'Source/Internal/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
