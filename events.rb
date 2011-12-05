require 'eventmachine'
require 'google_text'
require 'yaml'

config = YAML.load_file("./config.yml")

GoogleText.configure do |c|
    c.email        = config["credentials"]["username"]
    c.password     = config["credentials"]["password"]
end

client  = GoogleText::Client.new

if !client.logged_in? then
        client.login
end

page            = client.session.get("https://www.google.com/voice#phones")

forwarderDataBlock      = /^\s*'phones':.*,$/.match(page)

forwardingNumbers       = forwarderDataBlock.to_s.scan(/(\+\d{11,11})/)

p forwardingNumbers[1][0]

EventMachine.run {
  EventMachine.add_periodic_timer(10) {
    messages = GoogleText::Message.unread
      if messages
	#puts GoogleText::Message.unread.inspect
        messages.each { |message|
          display_number = "+1"+message.display_number.scan(/\d*/).join
          puts display_number
          puts "New message from "+display_number
          if forwardingNumbers.include?(display_number)
            p "This message is from a dispatcher."
          else
            p "This message is not from a dispatcher."           
          end

        }
      else
        puts "no new messages"
      end
  }
}
