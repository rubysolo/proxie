defmodule Proxie.ServerTest do
  use ExUnit.Case
  doctest Proxie.Server
  alias Proxie.Server

  defmodule CustomHandler do
    def call(conn) do
      IO.puts("unhandled route #{conn.host}#{conn.request_path}")
      %{host: "www.lmgtfy.com", base_path: "/"}
    end
  end

  @routing_table %{
    "api.example.com" => [
      %{match: "/api/v2/*", host: "new-hotness", base_path: "/"},
      %{match: "/api/*", host: "old-busted", base_path: "/"},
      %{match: "/status", host: "old-busted", base_path: "/healthcheck"},
      %{match: "/*", function: CustomHandler }
    ],
    "*.dev.example.com" => [
      %{match: "/status", host: "development-stack-monitor", base_path: "/status"},
      %{match: "/*", host: "development-stack", base_path: "/"}
    ]
  }

  test "exact match host, path prefix" do
    Server.configure(@routing_table)

    conn =
      Plug.Test.conn(:get, "/api/kittens")
      |> Map.put(:host, "api.example.com")

    req = Server.outgoing_request(conn)
    assert req.host == "old-busted"
    assert req.path == "/kittens"
  end

  test "exact match host, exact match path" do
    Server.configure(@routing_table)

    conn =
      Plug.Test.conn(:get, "/status")
      |> Map.put(:host, "api.example.com")

    req = Server.outgoing_request(conn)
    assert req.host == "old-busted"
    assert req.path == "/healthcheck"
  end

end
