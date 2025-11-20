require "mcp"

class GetAppLogsTool < MCP::Tool
  description "Print the command that needs to be run to get logs of a specific app from the specified project"
  input_schema(
    properties: {
      project: {type: "string"},
      app: {type: "string"},
      lines: {type: "integer", default: 5000}
    },
    required: ["project", "app"]
  )

  class << self
    def call(project:, app:, lines:, server_context:)
      MCP::Tool::Response.new([{
        type: "text",
        text: "nctl logs app --lines #{lines} --project #{project} #{app}"
      }])
    end
  end
end
