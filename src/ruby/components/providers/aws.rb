# frozen_string_literal: true

require 'aws-sdk-polly'

require './src/ruby/components/provider'

class AWSProvider < Provider
  attr_reader :persona

  def initialize(persona)
    @persona = persona
  end

  def client
    @client ||= Aws::Polly::Client.new(
      access_key_id: persona[:credentials][:'access-key'],
      secret_access_key: persona[:credentials][:'secret-key'],
      region: persona[:credentials][:region]
    )
  end

  def to_speech(message)
    client.synthesize_speech(
      {
        output_format: 'mp3',
        # text_type: 'ssml',
        text: message,
        voice_id: persona[:settings][:voice_id],
        engine: persona[:settings][:engine]
      }
    ).audio_stream.read
  end
end
