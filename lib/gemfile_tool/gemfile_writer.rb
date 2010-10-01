#!/usr/bin/env ruby
# encoding: UTF-8
require 'stringio'

class GemfileWriter
  def initialize(gems_hash)
    @io           = StringIO.new
    gems_by_group = gems_hash.inject({}) { |h, (k, v)| (h[v[:group]]||={})[k] = v; h }
    sources       = gems_hash.values.map { |options| options[:source] }.compact.uniq
    sources      -= %w[ http://gems.rubyforge.org http://gemcutter.org http://rubygems.org ]
    @io.puts "source :rubygems"
    sources.each { |source| @io.puts "source #{source.inspect}" }
    gems_by_group.entries.sort_by { |k, v| k.to_s }.each do |group, gems|
      @io.puts
      @io.puts "group #{group.inspect} do" if group
      gems.each do |name, options|
        @io.print "  " if group
        @io.puts  "gem #{[name, options[:version]].compact.map(&:inspect).join(', ')}"
      end
      @io.puts "end" if group
    end
  end

  def string
    @io.string
  end
  alias_method :to_s, :string

  def write(path = "Gemfile")
    open(path, "w") { |io| io.write string }
  end
end
