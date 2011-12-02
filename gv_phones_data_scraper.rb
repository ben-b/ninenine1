require 'google_text'
require 'yaml'

include Curl

config = YAML.load_file("./config.yml")

GoogleText.configure do |c|
	c.email		= config["credentials"]["username"]
	c.password	= config["credentials"]["password"]
end

client 	= GoogleText::Client.new

client.login

page 		= client.session.get("https://www.google.com/voice#phones")
forwarders 	= /^\s*'phones':.*,$/.match(page)
contacts 	= /^\s*'contacts':.*,$/.match(page)
contactPhones	= /^\s*'contactPhones':.*,$/.match(page)

# parse forwarders to build a list of dispatchers' numbers
# parse contacts or contactPhones to build a list of responder groups
#	and their numbers
