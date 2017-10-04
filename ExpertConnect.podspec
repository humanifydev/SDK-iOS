Pod::Spec.new do |s|
  s.name = 'EXPERTconnect'
  s.version = '6.2.0'
  s.license = 'MIT'
  s.summary = 'Humanify customer service native SDK'
  s.homepage = 'http://www.teletech.com/'
  s.authors = { 'Mike Schmoyer' => 'mike.schmoyer@humanify.com' }
  s.source = { :git => 'https://github.com/humanifydev/SDK-iOS.git', :tag => s.version }

  s.platform         = :ios, '8.1'
  s.requires_arc = true
  s.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS[config=Debug]' => '-D DEBUG' }

  s.source_files = 'ExpertConnect/ExpertConnect/**/*.{m,h,mm,hpp,cpp,c}'

  s.resources = 'ExpertConnect/ExpertConnect/**/*.{xcassets,xib,nib}'

  s.resource_bundles = {
	  'EXPERTconnect' => ['ExpertConnect/ExpertConnect/**/*.{json,imageset,png,lproj}']
  }

  # Dependencies
  s.frameworks = 'UIKit', 'MediaPlayer', 'MobileCoreServices', 'SystemConfiguration', 'CoreText', 'AVFoundation', 'Foundation', 'MapKit', 'Security'
  s.libraries	= 'icucore'

end
