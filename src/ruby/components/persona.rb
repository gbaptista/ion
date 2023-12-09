# frozen_string_literal: true

require 'yaml'

module Persona
  def self.load(path)
    persona = inject_environment_variables!(
      symbolize_keys(YAML.safe_load(File.read(path), permitted_classes: [Symbol]))
    )

    persona[:cartridge] = symbolize_keys(
      YAML.safe_load(File.read(persona[:'cartridge-file-path']), permitted_classes: [Symbol])
    )

    persona
  end

  def self.symbolize_keys(object)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = symbolize_keys(value)
      end
    when Array
      object.map { |e| symbolize_keys(e) }
    else
      object
    end
  end

  def self.inject_environment_variables!(node)
    case node
    when Hash
      node.each do |key, value|
        node[key] = inject_environment_variables!(value)
      end
    when Array
      node.each_with_index do |value, index|
        node[index] = inject_environment_variables!(value)
      end
    when String
      node.start_with?('ENV') ? ENV.fetch(node.sub(/^ENV./, ''), nil) : node
    else
      node
    end
  end
end
