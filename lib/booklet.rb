#
#  booklet.rb
#
#  Copyright (c) 2021 by Daniel Kelley
#

require 'optparse'
require 'yaml'
require 'victor'
require_relative 'cipher'

class Booklet

  attr_reader :ok

  NL_MAGIC = "<<NL>>"
  COVER_PAGES = 2
  ANSWER_PAGES = 1
  LAYOUT = {
    "four_up" => {
      :page_height => 11.0,
      :page_width => 8.5,
      :char_height => 0.25,
      :char_width => 0.25,
      :line_limit => 4.0,
      :subpage_per_page => 4,
      :char_style => "font-size:0.25;font-family:'URW Bookman'",
      :clue_style => "font-size:0.12;font-family:'URW Bookman'",
      :guide => [
        # vertical
        [  0.500,  0.000,  0.500,  0.250],
        [  2.125,  0.000,  2.125,  0.250],
        [  3.750,  0.000,  3.750,  0.250],
        [  4.750,  0.000,  4.750,  0.250],
        [  6.375,  0.000,  6.375,  0.250],
        [  8.000,  0.000,  8.000,  0.250],
        [  8.000, 10.750,  8.000, 11.000],
        # horizontal
        [  0.000,  0.500,  0.250,  0.500],
        [  0.000,  5.000,  0.250,  5.000],
        [  0.000,  6.000,  0.250,  6.000],
        [  0.000, 10.500,  0.250, 10.500],
        [  8.250, 10.500,  8.500, 10.500],
      ]

    },

    "two_up" => {
      :page_width => 11.0,
      :page_height => 8.5,
      :char_height => 0.25,
      :char_width => 0.25,
      :line_limit => 4.5,
      :subpage_per_page => 2,
      :char_style => "font-size:0.25;font-family:'URW Bookman'",
      :clue_style => "font-size:0.12;font-family:'URW Bookman'",
      :guide => [
        # vertical
        [  0.500,  0.000,  0.500,  0.250],
        [  5.000,  0.000,  5.000,  0.250],
        [  6.000,  0.000,  6.000,  0.250],
        [ 10.500,  0.000, 10.500,  0.250],
        [ 10.500,  8.250, 10.500,  8.500],
        # horizontal
        [  0.000,  0.500,  0.250,  0.500],
        [  0.000,  8.000,  0.250,  8.000],
        [ 10.750,  8.000, 11.000,  8.000],
      ]

    }
  }

  def initialize(argv)
    @ok = false
    @seed = nil
    @file = nil
    @quote = []
    @layout = "four_up"
    @help = false
    @debug = false
    @argv = argv

    options

    if !@help
      raise "no file" if @argv.length == 0
      raise "too many args" if @argv.length > 1
      raise "layout #{@layout} not found" if LAYOUT[@layout].nil?
      @file = argv[0]
      @base = File.basename(@file, ".yml")
      srand(@seed) if !@seed.nil?
      @ok = true
    end
  end

  def options
    @opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($0)} [options]"
      opts.on('--help', '-h', 'Issue this message') do
        puts opts
        @help = true
      end
      opts.on('--layout [LAYOUT]', '-L', 'Layout') do |arg|
        @layout = arg
      end
      opts.on('--seed [SEED]', '-S', 'Random Seed') do |arg|
        @seed = arg.nil? ? 1 : arg.to_i
      end
      opts.on('--debug', '-d', 'Debug') do
        @debug = true
      end
    end
    @opts.parse!(@argv)
  end

  def page_height
    LAYOUT[@layout][:page_height]
  end

  def page_width
    LAYOUT[@layout][:page_width]
  end

  def char_height
    LAYOUT[@layout][:char_height]
  end

  def char_width
    LAYOUT[@layout][:char_width]
  end

  def char_style
    LAYOUT[@layout][:char_style]
  end

  def clue_style
    LAYOUT[@layout][:clue_style]
  end

  def line_limit
    LAYOUT[@layout][:line_limit]
  end

  def guide
    LAYOUT[@layout][:guide]
  end

  def subpage_per_page
    LAYOUT[@layout][:subpage_per_page]
  end

  # return true if all lines are blank
  def only_whitespace?(item)
    a = item.split("\n")
    n = 0
    a.each do |line|
      n += 1 if !(line =~ /^\s*$/).nil?
    end
    n == a.length
  end

  def scan
    data = File.open(@file) { |yf| YAML::load(yf) }
    data.each do |item|
      next if only_whitespace?(item)
      @quote << encipher(item)
    end
  end

  def encipher(text)
    puts "encipher(#{text})" if @debug
    Cipher.new(text)
  end

  def content(n)
    if n == 0
      return "Title Page" # front
    elsif n == (@total-1)
      return "Back Matter" # rear (back)
    elsif n == (@total-2)
      return "Answer key" # answer
    elsif n >= 1 && n < (@total-@blank-2)
      q = @quote[(n-1)]
      raise "oops #{n}" if q.nil?
      return [q.crypt.upcase,q.clue] # content
    else
      return "Blank" # blank
    end
  end

  def layout_quote(svg, text, x, y)
    start = x
    limit = line_limit + x
    cur_x = x
    cur_y = y
    a = []
    quote = []
    puts "#{text} #{x} #{y}" if @debug
    # newline preservation: substitute newlines for magic char seqence
    txt = text.gsub("\n", " #{NL_MAGIC} ")
    txt.split.each do |word|
      puts "--#{word} #{x} #{y}" if @debug
      if (cur_x > limit || word == NL_MAGIC)
        puts "------#{a.inspect} #{start} #{cur_y}"  if @debug
        quote << [a.join(" "), start, cur_y]
        cur_x = x
        cur_y += char_height*3 # space for writing cleartext
        a.clear
      end
      puts "----#{word}" if @debug
      if word != NL_MAGIC
        a << word
        cur_x += (word.length+1)*char_width
      end
    end
    if a.length > 0
        puts "------#{a.inspect} #{start} #{cur_y}" if @debug
        quote << [a.join(" "), start, cur_y]
    end
    quote.each do |line|
      svg.text(line[0], x: line[1], y: line[2], style: char_style)
    end
  end

  def layout_clue(svg, text, x, y)
    s = "Clue: " + short_clue(text)
    svg.text(s,
             transform:"translate(#{x}, #{y}) rotate(180)",
             "text-anchor":"middle",
             "dominant-baseline":"central",
             style:clue_style)
  end

  def guide_marks(svg)
    guide.each do |a|
      svg.line(x1: a[0],
               y1: a[1],
               x2: a[2],
               y2: a[3],
               stroke: "red",
               stroke_width: "0.010")
    end
  end

  def page_counts
    quotes = @quote.length
    text_pages = quotes + COVER_PAGES + ANSWER_PAGES

    @blank = text_pages % subpage_per_page
    if @blank != 0
      @blank = subpage_per_page - @blank
    end
    total = text_pages + @blank
    pages = total / subpage_per_page
    if pages.odd?
      # add some more blanks to make an even number of full pages
      @blank += subpage_per_page
      total += subpage_per_page
      pages += 1
    end

    @total = total
    puts "SVG base:#{@base} pages:#{pages} quotes:#{quotes} text:#{text_pages} blank:#{@blank} total:#{@total}"
    raise 'oops' if (@total % subpage_per_page) != 0

    pages
  end


  # +---+---+
  # | a | b |
  # +---+---+
  # | d | c |
  # +---+---+
  def svg_four_up
    pages = page_counts
    a = 0
    b = @total - 1
    c = @total / 2
    d = c - 1
    pages.times do |n|
      sheet_no = (n/2)+1
      side = n.even? ? "f" : "b"
      name = "#{@base}-#{sheet_no}-#{side}"
      puts "  #{n} #{name}"
      if @debug
        puts "#{n}: #{a} #{b} #{c} #{d}"
        puts "#{n}: #{content(a)} #{content(b)} #{content(c)} #{content(d)}"
      end
      spa,cla = content(a)
      spb,clb = content(b)
      spc,clc = content(c)
      spd,cld = content(d)
      page_attr = {
        width: "#{page_width}in",
        height: "#{page_height}in",
        viewBox: "0 0 #{page_width} #{page_height}" # xmin ymin xmax ymax
      }

      svg = Victor::SVG.new(page_attr)
      #svg.text(spa,         x: 1.0, y: 1.0, style: char_style)
      layout_quote(svg, spa,   0.5,    0.75)
      layout_clue( svg, cla,   3.0,    4.5) if !cla.nil?

      svg.text("#{a}", x: 2.1, y: 5.0, style: char_style) # page

      #svg.text(spb,         x: 6.5, y: 1.0, style: char_style)
      layout_quote(svg, spb,   4.7,    0.75)
      layout_clue( svg, clb,   7.7,    4.5) if !clb.nil?
      svg.text("#{b}", x: 6.3, y: 5.0, style: char_style)

      #svg.text(spc,         x: 6.5, y: 6.5, style: char_style)
      layout_quote(svg, spc,   4.7,    6.25)
      layout_clue( svg, clc,   3.0,   10.0) if !clc.nil?
      svg.text("#{c}", x: 6.3, y: 10.5, style: char_style)

      #svg.text(spd,         x: 1.0, y: 6.5, style: char_style)
      layout_quote(svg, spd,   0.5,    6.25)
      layout_clue( svg, cld,   7.7,   10.0) if !cld.nil?
      svg.text("#{d}", x: 2.1, y: 10.5, style: char_style)

      #svg.text("a:#{a} b:#{b} c:#{c} d:#{d}",
      #         x: 1.0, y: 8.0, style: char_style)

      guide_marks(svg)


      svg.save(name)
      a += 1
      b -= 1
      c += 1
      d -= 1
    end
  end

  # +---+---+
  # | a | b |
  # +---+---+
  def svg_two_up
    pages = page_counts
    a = 0
    b = @total - 1
    pages.times do |n|
      sheet_no = (n/2)+1
      side = n.even? ? "f" : "b"
      name = "#{@base}-#{sheet_no}-#{side}"
      puts "  #{n} #{name}"
      if @debug
        puts "#{n}: #{a} #{b} #{c} #{d}"
        puts "#{n}: #{content(a)} #{content(b)} #{content(c)} #{content(d)}"
      end
      spa,cla = content(a)
      spb,clb = content(b)
      page_attr = {
        width: "#{page_width}in",
        height: "#{page_height}in",
        viewBox: "0 0 #{page_width} #{page_height}" # xmin ymin xmax ymax
      }

      svg = Victor::SVG.new(page_attr)
      #svg.text(spa,         x: 1.0, y: 1.0, style: char_style)
      layout_quote(svg, spa,   0.5,    0.75)
      layout_clue( svg, cla,   7.5,    4.0) if !cla.nil?
      svg.text("#{a}", x: 2.75, y: 8.0, style: char_style) # page

      #svg.text(spb,         x: 6.5, y: 1.0, style: char_style)
      layout_quote(svg, spb,   6.0,    0.75)
      layout_clue( svg, clb,  10.5,    7.5) if !clb.nil?
      svg.text("#{b}", x: 8.25, y: 8.0, style: char_style)

      guide_marks(svg)

      svg.save(name)

      a += 1
      b -= 1
    end
  end

  def svg
    self.method("svg_#{@layout}").call
  end

  def html_header(title)
    return <<EOF
<html>
  <head>
    <title>#{title}</title>
  </head>
  <body>
EOF
  end

  def html_trailer
    return <<EOF
  </body>
</html>
EOF
  end

  def html_row(*a)
    s = "<tr>"
    a.each do |item|
      s << "<td>"
      if item.respond_to? :each_line
        item.each_line do |line|
          s << "\n<br>"
          s << line
          s << "</br>"
        end
      else
        s << item.to_s
      end
      s << "</td>"
    end
    s << "</tr>"
  end

  def short_clue(clue)
    a = clue.split
    a[1]
  end

  def html_long_clue(clue)
    a = clue.split # title clue clear crypt
    s = "<br>#{a[0]} #{a[1]}</br>\n"
    n = 26
    clear = a[2][1..-2]
    crypt = a[3][1..-2]
    raise "oops #{clear.length} #{clear.inspect} #{n*2}" if clear.length != n*2
    raise 'oops' if crypt.length != n*2
    s << "<table border='1'>\n"
    s << "<tr><th>Crypt</th><th>Clear</th></tr>\n"
    n.times do |i|
      j = i*2
      q = clear[j,2]
      r = crypt[j,2]
      s << "<tr><td>#{r}</td><td>#{q}</td></tr>\n"
    end
    s << "</table>\n"
    s
  end

  def html_answer_page(idx)
    q = @quote[idx]
    page_no = idx+1
    file = "#{@base}_answer_#{page_no}.html"
    File.open(file, "w") do |fd|
      fd.puts html_header("#{@base} Answer #{page_no}")
      fd.puts "<h2>#{@base} Page #{page_no}</h2>"
      fd.puts "<h3>Quote</h3>"
      fd.puts "<br>#{q.text}</br>"
      fd.puts "<h3>Encrypted</h3>"
      fd.puts "<br>#{q.crypt.upcase}</br>"
      fd.puts "<h3>Clue</h3>"
      fd.puts html_long_clue(q.clue)
      fd.puts html_trailer
    end
    "<a href=\"#{file}\">Answer</a>"
  end

  def html_file(name,title)
    File.open(name, "w") do |fd|
      fd.puts html_header(title)
      fd.puts "<table border='1'>"
      fd.puts "<tr><th>Page</th><th>Clue</th><th>Answer</th></tr>"
      @quote.each_with_index do |q,idx|
        page_no = idx+1
        fd.puts html_row(page_no, short_clue(q.clue), html_answer_page(idx))
      end
      fd.puts "</table>"
      fd.puts html_trailer
    end
  end


  def html
    html_file("#{@base}_answer.html", "Answer")
  end

end
