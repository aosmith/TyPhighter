# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "TyPhighter/version"

Gem::Specification.new do |s|
  s.name        = "TyPhighter"
  s.version     = Typhighter::VERSION
  s.authors     = ["Alex Smith"]
  s.email       = ["aosmith@gmail.com"]
  s.homepage    = ""
  s.summary     = "TyPhighter is a multithreaded http gem."
  s.description = "http://dumbhipster.com/"

  s.rubyforge_project = "TyPhighter"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
