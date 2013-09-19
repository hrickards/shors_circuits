require 'shellwords' 

class Circuit
  include MongoMapper::Document

  # key <name>, <type>
  key :operators, Array
  key :lines, Integer

  key :c_id, Integer
  key :v_id, Integer

  timestamps!

  def ensure_values
    @lines = 2 if @lines.nil?
    @operators = [] if @operators.nil?
    return self
  end

  def run
    xs = {}
    circuit = @operators
      .map { |op| op["oid"] = op["id"]; op }
      .sort { |x, y| x["x"] <=> y["x"] }
      .each_with_index.map { |op, i| op["id"] = i; op }
    circuit.map! do |op|
      op["measurementId"] = circuit.select { |op2| op2["oid"] == op["measurementId"] }.first["id"] if op["operatorType"] == "controlled"

      op
    end

    register_size = @lines
    input_register = [1] + [0] * (2 ** register_size - 1)

    input = {
      circuit: circuit,
      register_size: register_size,
      input_register: input_register
    }
    output = `lib/quantum_simulation.py #{Shellwords.escape(JSON.generate(input))}`.strip.gsub(/^'|'$/, '')
    @results = JSON.parse(output).map do |result|
      Hash[result.map { |k, v| [k.camelize.camelize(:lower), v] }]
    end
  end

  def results
    @results
  end

  def self.new_v_id(c_id)
    (self.find_all_by_c_id(c_id).map { |doc| doc.v_id }.max || 0) + 1
  end

  def self.new_c_id
    (self.all.map { |doc| doc.c_id }.max || 0) + 1
  end
end
