defmodule SendMail.Exception do
  defexception [:message]

  @impl true
  def exception(message), do: %__MODULE__{message: message}
end
