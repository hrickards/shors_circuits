require 'shellwords' 

class Circuit
  include MongoMapper::Document

  # key <name>, <type>
  key :operators, Array
  key :lines, Integer
  key :initial_state, String

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

    input = {
      circuit: circuit,
      register_size: @lines,
      input_register: @initial_state
    }
    output = `lib/quantum_simulation.py #{Shellwords.escape(JSON.generate(input))}`.strip.gsub(/^'|'$/, '')
    JSON.parse output
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