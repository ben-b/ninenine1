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

    ch = Hash.new
    number = nil

    contactsDataBlock["Body"]["Contacts"].each { |contact|
    if contact.has_key?("Phones")
      contact["Phones"].each { |phone|
        if phone["Type"]["Id"] == "MOBILE"
          number = phone["Number"].match(/^[\+]?[1]?\D*(\d{3})?\D*(\d{3})\D*(\d{4})/)
          if number
            number = "+1"+number.captures.join
            ga = []
            contact["Groups"].each { |group|

               if ch.has_key?(group["id"])
                 ch[group["id"]].push(number)
               else
                 ch[group["id"]] = [number]
               end

            }

          else
#            puts phone["Number"]+" is not a valid phone number!"
          end
        else
#          puts phone["Number"]+" is not a cell.  it won't do any good to text it."
        end
      }
    end
    }

    contacts = ch

  end

  def groups
    gh = Hash.new
    contactsDataBlock["Body"]["Groups"].each { |group|
      gh[group["Name"]] = group["id"]
    }
    groups = gh 
  end

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

  def first_responders(groups=client.forwarding_numbers)

    fr_a = []

    groups.each { |group_name|
     client.contacts[client.groups[group_name]].each { |number|

        if !fr_a 
          fr_a = [number]
        elsif !fr_a.include?(number)
          fr_a.push(number)
        end

      }
    }
    first_responders = fr_a

  end

  def dispatch

    body = text.match(/(.*)!!(.*)/)
    if !body
      puts "Message is not a properly formatted dispatch.  It must start with a list of recipient group codes terminated by '!!'"
    else
      groups = body[1].split(" ")
      body = body[2]
    end

    first_responders(groups).each { |fr|
      dispatch = GoogleText::Message.new(:text => body, to => fr)
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

#EventMachine.run {
# EventMachine.add_periodic_timer(10) {
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
