#
#  encipher.rb
#
#  Copyright (c) 2020 by Daniel Kelley
#

require 'yaml'
require_relative 'cipher'
require_relative 'booklet'

class Encipher

  def initialize(s, idx)
    report(s, Cipher.new, idx)
  end

  def report(s, cipher, idx)
    puts "#{idx}. #{s}"
    puts cipher.encipher(s).upcase
    puts cipher.clue(s)
    puts
  end

  class << self

    def encipher_file(file)
      idx = 1
      y = yaml_load(file) do |item|
        Encipher.new(item, idx)
        idx += 1
      end
    end

    def encipher_booklet(argv)
      rc = 1
      b = Booklet.new(argv)
      if b.ok
        b.scan
        b.svg
        b.html
        rc = 0
      end
      rc
    end

    def yaml_load(f)
      data = File.open(f) { |yf| YAML::load(yf) }
      data.each do |item|
        next if item =~ /^\s*$/
        yield item
      end
    end
  end

end
