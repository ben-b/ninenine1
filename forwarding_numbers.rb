require 'google_text'
require 'yaml'

include Curl

config = YAML.load_file("./config.yml")

GoogleText.configure do |c|
	c.email		= config["credentials"]["username"]
	c.password	= config["credentials"]["password"]
end

client 	= GoogleText::Client.new

if !client.logged_in? then
	client.login
end

page 		= client.session.get("https://www.google.com/voice#phones")

forwarderDataBlock 	= /^\s*'phones':.*,$/.match(page)

forwardingNumbers	= forwarderDataBlock.to_s.scan(/(\+\d{11,11})/)

forwardingNumbers.each { |forwardingNumber|
	p forwardingNumber
}


# the below is a dumb way to interact with the contacts, since
# google already provides a stable api to contacts.  still,
# i'll leave these snippets here in case they come in handy for
# some reason.
#
#contacts 	= /^\s*'contacts':.*,$/.match(page)
#puts "contacts:\n"
#contacts.each { |contact|
#	puts contact
#}

#contactPhones	= /^\s*'contactPhones':.*,$/.match(page)

# parse forwarders to build a list of dispatchers' numbers
# parse contacts or contactPhones to build a list of responder groups
#	and their numbers
