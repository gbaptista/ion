# frozen_string_literal: true

require 'openai'

require './src/ruby/components/provider'

class OpenAIProvider < Provider
  DEFAULT_ADDRESS = 'https://api.openai.com'

  attr_reader :persona

  def initialize(persona)
    @persona = persona
  end

  def client
    @client ||= OpenAI::Client.new(
      uri_base: OpenAIProvider.uri_base(persona),
      access_token: persona[:credentials][:'access-token']
    )
  end

  def to_text(audio_file_path)
    client.audio.transcribe(
      parameters: {
        model: persona[:settings][:model],
        file: File.open(audio_file_path, 'rb')
      }
    )['text']
  end

  def to_speech(message)
    client.audio.speech(
      parameters: {
        model: persona[:settings][:model],
        voice: persona[:settings][:voice],
        input: message
      }
    )
  end

  def self.uri_base(persona)
    if persona[:credentials][:address].nil? || persona[:credentials][:address].to_s.strip.empty?
      "#{DEFAULT_ADDRESS}/"
    else
      "#{persona[:credentials][:address].to_s.sub(%r{/$}, '')}/"
    end
  end
end
