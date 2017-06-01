Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '9.0'
s.name = "DVCaptureView"
s.summary = "DVCaptureView use for rectangle detecting."
s.requires_arc = true

# 2
s.version = "1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 
s.author = { "Dmitriy Virych" => "damienissa@yahoo.com" }

# 5 
s.homepage = "https://github.com/damienissa/DVCaptureViewFramework/"

# 6
s.source = { :git => "https://github.com/damienissa/DVCaptureViewFramework.git", :tag => "1.0"}

# 7
s.framework = "UIKit"

# 8
s.source_files = "DVCaptureView/**/*.{swift, plist}"

end
