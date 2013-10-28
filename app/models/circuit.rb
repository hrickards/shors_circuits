require 'shellwords' 

class Circuit
  include MongoMapper::Document

  # key <name>, <type>
  key :operators, Array
  key :lines, Integer
  key :initial_state, String

  key :c_id, Integer
  key :v_id, Integer

  key :uid, String

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

    operators = %w{gate measurement controlled}.map do |type|
      @operators
        .select { |o| o["operator_type"] == type }
        .map { |o| Operator.find o["operator_id"] }
        .map do |o|
          h = {
            id: o.id.to_s,
            name: o.name
          }
          if type == "controlled"
            h[:matrices] = Hash[o.matrix]
            h[:values] = o.matrix.map { |k, v| k }
          else
            h[:matrix] = o.matrix
          end

          h
        end
    end

    input = {
      circuit: circuit,
      register_size: @lines,
      input_register: @initial_state,
      gates: operators[0],
      measurements: operators[1],
      controlled_gates: operators[2]
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
    (self.all.map { |doc| doc.c_id }.reject(&:nil?).max || 0) + 1
  end

  def iterations
    self.class.find_all_by_c_id(self.c_id).map do |c|
      {
        v_id:  c.v_id,
        c_id: c.c_id,
        modified: c.updated_at.strftime("%b %d %Y"),
        current: c.v_id == self.v_id
      }
    end
  end
end
