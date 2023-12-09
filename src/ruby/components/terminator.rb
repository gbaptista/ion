# frozen_string_literal: true

require './src/ruby/components/speech_manager'

require 'singleton'

class Terminator
  include Singleton

  attr_accessor :processes

  def initialize
    @processes = []
  end

  attr_writer :event

  def kill!
    @processes.each do |pid|
      Process.kill('SIGTERM', pid)
    rescue Errno::ECHILD, Errno::ESRCH
    end
  end

  def wait!
    @processes.each do |pid|
      Process.wait(pid)
    rescue Errno::ECHILD, Errno::ESRCH
    end
  end

  def terminate!
    SpeechManager.instance.clear_and_close!

    kill!
    wait!

    @event.dispatch('interaction-interrupted')

    exit!
  end

  def register_trap!
    Signal.trap('TERM') do
      terminate!
    end
  end
end
