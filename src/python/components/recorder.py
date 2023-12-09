import struct
import subprocess
import tempfile
import wave

class Recorder:
    def __init__(self, monitor, persona):
        self.sample_width = 2
        self.sample_rate = monitor.porcupine.sample_rate

        self.monitor = monitor
        self.settings = persona['voice-engine']['settings']

    def record(self, event):
        frames = self.collect_audio_until_silence_or_limit()
        event.dispatch('audio-recorded')
        if frames:
            return self.create_audio_file_from(frames)
        else:
            return None

    def collect_audio_until_silence_or_limit(self):
        frames = []
        max_frames = self.sample_rate * self.settings['maximum-recording-duration']['seconds']
        silent_frames_threshold = self.sample_rate * self.settings['duration-of-silence-to-stop-recording']['seconds'] / self.monitor.porcupine.frame_length
        min_valid_frames = self.sample_rate * self.settings['minimum-recording-duration-to-be-a-valid-input']['seconds']
        frame_count = 0
        silent_frames = 0

        while frame_count < max_frames:
            frame = self.monitor.frame_from_an_audio_sample()

            if not self.monitor.does_it_have_someone_speaking(frame):
                silent_frames += 1
                if silent_frames >= silent_frames_threshold:
                    break
            else:
                silent_frames = 0

            packed_frame = struct.pack('h' * len(frame), *frame)
            frames.append(packed_frame)
            frame_count += len(frame)

        if frame_count >= min_valid_frames:
            return frames
        else:
            return None

    def create_audio_file_from(self, frames):
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as file:
            with wave.open(file.name, 'wb') as writer:
                writer.setnchannels(1)
                writer.setsampwidth(self.sample_width)
                writer.setframerate(self.sample_rate)
                writer.writeframes(b''.join(frames))
            return file.name
