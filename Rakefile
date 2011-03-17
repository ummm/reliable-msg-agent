
require "rubygems"
require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "reliable-msg/agent/version"

spec = Gem::Specification.new do |s|
  s.name = "reliable-msg-agent"
  s.version = ReliableMsg::Agent::Version::STRING
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.summary = "This(it) is agent daemon for reliable-msg queue"
  s.description = s.summary
  s.executables = Dir.glob("bin/**/*").map { |f| File.basename(f) }
  s.files = %w(History.txt MIT-LICENSE README.rdoc Rakefile) + Dir.glob("{bin,ext,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
  
  s.add_dependency("reliable-msg")
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =["README.rdoc", "MIT-LICENSE", "lib/**/*.rb"]
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.rdoc" # page to start on
  rdoc.title = "reliable-msg-agent Docs"
  rdoc.rdoc_dir = "doc/rdoc" # rdoc output folder
  rdoc.options << "--line-numbers"
end

Dir["tasks/**/*.rake"].each { |t| load t }
task :default => [:spec]

