# frozen_string_literal: true

require 'dotenv/load'

require './src/ruby/components/persona'
require './src/ruby/components/event'

persona_path, state_key, audio_file_path = ARGV

persona = Persona.load(persona_path)

@event = Event.new(persona)
@event.dispatch('interaction-engine-started')

require './src/ruby/components/speech_engine'
require './src/ruby/components/terminator'
require './src/ruby/components/speech_manager'

Terminator.instance.event = @event
SpeechManager.instance.event = @event

Terminator.instance.register_trap!
SpeechManager.instance.start!

begin
  SpeechEngine.instance.persona = persona
  SpeechManager.instance.persona = persona

  unless audio_file_path
    if (message = persona.dig(:events, :'welcome-message-booted', :message))
      @event.dispatch('welcome-message-booted')
      SpeechManager.instance.add_to_queue(message)
    end

    SpeechManager.instance.wait!
    Terminator.instance.wait!
    return
  end

  @event.dispatch('speech-to-text-started')
  user_input = SpeechEngine.instance.hear(audio_file_path)
  @event.dispatch('speech-to-text-completed', user_input)

  require 'nano-bots'

  bot = NanoBot.new(cartridge: persona[:'cartridge-file-path'], state: state_key)

  buffer = ''
  first = true

  bot.eval(user_input) do |_content, fragment, _finished, meta|
    next if fragment.nil?

    if !meta.nil?
      @event.dispatch("nano-bot-tool-#{meta[:tool][:action]}", fragment)
    else
      buffer += fragment

      next unless persona[:'text-to-speech'][:settings][:'fragment-speech'] && buffer =~ /\.\s/

      parts = buffer.split(/\.\s/)
      dispatch_message = "#{parts[0].strip}."

      @event.dispatch('nano-bot-answer-received', dispatch_message.strip, !first)
      SpeechManager.instance.add_to_queue(dispatch_message)

      buffer = parts[1] || ''
      first = false
    end
  end

  if buffer.strip != ''
    @event.dispatch('nano-bot-answer-received', buffer.strip, !first)
    SpeechManager.instance.add_to_queue(buffer.strip)
  end

  SpeechManager.instance.wait!
  Terminator.instance.wait!

  @event.dispatch('interaction-completed')
rescue Interrupt
  Terminator.instance.terminate!
rescue StandardError => e
  @event.dispatch('error-raised', e.message)
end
