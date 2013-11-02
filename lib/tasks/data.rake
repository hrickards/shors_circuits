require 'yaml'

# Tasks to do with data
namespace :data do
  desc "import all data"
  task :import => [:environment, :clear, :import_user, :import_operators, :import_circuits] do
  end

  desc "delete all data"
  task :clear => :environment do
    User.delete_all
    Authorization.delete_all
    Circuit.delete_all
    Operator.delete_all
  end

  desc "setup a first user"
  task :import_user => :environment do
    user = YAML.load_file('lib/tasks/user.yml')
    u = User.create email: user['email'], name: user['name'], uid: user['uid']
    Authorization.create provider: user['provider'], uid: user['uid'],
      user_id: u._id
  end

  desc "import some basic, default operators to the database"
  task :import_operators => :environment do
    # Retrieve a list of default operators from a yaml file
    operators = YAML.load_file('lib/tasks/operators.yml')['operators']
    operators.each do |op_data|
      # For each operator, add it to the database with the default attribute set
      # to be true
      op = Operator.new op_data
      op.default = true
      op.save
    end
  end

  desc "setup some example circuits"
  task :import_circuits => [:environment, :import_bell_states, :import_pauli, :import_measurement, :import_qt] do
  end

  desc "setup bell states circuit"
  task :import_bell_states => :environment do
    h = Operator.find_by_symbol_and_size('H', 1)._id.to_s
    cnot = Operator.find_by_symbol_and_size('CNOT', 2)._id.to_s

    operators = [
      {
        id: 0,
        lines: [0],
        x: 43,
        y: 50,
        operator_type: 'gate',
        operator_id: h
      },
      {
        id: 1,
        lines: [0, 1],
        x: 130,
        y: 75,
        operator_type: 'gate',
        operator_id: cnot
      }
    ]

    Circuit.create c_id: Circuit.new_c_id, v_id: 1, operators: operators,
      lines: 2, name: "Bell States",
      initial_state: "|00>", world_editable: true,
      world_readable: true, uid: YAML.load_file('lib/tasks/user.yml')['uid']
  end

  desc "setup circuit demonstrating pauli gates"
  task :import_pauli => :environment do
    x = Operator.find_by_symbol_and_size('X', 1)._id.to_s
    y = Operator.find_by_symbol_and_size('Y', 1)._id.to_s
    z = Operator.find_by_symbol_and_size('Z', 1)._id.to_s

    operators = [
      {
        id: 0,
        lines: [0],
        x: 46,
        y: 50,
        operator_type: 'gate',
        operator_id: x
      },
      {
        id: 1,
        lines: [1],
        x: 123,
        y: 100,
        operator_type: 'gate',
        operator_id: y
      },
      {
        id: 2,
        lines: [2],
        x: 46,
        y: 150,
        operator_type: 'gate',
        operator_id: z
      }
    ]

    Circuit.create c_id: Circuit.new_c_id, v_id: 1, operators: operators,
      lines: 3, name: "Pauli Gates",
      initial_state: "|001>", world_editable: true,
      world_readable: true, uid: YAML.load_file('lib/tasks/user.yml')['uid']
  end

  desc "setup circuit demonstrating measurement"
  task :import_measurement => :environment do
    m = Operator.find_by_symbol_and_size('M', 1)._id.to_s

    operators = [{
      id: 0,
      lines: [0],
      x: 46,
      y: 50,
      operator_type: 'measurement',
      operator_id: m
    }]

    Circuit.create c_id: Circuit.new_c_id, v_id: 1, operators: operators,
      lines: 1, name: "Measurement",
      initial_state: "1/sqrt(2)|0>+1/sqrt(2)|1>", world_editable: true,
      world_readable: true, uid: YAML.load_file('lib/tasks/user.yml')['uid']
  end

  desc "setup quantum teleportation circuit"
  task :import_qt => :environment do
    h = Operator.find_by_symbol_and_size('H', 1)._id.to_s
    cnot = Operator.find_by_symbol_and_size('CNOT', 2)._id.to_s
    m2 = Operator.find_by_symbol_and_size('M', 2)._id.to_s
    qt = Operator.find_by_symbol_and_size('QT', 1)._id.to_s
    m = Operator.find_by_symbol_and_size('M', 1)._id.to_s

    operators = [
      {
        id: 0,
        lines: [1],
        x: 43,
        y: 100,
        operator_type: 'gate',
        operator_id: h
      },
      {
        id: 1,
        lines: [1, 2],
        x: 130,
        y: 125,
        operator_type: 'gate',
        operator_id: cnot
      },
      {
        id: 2,
        lines: [0, 1],
        x: 216,
        y: 75,
        operator_type: 'gate',
        operator_id: cnot
      },
      {
        id: 3,
        lines: [0],
        x: 321,
        y: 50,
        operator_type: 'gate',
        operator_id: h
      },
      {
        id: 4,
        lines: [0, 1],
        x: 414,
        y: 75,
        operator_type: 'measurement',
        operator_id: m2
      },
      {
        id: 5,
        lines: [2],
        x: 555,
        y: 150,
        operator_type: 'controlled',
        operator_id: qt,
        measurement_id: 4
      },
      {
        id: 6,
        lines: [2],
        x: 641,
        y: 150,
        operator_type: 'measurement',
        operator_id: m
      }
    ]

    Circuit.create c_id: Circuit.new_c_id, v_id: 1, operators: operators,
      lines: 3, name: "Quantum Teleportation",
      initial_state: "1/sqrt(2)|100>+1/sqrt(2)|000>", world_editable: true,
      world_readable: true, uid: YAML.load_file('lib/tasks/user.yml')['uid']
  end
end
