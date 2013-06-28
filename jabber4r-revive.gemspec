# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jabber4r/version"

Gem::Specification.new do |gem|
  gem.name          = "jabber4r-revive"
  gem.version       = Jabber::VERSION
  gem.authors       = ["Richard Kilmer", "Sergey Fedorov"]
  gem.email         = ["rich@infoether.com", "strech_ftf@mail.ru"]
  gem.description   = "The purpose of this library is to allow Ruby applications to  talk to a Jabber IM system. Jabber is an open-source instant  messaging service, which can be learned about at http://www.jabber.org"
  gem.summary       = "Read more http://jabber4r.rubyforge.org"
  gem.homepage      = "https://github.com/Strech/jabber4r-revive"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "ox", "~> 2.0.4"
  gem.add_dependency "virtus", "~> 0.5.4"

  gem.add_development_dependency "rspec", "~> 2.13.0"
  gem.add_development_dependency "webmock", "~> 1.11.0"
  gem.add_development_dependency "changelogger", "~> 0.0.3"
end
