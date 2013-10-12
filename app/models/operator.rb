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

  timestamps!
end
