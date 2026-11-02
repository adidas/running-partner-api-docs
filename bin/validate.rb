#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

ROOT = File.expand_path('..', __dir__)
SPEC_PATH = File.join(ROOT, 'openapi/generated/partner-api.v0.yaml')
HTTP_METHODS = %w[get post put patch delete options head trace].freeze

def fail_validation(message)
  abort "Validation failed: #{message}"
end

def collect_refs(value, refs = [])
  case value
  when Hash
    value.each do |key, child|
      refs << child if key == '$ref'
      collect_refs(child, refs)
    end
  when Array
    value.each { |child| collect_refs(child, refs) }
  end
  refs
end

def resolve_pointer(document, pointer)
  pointer.delete_prefix('#/').split('/').reduce(document) do |current, segment|
    key = segment.gsub('~1', '/').gsub('~0', '~')
    fail_validation("unresolved reference #{pointer}") unless current.is_a?(Hash) && current.key?(key)

    current.fetch(key)
  end
end

spec = YAML.safe_load(File.read(SPEC_PATH), aliases: true)
fail_validation('OpenAPI version must be 3.x') unless spec.fetch('openapi').start_with?('3.')
fail_validation("expected 6 paths, found #{spec.fetch('paths').size}") unless spec.fetch('paths').size == 6

operations = spec.fetch('paths').values.flat_map do |path_item|
  path_item.select { |key, _value| HTTP_METHODS.include?(key) }.values
end
fail_validation("expected 10 operations, found #{operations.size}") unless operations.size == 10

refs = collect_refs(spec)
external_refs = refs.reject { |ref| ref.is_a?(String) && ref.start_with?('#/') }
fail_validation("non-internal references: #{external_refs.join(', ')}") unless external_refs.empty?
refs.each { |ref| resolve_pointer(spec, ref) }

spec.fetch('paths').each do |path, path_item|
  placeholders = path.scan(/{([^}]+)}/).flatten
  next if placeholders.empty?

  path_item.each do |method, operation|
    next unless HTTP_METHODS.include?(method)

    parameters = Array(path_item['parameters']) + Array(operation['parameters'])
    parameter_names = parameters.map do |parameter|
      parameter = resolve_pointer(spec, parameter.fetch('$ref')) if parameter.key?('$ref')
      parameter['name'] if parameter['in'] == 'path' && parameter['required'] == true
    end.compact
    missing = placeholders - parameter_names
    fail_validation("#{method.upcase} #{path} is missing path parameters: #{missing.join(', ')}") unless missing.empty?
  end
end

schemes = spec.dig('components', 'securitySchemes')
fail_validation('missing Partner client credentials flow') unless schemes.dig('Partner', 'flows', 'clientCredentials')
fail_validation('missing user authorization code flow') unless schemes.dig('Partner-in-behalf-of-User', 'flows', 'authorizationCode')

scopes = schemes.dig('Partner-in-behalf-of-User', 'flows', 'authorizationCode', 'scopes')
%w[pa_activity_read pa_activity_write].each do |scope|
  fail_validation("missing #{scope} scope") unless scopes.key?(scope)
end
fail_validation('legacy pa_activity scope must remain marked deprecated') unless scopes.fetch('pa_activity').include?('DEPRECATED')

serialized = YAML.dump(spec)
fail_validation('obsolete /v0/authentication link remains') if serialized.include?('/v0/authentication')
fail_validation('legacy Swagger localhost reference remains') if serialized.include?('http://localhost/spec')
fail_validation('generated contract still requires deprecated pa_activity') if operations.any? do |operation|
  Array(operation['security']).any? { |requirement| Array(requirement['Partner-in-behalf-of-User']).include?('pa_activity') }
end

puts "Validated 6 paths, 10 operations, #{refs.size} references, and #{scopes.size} OAuth scopes"