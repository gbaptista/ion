# frozen_string_literal: true

module Player
  def self.play!(path, volume = 1)
    command = "mpv --volume=#{(volume.to_f * 100).to_i} #{path}"
    pid = Process.spawn(command, out: '/dev/null', err: '/dev/null')
    Process.detach(pid)
    pid
  end
end
