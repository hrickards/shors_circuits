MongoMapper.connection = Mongo::Connection.new('localhost', nil, :logger => logger)

case Padrino.env
  when :development then MongoMapper.database = 'quantum_development'
  when :production  then MongoMapper.database = 'quantum_production'
  when :test        then MongoMapper.database = 'quantum_test'
end
