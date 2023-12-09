class M:
    @staticmethod
    def dig(container, *keys):
        for key in keys:
            if isinstance(container, (dict, list, tuple)) and key in container:
                container = container[key]
            else:
                return None
        return container
