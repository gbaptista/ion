import sys
import subprocess
import threading
import time
import secrets

from src.python.components.persona import Persona
from src.python.components.monitor import Monitor
from src.python.components.recorder import Recorder
from src.python.components.event import Event
from src.python.helpers.map import M

class MainApplication:
    def __init__(self, persona_path):
        self.persona_path = persona_path
        self.persona = Persona.load(persona_path)
        self.event = Event(self.persona)
        
        self.event.dispatch('monitor-engine-started')

        self.state_key = f'ion-{secrets.token_hex(16)}'

        if (M.dig(self.persona, 'events', 'welcome-message-booted', 'message')
            and M.dig(self.persona, 'events', 'welcome-message-booted', 'speak')):
            command = ["bundle", "exec", "ruby", "main.rb", self.persona_path, self.state_key]
            subprocess.run(command)
        else:
            self.event.dispatch('welcome-message-booted')
        
        self.monitor = Monitor(self.persona)
        self.recorder = Recorder(self.monitor, self.persona)
        
        self.current_subprocess = None
        self.just_terminated = False
        self.just_completed = False

    def run_subprocess(self, command):
        self.current_subprocess = subprocess.Popen(command)
        self.current_subprocess.wait()
        self.just_completed = True
        self.current_subprocess = None

    def run(self):
        try:
            self.event.dispatch('listening-and-waiting')

            self.monitor.start_listening()

            while True:
                if self.just_terminated or self.just_completed or self.monitor.has_wake_word_been_detected():
                    if self.current_subprocess:
                        self.event.dispatch('interruption-requested')
                        self.current_subprocess.terminate()
                        self.current_subprocess.wait()
                        self.current_subprocess = None
                        self.just_terminated = True
                    else:
                        if not self.just_terminated and not self.just_completed:
                            self.event.dispatch('awake-and-recording')
                        else:
                            self.event.dispatch('recording-follow-up')

                        recorded_audio_file_path = self.recorder.record(self.event)

                        if recorded_audio_file_path:
                            self.event.dispatch('audio-stored')
                            command = ["bundle", "exec", "ruby", "main.rb",
                                       self.persona_path, self.state_key, recorded_audio_file_path]

                            threading.Thread(target=self.run_subprocess, args=(command,)).start()
                        else:
                            if not self.just_terminated and not self.just_completed:
                                self.event.dispatch('audio-discarded')
                            else:
                                self.event.dispatch('no-follow-up-received')

                        self.just_terminated = False
                        self.just_completed = False

        except KeyboardInterrupt:
            print("Stopping...")

        finally:
            self.monitor.destroy()

def main():
    persona_path = sys.argv[1]
    app = MainApplication(persona_path)
    app.run()

if __name__ == "__main__":
    main()
