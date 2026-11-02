#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'yaml'

class GenerateOAS
  HTTP_METHODS = %w[get post put patch delete options head trace].freeze
  ROOT = File.expand_path('..', __dir__)
  SOURCE = File.join(ROOT, 'openapi/source')
  MANIFEST = File.join(SOURCE, 'manifest.yaml')
  OUTPUT = File.join(ROOT, 'openapi/generated/partner-api.v0.yaml')

  def run
    manifest = load_yaml(MANIFEST)
    document = load_yaml(source_path(manifest.fetch('base')))
    document['paths'] = {}
    document['components'] = { 'schemas' => {} }
    @schemas = document['components']['schemas']

    manifest.fetch('components').each do |relative_path|
      path = source_path(relative_path)
      components = resolve_file_refs(load_yaml(path).fetch('components'), File.dirname(path))
      merge_component_groups!(document['components'], components, relative_path)
    end

    manifest.fetch('paths').each do |relative_path|
      path = source_path(relative_path)
      paths = resolve_file_refs(load_yaml(path).fetch('paths'), File.dirname(path))
      merge_unique!(document['paths'], paths, "paths from #{relative_path}")
    end

    validate!(document)

    FileUtils.mkdir_p(File.dirname(OUTPUT))
    File.write(OUTPUT, YAML.dump(document))
    puts "Generated #{relative_to_root(OUTPUT)}"
  end

  private

  def load_yaml(path)
    YAML.safe_load(File.read(path), aliases: true)
  rescue Errno::ENOENT
    abort "Missing OpenAPI source: #{path}"
  end

  def source_path(relative_path)
    File.expand_path(relative_path, SOURCE)
  end

  def merge_unique!(target, additions, label)
    duplicates = target.keys & additions.keys
    abort "Duplicate #{label}: #{duplicates.join(', ')}" unless duplicates.empty?

    target.merge!(additions)
  end

  def merge_component_groups!(target, additions, relative_path)
    additions.each do |group, values|
      target[group] ||= {}
      merge_unique!(target[group], values, "components.#{group} in #{relative_path}")
    end
  end

  def resolve_file_refs(value, current_directory)
    case value
    when Hash
      if file_reference?(value['$ref'])
        return { '$ref' => register_schema(value.fetch('$ref'), current_directory) }
      end

      value.transform_values { |child| resolve_file_refs(child, current_directory) }
    when Array
      value.map { |child| resolve_file_refs(child, current_directory) }
    else
      value
    end
  end

  def file_reference?(reference)
    reference.is_a?(String) && !reference.start_with?('#/')
  end

  def register_schema(reference, current_directory)
    path_part, fragment = reference.split('#', 2)
    abort "Unsupported external reference: #{reference}" if path_part.match?(%r{\Ahttps?://})

    absolute_path = File.expand_path(path_part, current_directory)
    component_name = schema_name(absolute_path, fragment)
    return "#/components/schemas/#{component_name}" if @schemas.key?(component_name)

    @schemas[component_name] = {}
    schema = load_yaml(absolute_path)
    schema = resolve_fragment(schema, fragment, reference) if fragment
    @schemas[component_name] = resolve_file_refs(schema, File.dirname(absolute_path))
    "#/components/schemas/#{component_name}"
  end

  def resolve_fragment(value, fragment, reference)
    fragment.delete_prefix('/').split('/').reduce(value) do |current, segment|
      key = segment.gsub('~1', '/').gsub('~0', '~')
      abort "Unresolved fragment in #{reference}" unless current.is_a?(Hash) && current.key?(key)

      current.fetch(key)
    end
  end

  def schema_name(absolute_path, fragment)
    relative = Pathname.new(absolute_path).relative_path_from(Pathname.new(SOURCE)).to_s
    [relative.sub(/\.ya?ml\z/, ''), fragment].compact.join('_').gsub(/[^A-Za-z0-9._-]+/, '_')
  end

  def validate!(document)
    %w[openapi info paths components].each do |key|
      abort "Generated OpenAPI is missing #{key}" unless document.key?(key)
    end

    operation_count = document.fetch('paths').values.sum do |path_item|
      path_item.keys.count { |key| HTTP_METHODS.include?(key) }
    end
    abort "Expected 6 paths, found #{document.fetch('paths').size}" unless document.fetch('paths').size == 6
    abort "Expected 10 operations, found #{operation_count}" unless operation_count == 10

    serialized = YAML.dump(document)
    abort 'Generated OpenAPI contains a remote $ref' if serialized.match?(/^\s*\$ref:\s+https?:\/\//)
    abort 'Generated OpenAPI contains a file $ref' if serialized.match?(/^\s*\$ref:\s+(?!['"]?#\/)/)
  end

  def relative_to_root(path)
    Pathname.new(path).relative_path_from(Pathname.new(ROOT)).to_s
  end
end

GenerateOAS.new.run