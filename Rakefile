require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << "tests"
  t.test_files = FileList["tests/**/*_test.rb"]
  t.verbose = true
end

task :rdoc do
  sh 'rm -r doc' if File.directory?('doc')
  begin
    sh 'sdoc --line-numbers --inline-source --main "README.rdoc" --title "MailBuilder Documentation" README.rdoc lib'
  rescue
    puts "sdoc not installed:"
    puts "  gem install voloko-sdoc --source http://gems.github.com"
  end
end

require "rake/gempackagetask"

NAME = "mail_builder"
SUMMARY = "MailBuilder is a simple library for building RFC compliant MIME emails."
GEM_VERSION = "0.2"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.summary = s.description = SUMMARY
  s.author = "Bernerd Schaefer"
  s.email = "bernerd@wieck.com"
  s.homepage = "http://wiecklabs.com"
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.files = %w(Rakefile) + Dir.glob("lib/**/*")
  s.add_dependency 'mime-types'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install MailBuilder as a gem"
task :install => [:repackage] do
  sh %{gem install pkg/#{NAME}-#{GEM_VERSION}}
end