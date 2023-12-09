import os
import yaml

class Persona:
    @staticmethod
    def load(path):
        with open(path, 'r') as file:
            data = yaml.safe_load(file)
        return Persona._inject_environment_variables(data)

    @staticmethod
    def _inject_environment_variables(node):
        if isinstance(node, dict):
            for key, value in node.items():
                node[key] = Persona._inject_environment_variables(value)
        elif isinstance(node, list):
            for index, value in enumerate(node):
                node[index] = Persona._inject_environment_variables(value)
        elif isinstance(node, str) and node.startswith('ENV'):
            return os.getenv(node[4:], None)
        return node
