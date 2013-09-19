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
      {
        state_string: result['stateString'],
        probability_string: result['probabilityString']
      }
    end
  end

  def results
    @results
  end
end
