from datetime import datetime

from src.python.components.player import Player

from src.python.helpers.map import M

class Event:
    def __init__(self, persona):
        self.persona = persona

    def dispatch(self, event_key, content=None):
        now_in_local_timezone = datetime.now().astimezone()

        output = now_in_local_timezone.replace(microsecond=0).isoformat()

        if M.dig(self.persona, 'meta', 'symbol'):
            output += ' ' + self.persona['meta']['symbol']

        output += ' >'

        if not M.dig(self.persona, 'events', event_key):
            output += ' [' + event_key + ']'
            if content:
                output += ' ' + content
            print(output)
            return

        if M.dig(self.persona, 'events', event_key, 'symbol'):
            output += ' ' + self.persona['events'][event_key]['symbol']
        else:
            output += ' [' + event_key + ']'
        
        if M.dig(self.persona, 'events', event_key, 'message'):
            output += ' ' + self.persona['events'][event_key]['message']

        if content:
            output += ' ' + content

        print(output)

        if M.dig(self.persona, 'events', event_key, 'audio'):
            Player.play(
                self.persona['events'][event_key]['audio'],
                M.dig(self.persona, 'events', event_key, 'volume') or 1)
