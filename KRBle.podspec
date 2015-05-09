Pod::Spec.new do |s|
  s.name         = "KRBle"
  s.version      = "1.2"
  s.summary      = "Achieved BLE with Central and Peripheral modules in BT4.0."
  s.description  = <<-DESC
                   KRBle implements the Bluetooth Low Engery (BLE) and simulate SPP transfer big data ( ex : image / 2,000 words ), central and peripheral can exchange the big data to each other, summarized, you could easy use this project to build your BLE applications.
                   DESC
  s.homepage     = "https://github.com/Kalvar/ios-KRBle"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Kalvar Lin" => "ilovekalvar@gmail.com" }
  s.social_media_url = "https://twitter.com/ilovekalvar"
  s.source       = { :git => "https://github.com/Kalvar/ios-KRBle.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.public_header_files = 'KRBle/*.h', 'KRBle/*'
  s.source_files = 'KRBle/KRBle.h'
  s.frameworks   = 'Foundation', 'CoreBluetooth'
end 