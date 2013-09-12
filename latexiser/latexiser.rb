# Returns various things formatted nicely using the LaTeX package QCircuit
class Latexiser
  def initialize(code, width, height)
    @code = code
    @width = width || 100
    @height = height || 100
    # true if and only if width or height have been passed
    @custom_dimensions = width || height || false
    # width and height need to be integral
    @width = @width.to_i
    @height = @height.to_i

    # Create a hash of various properties to give temporary filenames
    # and also allow easy caching
    @hash = Digest::SHA2.new << @code << @width.to_s << @height.to_s
    @name = "/tmp/latexiser_#{@hash}"
  end

  # Assuming the tex file already exists, generates an svg using latex2svg
  # latex2svg is a wrapper shell script that compiles the tex into a PDF,
  # removes any whitespace and creates an svg. See lib/scripts/latex2svg.
  def svg
    # Only recompile the SVG if it doesn't already exist
    unless File.exist? self.svg_name
      File.open("#{@name}.tex", 'w') { |f| f.write document }
      # TODO Catch pdflatex errors
      system "latex2svg #{@name}"
    end
    # Unless latex2svg was successful, use a placeholder SVG
    copy_placeholder unless File.exist? self.svg_name
    return File.read self.svg_name
  end

  # Copy a placeholder image to self.svg_name. Used when SVG generation fails
  def copy_placeholder
    FileUtils.cp File.expand_path("lib/images/placeholder.svg"), self.svg_name
  end

  # Returns a scaled version of the SVG
  def svg_scale
    # Use the normal svg method, unless a custom width or height have been
    # passed
    return self.svg unless @custom_dimensions

    # Use regex to substitute the width and height attributes of the
    # SVG. Remember, sub only substitutes the first occurence.
    d = self.svg
    d.sub! /\swidth="[\da-zA-Z]*"\s/, " width=\"#{@width}px\" "
    d.sub! /\sheight="[\da-zA-Z]*"\s/, " height=\"#{@height}px\" "
    return d
  end

  def svg_name
    return "#{@name}.svg"
  end

  def png_name
    return "#{@name}.png"
  end

  def png
    # Only reconvert the PNG if it doesn't already exist
    unless File.exist? self.png_name
      # Call inkscape to convert the svg into a png
      system "inkscape -z -e #{self.png_name} -w #{@width} -h #{@height} #{self.svg_name}"
    end
    return File.read self.png_name
  end

  # Given some latex code, an image format, width and height return an image
  def self.image(code, format, width, height)
    l = self.new code, width, height

    case format.to_sym
    when :png
      # l.png doesn't create the svg, it just converts it, so l.svg has to be
      # called first
      l.svg
      return l.png
    else
      l.svg_scale
    end
  end

  # Given the symbol (code) for a gate, the number of inputs it has (num) and
  # the image format, width and height, return an image for the gate circuit
  # symbol
  def self.gate(code, num, format, width, height)
    self.multi code, num, "gate", true, format, width, height
  end

  # Given the symbol (code) for a observable, the number of inputs it has (num)
  # and the image format, width and height, return an image for the observable
  # circuit symbol
  def self.observable(code, num, format, width, height)
    if code.downcase == "standard" and num == 1
      self.meter format, width, height
    else
      self.multi code, num, "measure", false, format, width, height
    end
  end

  # Given the number for a qubit and the image format, width and height, produce
  # a ket circuit symbol (|n>)
  def self.ket(num, format, width, height)
    tex = "\\Qcircuit @C=1em @R=0em {"
    tex << "\\ket{#{num}}"
    tex << "}"

    self.image tex, format, width, height
  end

  def self.qcircuit(code, format, width, height)
    tex = "\\Qcircuit @C=1em @R=0em {#{code}}"

    self.image tex, format, width, height
  end

  private
  # Return the standard meter circuit symbol for a 1-qubit observable
  # with standard as the symbol
  def self.meter(format, width, height)
    tex = "\\Qcircuit @C=1em @R=0em {"
    tex << "& \\meter{}"
    tex << "}"
    self.image tex, format, width, height
  end

  # Returns the tex code for a multiple-input ___ (gate/ket/etc)
  # See the QCircuit documentation for details
  def self.multi(code, num, type, qw, format, width, height)
    num -= 1

    tex = "\\Qcircuit @C=1em @R=0em {"

    if num == 0
      tex << "& \\#{type}{#{code}}"
      tex << "& \\qw" if qw
    else
      tex << "& \\multi#{type}{#{num}}{#{code}}"
      tex << "& \\qw" if qw
      tex << "\\\\"
      (num-1).times do
        tex << "& \\ghost{#{code}}"
        tex << "& \\qw" if qw
        tex << "\\\\"
      end 
      tex << "& \\ghost{#{code}}"
      tex << "& \\qw" if qw
    end

    tex << "}"

    self.image tex, format, width, height
  end

  # Generate the LaTeX document from the code passed (the code doesn't include
  # the documentclass, etc)
  def document
    return "\\documentclass{minimal}\n\\input{Qcircuit}\n\\pagestyle{empty}\n\\begin{document}\n#{@code}\n\\end{document}"
  end
end
