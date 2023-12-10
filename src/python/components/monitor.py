import pvporcupine
import pvcobra
from pvrecorder import PvRecorder

class Monitor:
    def __init__(self, persona):
        voice_engine = persona['voice-engine']
        provider = persona['voice-engine']['provider']

        self.porcupine = pvporcupine.create(
            access_key=provider['credentials']['access-key'],
            keywords=provider['settings']['porcupine']['keywords'],
            sensitivities=provider['settings']['porcupine']['sensitivities'])
        
        self.cobra = pvcobra.create(
            access_key=provider['credentials']['access-key'])

        self.pv_recorder = PvRecorder(
            device_index=-1,
            frame_length=self.porcupine.frame_length)

        self.voice_probability_threshold = voice_engine['settings']['voice-probability-threshold']

    def start_listening(self):
        self.pv_recorder.start()

    def frame_from_an_audio_sample(self):
        return self.pv_recorder.read()

    def has_wake_word_been_detected(self):
        return self.porcupine.process(self.frame_from_an_audio_sample()) >= 0

    def is_someone_speaking(self):
        return self.does_it_have_someone_speaking(self.frame_from_an_audio_sample())

    def does_it_have_someone_speaking(self, frame_from_an_audio_sample):
        return self.cobra.process(frame_from_an_audio_sample) > self.voice_probability_threshold

    def destroy(self):
        self.pv_recorder.delete()
        self.porcupine.delete()
        self.cobra.delete()
