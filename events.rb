require 'eventmachine'
require 'google_text'
require 'yaml'

config = YAML.load_file("./config.yml")

GoogleText.configure do |c|
    c.email        = config["credentials"]["username"]
    c.password     = config["credentials"]["password"]
end

module Dispatcher 

  def forwarding_numbers

    if !logged_in? then
      login
    end
    page = session.get("https://www.google.com/voice#phones")

    forwarderDataBlock      = /^\s*'phones':.*,$/.match(page)

    forwarderDataBlock.to_s.scan(/\+\d{11}/)
  end

#  @@forwarding_numbers = forwarding_numbers 

#  def forwarding_numbers
#    puts @@forwarding_numbers
#  end

end

module Dispatch

  def sender
    sender = "+1"+display_number.match(/\((\d{3})\)\s*(\d{3})-(\d{4})/).captures.join.to_s
  end

  def is_dispatch?
    client.forwarding_numbers.include?(sender)
  end

  def dispatch

    body = text.match(/(.*)!!(.*)/)
    if !body
      puts "Message is not a properly formatted dispatch.  It must start with a list of recipient group codes terminated by '!!'"
    else
      groups = body[1]
      body = body[2]
    end

    #this needs google contacts magic
    recip_list = transform_list_of_group_codes_to_list_of_phone_numbers(groups)
    recip_list.each { |recip|
      dispatch = GoogleText::message.new(:text => body, :to => recip)
      dispatch.send
    }
  end

end

class GoogleText::Client
  include Dispatcher
end

class GoogleText::Message
  include Dispatch
end

EventMachine.run {
  EventMachine.add_periodic_timer(10) {
    messages = GoogleText::Message.unread

    if messages 
      messages.each { |message|
        puts message.inspect
        if message.is_dispatch?
          puts "Message is from dispatcher "+message.sender
          message.dispatch
        end
      }
    else
      puts "no new messages"
    end
  }
}

=begin

  # this is the old block to execute after 'messages.each...'
          display_number = "+1"+message.display_number.scan(/\d*/).join
          puts display_number
          puts "New message from "+display_number
          if forwardingNumbers.include?(display_number)
            puts "This message is from a dispatcher."
          else
            puts "This message is not from a dispatcher."           
          end
=end
