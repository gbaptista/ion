# frozen_string_literal: true

require 'singleton'

require './src/ruby/components/terminator'
require './src/ruby/components/speech_engine'
require './src/ruby/components/player'

class SpeechManager
  include Singleton

  attr_writer :event
  attr_accessor :persona

  def initialize
    @pending_queue = Queue.new
    @text_queue = Queue.new
    @audio_queue = Queue.new
  end

  def start!
    start_text_queue!
    start_audio_queue!
  end

  def clear_and_close!
    @pending_queue.clear
    @text_queue.clear
    @audio_queue.clear

    @pending_queue.close
    @text_queue.close
    @audio_queue.close
  end

  def start_text_queue!
    Thread.new do
      loop do
        text = @text_queue.pop
        next if @text_queue.closed? || text.nil?

        @audio_queue << {
          audio: SpeechEngine.instance.to_speech(text),
          text: text
        }
      end
    end
  end

  def start_audio_queue!
    Thread.new do
      loop do
        audio = @audio_queue.pop
        next if @audio_queue.closed? && audio.nil?

        @event.dispatch('speaking-started', audio[:text])

        pid = Player.play!(audio[:audio], persona.dig(:events, :'speaking-started', :volume) || 1)
        Terminator.instance.processes << pid

        begin
          Process.wait(pid)
        rescue Errno::ECHILD, Errno::ESRCH
        end

        @pending_queue.pop
      end
    end
  end

  def wait!
    until @audio_queue.empty? && @text_queue.empty? && @pending_queue.empty?
    end
  end

  def add_to_queue(text)
    @pending_queue << true
    @text_queue << text
  end
end
