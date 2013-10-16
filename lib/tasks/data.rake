require 'yaml'

# Tasks to do with data
namespace :data do
  desc "import some basic, default operators to the database"
  task :import => :environment do
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
end
