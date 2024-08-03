if Code.ensure_loaded?(ExSync) && function_exported?(ExSync, :register_group_leader, 0) do
  ExSync.register_group_leader()
end

global_iex_path = Path.expand("~/.iex.exs")
if File.exists?(global_iex_path), do: Code.eval_file("~/.iex.exs")
import_if_available(JaxIEx)
