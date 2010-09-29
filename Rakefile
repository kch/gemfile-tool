#!/usr/bin/env rake
# encoding: UTF-8
require 'pathname'

task :default => :build

desc "Build a standalone executable that you can put anywhere"
task :build do
  outfile = "bin/gemfile-standalone"
  infile  = "bin/gemfile-from-dotgems"
  open("bin/gemfile-standalone", "w") do |f|
    expanded_contents = IO.read(infile).gsub(/^require ([A-Z].*)/) do
      require_argument = $1
      require_argument.gsub!(/\b__FILE__\b/, infile.inspect)
      expanded_require_path = eval(require_argument).to_s
      IO.read("#{expanded_require_path}.rb").sub(/\A(#.*\n)*/, '')
    end
    f.write expanded_contents
  end
  system("chmod", "755", outfile)
end
