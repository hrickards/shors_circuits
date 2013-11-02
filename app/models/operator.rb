require 'matrix'

class Operator
  include MongoMapper::Document

  # key <name>, <type>
  key :type, String
  key :name, String
  key :symbol, String
  key :size, Integer
  # Use array rather than matrix as just string types for symbolicness
  key :matrix, Array
  key :uid, String
  key :default, Boolean

  timestamps!

  # Obtain a latex representation of the matrix
  def latex_matrix
    if @type == "controlled"
      @matrix.map { |value, matrix| [value, latex_matrix_for(matrix)] }
    else
      latex_matrix_for @matrix
    end
  end

  private
  def latex_matrix_for(matrix)
    # Use sympy to parse the matrix and output it as LaTeX
    output = `lib/matrix_parser.py #{Shellwords.escape(JSON.generate({matrix: matrix}))}`.strip.gsub(/^'|'$/, '')
    return JSON.parse(output)['matrix']
  end
end
