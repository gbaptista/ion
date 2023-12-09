# frozen_string_literal: true

require 'time'

require './src/ruby/components/player'

class Event
  def initialize(persona)
    @persona = persona
  end

  def dispatch(event_key, content = nil, silent = false)
    event_key = event_key.to_sym

    output = Time.now.iso8601.to_s

    output += " #{@persona[:meta][:symbol]}" if @persona.dig(:meta, :symbol)

    output += ' >'

    unless @persona.dig(:events, event_key)
      output = "#{output} [#{event_key}]"
      output += " #{content}" if content
      puts output
      return
    end

    event = @persona[:events][event_key]

    output += if event[:symbol] == 'nano-bot-cartridge' && @persona.dig(:cartridge, :meta, :symbol)
                " #{@persona[:cartridge][:meta][:symbol]}"
              elsif event[:symbol]
                " #{event[:symbol]}"
              else
                " [#{event_key}]"
              end

    output += " #{event[:message]}" if event[:message]

    output += " #{content}" if content

    puts output

    Player.play!(event[:audio], event[:volume] || 1) if event[:audio] && !silent
  end
end
