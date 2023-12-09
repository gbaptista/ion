# frozen_string_literal: true

require 'google/cloud/text_to_speech'

require './src/ruby/components/provider'

class GoogleProvider < Provider
  attr_reader :persona

  def initialize(persona)
    @persona = persona
  end

  def client
    @client ||= Google::Cloud::TextToSpeech.text_to_speech do |config|
      config.credentials = persona[:credentials][:'file-path']
    end
  end

  def to_speech(message)
    client.synthesize_speech(
      input: { text: message },
      voice: {
        name: persona[:settings][:name],
        ssml_gender: persona[:settings][:ssml_gender],
        language_code: persona[:settings][:language_code]
      },
      audio_config: { audio_encoding: :MP3 }
    ).audio_content
  end
end
