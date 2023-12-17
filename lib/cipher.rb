#
#  cipher.rb
#
#  Copyright (c) 2020 by Daniel Kelley
#

class Cipher

  LETTERS = ('A'..'Z')

  attr_reader :text
  attr_reader :crypt
  attr_reader :clue


  def initialize(text)
    @text = text
    @clear, @subst = groomed_cipher
    @crypt = encipher(@text)
    @clue = _clue(text)
  end

  private

  # flag ciphers with identities
  def funky(clear,subst)
    clear.each_char do |letter|
      c = letter.upcase
      if c == _encipher(c, clear, subst)
        return true
      end
    end
    return false
  end

  # Groom generated cipher to remove funkyness
  def groomed_cipher
    100.times do
      clear, subst = subst_cipher
      if !funky(clear, subst)
        return [clear, subst]
      end
    end
    raise "funky cipher"
  end

  # Create substitution cipher
  def subst_cipher
    cipher = LETTERS.to_a.shuffle
    clear = ''
    subst = ''
    LETTERS.each_with_index do |letter,i|
      clear << letter
      clear << letter.downcase
      subst << cipher[i]
      subst << cipher[i].downcase
    end
    [clear, subst]
  end

  # Encipher string s
  def _encipher(s, clear, subst)
    s.tr(clear, subst)
  end

  # Encipher string s
  def encipher(s)
    t = _encipher(s, @clear, @subst)
    check(s,t)
    t
  end

  # ensure t decrypts to s
  def check(s,t)
    if (_encipher(t, @subst, @clear) != s)
      raise 'oops'
    end
  end

  # pick a letter from s and the corresponding substitution
  # Could be made harder by picking the clue from the least frequently
  # used letters.
  def _clue(s)
    1000.times do
      n = rand(s.length)
      l = s[n]
      next if l.nil?
      c = l.upcase
      if LETTERS.include?(c)
        e = encipher(c)
        return "Clue: #{e}=#{c}\n#{@clear.inspect}\n#{@subst.inspect}"
      end
    end
    raise "oops"
  end

end
