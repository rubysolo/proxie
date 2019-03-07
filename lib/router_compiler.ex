defmodule Proxie.Router do
  # stub module with default implementation
  def match(_host, _path), do: raise("Routing table has not been defined!")
end

defmodule Proxie.RouterCompiler do
  @moduledoc """
  Compiles routing table into a dynamic module
  """

  def compile(routing_table) do
    quote bind_quoted: [
            routing_table: Macro.escape(routing_table),
            module_name: Proxie.Router],
          location: :keep do
      defmodule module_name do
        for {host, routes} <- routing_table do
          for route <- routes do
            m = Proxie.RouterCompiler.build_path_matcher(route.match)
            def match(unquote(host), unquote(m)), do: unquote(Macro.escape(route))
          end
        end

        # fallback
        def match(host, path), do: raise("Route not found for #{host}#{path}")
      end
    end
    |> Code.eval_quoted([], __ENV__)
  end

  def build_path_matcher(match), do: match |> String.reverse() |> path_matcher()
  def path_matcher("*" <> reverse_match) do
    {:<>, [context: Elixir, import: Kernel], [String.reverse(reverse_match), {:_, [], Elixir}]}
  end
  def path_matcher(m), do: String.reverse(m)
end
