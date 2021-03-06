# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Broker::Application.config.secret_token = 'be714beb6a20e3bb1ac7fb915d963fce18c58ea8fe983f2ca000d0cb962ab925e342486727a5196b09da8b380371b0934b03bbf6197d6a252afda7710e5a7118'

conf_file = if Rails.env.development?
  File.join(OpenShift::Config::CONF_DIR, 'broker-dev.conf')
else
  File.join(OpenShift::Config::CONF_DIR, 'broker.conf')
end
conf = OpenShift::Config.new(conf_file)

auth_salt = conf.get("AUTH_SALT")
if auth_salt.blank?
  raise "\nYou must set AUTH_SALT in #{conf_file}."
elsif auth_salt == "ClWqe5zKtEW4CJEMyjzQ"
  Rails.logger.error "\nERROR: You are using the default value for for AUTH_SALT in #{conf_file}!"
end
