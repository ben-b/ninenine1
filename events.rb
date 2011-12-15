require 'eventmachine'
require 'google_text'
require 'yaml'
require 'json'

config = YAML.load_file("./config.yml")

GoogleText.configure do |c|
    c.email        = config["credentials"]["username"]
    c.password     = config["credentials"]["password"]
end

module Dispatcher 

  def page(url="https://www.google.com/voice#phones")
    if !logged_in? then
      login
    end

    session.get(url)
  end

  def contactsDataBlock
    url	= "https://www.google.com/voice/c/b/"+account.email+"/ui/ContactManager"
    JSON.parse(/initContactData = (.*?);/.match(page(url))[1]) 
  end

  def contacts
    # this array needs to be parsed into a hash so that contacts
    # can be looked up by group id numbers.  those are also the only
  end

=begin

  # well, that was a lot of work and fancy regex dancing down the tubes :/

  def groups
    contactsDataBlock[2].to_s.scan(/\{.*?\}/)
  end

  def groups_hash
    id = "none"
    gh = Hash.new

    groups.each { |group|
      group.match(/\{(.*)\}/)[1].split(",").each { |pair|
        /"(.*)":"?(.*[^"])/.match(pair) { |m|
          if m[1]=="id"
            id = m[2]
          elsif m[1]=="Name"
            gh[m[2]] = id
          end
        }
      }
    }
    group_hash = gh
  end

=end

  def forwarderDataBlock
    /^\s*'phones':.*,$/.match(page)
  end

  def forwarding_numbers
    forwarderDataBlock.to_s.scan(/\+\d{11}/)
  end

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
    # recip_list = transform_list_of_group_codes_to_list_of_phone_numbers(groups)
    #recip_list.each { |recip|
    #  dispatch = GoogleText::message.new(:text => body, :to => recip)
    #  dispatch.send
    #}
  end

end

class GoogleText::Client
  include Dispatcher
end

class GoogleText::Message
  include Dispatch
end

=begin
#EventMachine.run {
#  EventMachine.add_periodic_timer(10) {
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
#  }
#}
=end
