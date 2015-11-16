Pod::Spec.new do |s|
  s.name             = "FSKModem"
  s.version          = "0.1.0"
  s.summary          = "Frequency shift keying framework for iOS and OS X."
 
  s.description      = <<-DESC
  
  The FSKModem framework allows sending and receiving data from any iOS or OS X device via the head phone jack. It uses frequency shift keying (FSK) to modulate a sine curve carrier signal to transmit bits. On top of that it uses a simple packet protocol to cluster bytes.
                       DESC

  s.homepage         = "https://github.com/jensmeder/FSKModem"
  s.license          = 'MIT'
  s.author           = { "Jens Meder" => "me@jensmeder.de" }
  s.source           = { :git => "https://github.com/jensmeder/FSKModem.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true

  s.source_files = 'Source/**/*{h,m}'

  s.private_header_files = 'Source/Internal/**/*.h'
  s.frameworks = 'AudioToolbox', 'AVFoundation'
end
