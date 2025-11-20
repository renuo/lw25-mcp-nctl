require "mcp"
require "json"
require "open3"

module ProjectResources
  module_function

  URI_PREFIX = "resource://lw25-mcp-nctl/app/".freeze

  def resources
    apps = fetch_apps
    @apps_by_uri = apps.each_with_object({}) { |app, memo| memo[to_uri(app)] = app }

    apps.map do |app|
      MCP::Resource.new(
        uri: to_uri(app),
        name: "#{app_namespace(app)}-#{app_name(app)}",
        description: "Application #{app_name(app)} in namespace #{app_namespace(app)}",
        mime_type: "application/json"
      )
    end
  end

  def read_handler
    proc do |params|
      @apps_by_uri ||= fetch_apps.each_with_object({}) { |app, memo| memo[to_uri(app)] = app }
      app = @apps_by_uri[params[:uri]]

      if app.nil?
        @apps_by_uri = fetch_apps.each_with_object({}) { |fresh_app, memo| memo[to_uri(fresh_app)] = fresh_app }
        app = @apps_by_uri[params[:uri]]
      end

      next [] unless app

      app['spec'] = {}

      [{
        uri: to_uri(app),
        mimeType: "application/json",
        text: JSON.pretty_generate(app)
      }]
    end
  end

  def fetch_apps
    cmd = %w[nctl get app -A -o json]
    stdout, stderr, status = Open3.capture3(*cmd)

    unless status.success?
      warn "Failed to fetch applications: #{stderr.strip.empty? ? status.inspect : stderr.strip}"
      return []
    end

    parse_apps(stdout)
  rescue JSON::ParserError => e
    warn "Failed to parse applications JSON: #{e.message}"
    []
  end

  def parse_apps(payload)
    data = JSON.parse(payload)
    items =
      if data.is_a?(Hash) && data["items"].is_a?(Array)
        data["items"]
      elsif data.is_a?(Array)
        data
      else
        []
      end

    items.filter_map do |item|
      next unless item.is_a?(Hash)
      ns = app_namespace(item)
      name = app_name(item)
      next if ns.to_s.strip.empty? || name.to_s.strip.empty?
      item
    end
  end

  def to_uri(app)
    "#{URI_PREFIX}#{app_namespace(app)}/#{app_name(app)}"
  end

  def app_namespace(app)
    (app["metadata"] || {})["namespace"].to_s
  end

  def app_name(app)
    (app["metadata"] || {})["name"].to_s
  end
end
