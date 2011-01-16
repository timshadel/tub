# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tub/version"

Gem::Specification.new do |s|
  s.name        = "tub"
  s.version     = ThinUpgradableBackend::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tim Shadel"]
  s.email       = ["github@timshadel.com"]
  s.homepage    = "http://github.com/timshadel/tub"
  s.summary     = %q{Make a Thin backend that can serve Rack, then easily be upgraded to a completely different EM-based protocol.}
  s.description = %q{The HTTP spec details a way to use HTTP/1.1 as a platform for transitioning to newer protocols by starting the conversation with HTTP/1.1. There are no restrictions on what that protocol can be.}

  # s.rubyforge_project = "tub"

  s.add_development_dependency "rspec"
  s.add_development_dependency "autotest"
  s.add_dependency "thin"
  s.add_dependency "activesupport"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
