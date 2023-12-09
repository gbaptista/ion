# frozen_string_literal: true

require 'singleton'

require './src/ruby/components/providers/aws'
require './src/ruby/components/providers/openai'
require './src/ruby/components/providers/google'
require './src/ruby/components/player'

class SpeechEngine
  include Singleton

  attr_writer :persona

  def speech_to_text_provider_id
    @speech_to_text_provider_id ||= @persona[:'speech-to-text'][:provider][:id]
  end

  def text_to_speech_provider_id
    @text_to_speech_provider_id ||= @persona[:'text-to-speech'][:provider][:id]
  end

  def speech_to_text_provider
    @speech_to_text_provider ||= case speech_to_text_provider_id
                                 when 'openai'
                                   OpenAIProvider.new(@persona[:'speech-to-text'][:provider])
                                 when 'aws'
                                   AWSProvider.new(@persona[:'speech-to-text'][:provider])
                                 when 'google'
                                   GoogleProvider.new(@persona[:'speech-to-text'][:provider])
                                 else
                                   raise "Unsupported Speech to Text Provider: \"#{text_to_speech_provider_id}\""
                                 end
  end

  def text_to_speech_provider
    @text_to_speech_provider ||= case text_to_speech_provider_id
                                 when 'openai'
                                   OpenAIProvider.new(@persona[:'text-to-speech'][:provider])
                                 when 'aws'
                                   AWSProvider.new(@persona[:'text-to-speech'][:provider])
                                 when 'google'
                                   GoogleProvider.new(@persona[:'text-to-speech'][:provider])
                                 else
                                   raise "Unsupported Text to Speech Provider: \"#{text_to_speech_provider_id}\""
                                 end
  end

  def create_playable_mp3_file(binary)
    tempfile = Tempfile.create(['speech', '.mp3'])
    File.binwrite(tempfile.path, binary)
    tempfile.path
  end

  def hear(audio_file_path)
    speech_to_text_provider.to_text(audio_file_path)
  end

  def to_speech(message)
    binary = text_to_speech_provider.to_speech(message)
    create_playable_mp3_file(binary)
  end
end
