task :default => :build

desc "Build a standalone executable that you can put anywhere"
task :build do
  outfile = "bin/gemfile-standalone"
  infile  = "bin/gemfile-from-dotgems"
  open("bin/gemfile-standalone", "w") { |f|
    f.write \
      IO.read(infile).gsub(/^require (File.*)/) {
        IO.read(eval($1.gsub(/\b__FILE__\b/, infile.inspect)) + ".rb").sub(/\A(#.*\n)*/, '') } }
  system("chmod", "755", outfile)
end
