# frozen_string_literal: true

class Provider
  def client
    raise NotImplementedError
  end

  def to_text(_audio_file_path)
    raise NotImplementedError
  end

  def to_speech(_message)
    raise NotImplementedError
  end
end
