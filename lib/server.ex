defmodule Proxie.Server do
  # stores dynamic routing table
  # proxies request to appropriate backends

  # TODO : make dynamic (compiled?)
  def configure(routing_table) do
    Proxie.RouterCompiler.compile(routing_table)
  end

  def call(conn) do
    # construct URL based on host header and path
    # read incoming request
    # make outgoing request
  end

  def outgoing_request(conn) do
    route = Proxie.Router.match(conn.host, conn.request_path)
    prefix =
      route.match
      |> String.replace("/*", "/")
    path =
      String.replace(conn.request_path, prefix, route.base_path)

    Map.put_new(route, :path, path)
  end
end
