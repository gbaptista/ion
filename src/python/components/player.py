import subprocess

class Player:
    @staticmethod
    def play(path, volume=1):
        command = ["mpv", f"--volume={int(float(volume) * 100)}", path]
        subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
