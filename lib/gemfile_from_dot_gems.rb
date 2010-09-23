#!/usr/bin/env ruby
# encoding: UTF-8
require 'strscan'
require 'stringio'

class GemfileFromDotGems
  class ParseError < RuntimeError; end
  attr_reader :gems

  def self.[](*a)
    new(*a).parse.gemfile
  end

  def initialize(s, filename="-")
    @s, @filename = s.gsub(/\r\n?/, "\n").sub(/\Z\n?/, "\n"), filename
  end

  def parse
    @ss   = StringScanner.new(@s)
    @gems = {}
    # tokenization
    until @ss.eos?
      @ss.skip(/^[\t ]*(#.*)?\n/) and next
      @ss.skip(/[\t ]+/)
      options     = { :pos => @ss.pos }
      name        = @ss.scan(/\S+/) or raise_parse_error("Don't know what to do with:")
      @gems[name] = options
      until @ss.skip(/\n/)
        @ss.skip(/[\t ]+/)
        if @ss.scan(/-\w|--\w\w+/) and key = @ss[0]
          @ss.skip(/[\t ]*(=[\t ]*)?/)
          @ss.scan(/'(.*?)(?!<\\)'/) or
          @ss.scan(/"(.*?)(?!<\\)"/) or
          @ss.scan(/(\S+)/)          or raise_parse_error("Expected value for key #{key} in", @ss.pos, options[:pos])
          options[key] = @ss[1]
          @ss.skip(/[\t ]+/)
        else @ss.skip(/#.*/) or raise_parse_error("Unexpected:")
        end
      end
    end
    # semantic validation
    @gems.each do |name, options|
      s = options.delete("-s") || options.delete("--source")  and options[:source]  = s
      v = options.delete("-v") || options.delete("--version") and options[:version] = v
      invalid_keys = options.keys - [:source, :version, :pos]
      invalid_keys.empty? or raise_parse_error("Invalid options for gem '#{name}': #{invalid_keys.join(",")} in", options[:pos])
    end
    self
  end

  def raise_parse_error(message, pos = @ss.pos, peek_pos = pos)
    line = @s[0...pos].scan(/\n/).length + 1
    col  = @s[0...pos].sub(/.*\n/m, '').length + 1
    peek = @s[peek_pos..-1][/\A.*/]
    raise ParseError, "#{message} #{peek.inspect} in #{@filename} line #{line}, col #{col}"
  end

  def gemfile
    StringIO.new.tap do |io|
      io.puts "source :rubygems"
      @gems.values.map { |options| options[:source] }.compact.each { |source| io.puts "source #{source.inspect}" }
      io.puts
      @gems.each { |name, options| io.puts "gem #{[name, options[:version]].compact.map(&:inspect).join(', ')}" }
    end.string
  end
end
