#!/usr/bin/env ruby
# encoding: UTF-8

class RubyFileWrapper
  attr_reader :path, :contents, :lines, :active_lines, :squashed

  def initialize(path)
    @path         = path.to_s
    @contents     = File.exists?(@path) ? IO.read(@path).gsub(/\r\n?/, "\n") : ""
    @lines        = @contents.lines.to_a
    @active_lines = @lines.reject { |line| line =~ /\A\s*(#.*)?\s*\z/m }
    @squashed     = lines.map { |line| line.sub(/#(?!\{).*\z/m, '') }.join.gsub(/\s+/, '')
    [@path, @contents, @active_lines, @squashed].each(&:freeze)
  end

  def rewrite(contents = lines.join)
    contents = contents.sub(/\A\s+/, '').sub(/\s+\z/, "\n")
    open(@path, 'w') { |io| io.write contents }
  end

  def include?(other)
    squashed.include?(other.squashed)
  end

  class ConfigHash < Hash
    def gem(k, h = {})
      self[k] = h
    end
  end

  def extract_gems!(group = File.basename(@path, '.rb').to_sym)
    config    = ConfigHash.new
    gem_lines = active_lines.grep(/\A\s*config\.gem\b/)
    @lines   -= gem_lines
    gem_lines.map { |line| line.sub(/\b(unless|if)\b.*/, '') }.each { |s| eval(s) rescue nil }
    config.values.each   { |h| h.keys.each { |k| h[k.to_sym] = h.delete(k) } }
    config.values.select { |h| h.key? :lib }.each { |h| h[:require] = h.delete(:lib) }
    config.values.each   { |h| h[:group] = group } if group
    rewrite
    config
  end
end
