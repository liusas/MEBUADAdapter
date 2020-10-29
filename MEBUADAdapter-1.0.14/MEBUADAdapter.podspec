Pod::Spec.new do |s|
  s.name = "MEBUADAdapter"
  s.version = "1.0.14"
  s.summary = "A adapter of BUAD for mediation SDK"
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"刘峰"=>"liufeng@mobiexchanger.com"}
  s.homepage = "https://github.com/liusas/MEBUADAdapter.git"
  s.description = "this is a Mobiexchanger's advertise adapter, and we use it as a module"
  s.source = { :path => '.' }

  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/MEBUADAdapter.framework'
end
