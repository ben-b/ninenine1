require 'eventmachine'
require 'google_text'
require 'yaml'

config = YAML.load_file("./config.yml")

GoogleText.configure do |c|
    c.email        = config["credentials"]["username"]
    c.password     = config["credentials"]["password"]
end

EventMachine.run {
  EventMachine.add_periodic_timer(10) {
    messages = GoogleText::Message.unread
      if messages
	#puts GoogleText::Message.unread.inspect
        messages.each { |message|
          display_number = message.display_number.scan(/\d*/).join
          puts "New message from \+1"+display_number
        }
      else
        puts "no new messages"
      end
  }
}
