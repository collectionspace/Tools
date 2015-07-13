require "erb"
 
module CustomConfig
 unless defined? @@env_config
 puts "Loading environments.yml..."
 env = (ENV['ENVIRONMENT'] && ENV['ENVIRONMENT'].to_sym) || :reader
 environments = YAML.load(ERB.new(File.read(File.expand_path('../../../config/environments.yml', __FILE__))).result)
 @@env_config = environments[env.to_s]
 raise "No config found for environment: #{env}" unless @@env_config
 end
 
def env_config
 @@env_config
 end
 
end
 
World(CustomConfig)