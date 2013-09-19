class Latex
  def initialize(code, width, height)
    @code = code
    @width = width || 100
    @height = height || 100
    # true if and only if width or height have been passed
    @custom_dimensions = width || height || false
    @custom_width = width || false
    @custom_height = height || false
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
      system "lib/latex2svg #{@name}"
    end
    # Unless latex2svg was successful, use a placeholder SVG
    copy_placeholder unless File.exist? self.svg_name
    return File.read self.svg_name
  end

  # Copy a placeholder image to self.svg_name. Used when SVG generation fails
  def copy_placeholder
    FileUtils.cp File.expand_path("lib/placeholder.svg"), self.svg_name
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
    # Call even if svg generated to make sure not scaled
    d = self.svg
    width = d.scan(/\swidth="([\d]*)[a-zA-Z]*"\s/).first.first.to_f
    height = d.scan(/\sheight="([\d]*)[a-zA-Z]*"\s/).first.first.to_f

    aspect_ratio = width/height
    passed_aspect_ratio = @width/@height
    # If generated image is too wide, and a width was passed, or if no height was passed
    if (aspect_ratio > passed_aspect_ratio and @custom_width) or not (@custom_height)
      # Resize using the passed width
      new_width = @width
      new_height = @width / aspect_ratio
    # Else if generated image is too narrow and a height was passed, or if no width was passed
    else
      # Resize using the passed height
      new_width = aspect_ratio * @height
      new_height = @height
    end

    # Only reconvert the PNG if it doesn't already exist
    unless File.exist? self.png_name
      # Call inkscape to convert the svg into a png
      system "inkscape -z -e #{self.png_name} -w #{new_width} -h #{new_height} #{self.svg_name}"
    end
    return File.read self.png_name
  end

  def image(format)
    case format.to_sym
    when :png
      return self.png
    else
      return self.svg_scale
    end
  end

  # Generate the LaTeX document from the code passed (the code doesn't include
  # the documentclass, etc)
  def document
    return "\\documentclass{minimal}\n\\input{Qcircuit}\n\\pagestyle{empty}\n\\begin{document}\n#{@code}\n\\end{document}"
  end

  def self.qcircuit(code, format, width, height)
    tex = "\\Qcircuit @C=1em @R=0em {#{code}}"
    latex = self.new tex, width, height
    return latex.image format
  end

  def self.ket(code, format, width, height)
    return self.qcircuit "\\ket{#{code}}", format, width, height
  end

  def self.math(code, format, width, height)
    tex = "$#{code}$"
    latex = self.new tex, width, height
    return latex.image format
  end
end
