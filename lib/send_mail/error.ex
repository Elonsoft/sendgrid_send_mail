defmodule SendMail.Error do
  defstruct [:details]

  @type t() :: %__MODULE__{}
end
