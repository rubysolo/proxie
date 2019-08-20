defmodule Proxie.Router do
  # stub module with default implementation
  def match(%Plug.Conn{}), do: raise("Routing table has not been defined!")
end

defmodule Proxie.RouterCompiler do
  @moduledoc """
  Compiles routing table into a dynamic module
  """

  def compile(routing_table) do
    # temporarily suppress "module redefined" warning messages
    opts = Code.compiler_options()
    Code.compiler_options(ignore_module_conflict: true)

    quote bind_quoted: [
            routing_table: Macro.escape(routing_table),
            module_name: Proxie.Router],
          location: :keep do
      defmodule module_name do
        def match(conn) do
          do_match(conn.host, String.reverse(conn.host), conn.request_path)
        end

        for {host, routes} <- routing_table do
          for route <- routes do
            h = Proxie.RouterCompiler.build_host_matcher(host)
            m = Proxie.RouterCompiler.build_path_matcher(route.match)
            def do_match(_, unquote(h), unquote(m)), do: unquote(Macro.escape(route))
          end
        end

        # fallback
        def do_match(host, _, path), do: raise("Route not found for #{host}#{path}")
      end
    end
    |> Code.eval_quoted([], __ENV__)

    # restore original compiler options
    Code.compiler_options(opts)
  end

  def build_host_matcher("*" <> host_suffix) do
    {:<>, [context: Elixir, import: Kernel], [String.reverse(host_suffix), {:_, [], Elixir}]}
  end
  def build_host_matcher(host), do: String.reverse(host)

  def build_path_matcher(match), do: match |> String.reverse() |> path_matcher()
  def path_matcher("*" <> reverse_match) do
    {:<>, [context: Elixir, import: Kernel], [String.reverse(reverse_match), {:_, [], Elixir}]}
  end
  def path_matcher(m), do: String.reverse(m)
end
