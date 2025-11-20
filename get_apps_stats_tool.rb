require "mcp"

class GetAppsStatsTool < MCP::Tool
  description "Print the command that needs to be run to get stats off all application of a specific project"
  input_schema(
    properties: {
      project: {type: "string"}
    },
    required: ["project"]
  )

  class << self
    def call(project:, server_context:)
      MCP::Tool::Response.new([{
        type: "text",
        text: "nctl get apps -p renuo-remms -o stats"
      }])
    end
  end
end
