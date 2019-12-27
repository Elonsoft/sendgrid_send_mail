defmodule SendMail do
  @moduledoc """
  Module for sending e-mails via SendGrid

  ## Configuration

  ```
  config :phoenix_seed, SendMail,
    sendgrid_api_key: System.get_env("SENDGRID_API_KEY") || "none",
    templates: [
      your_template_name: %{
        subject: "Test SendMail",
        from: %{email: "test@example.com"},
        template_id: "asdf"
      }
    ]
  ```

  ## Usage

  Create a module:

  ```
  defmodule MyApp.SendMail do
    use SendMail, otp_app: :my_app
  end
  ```

  Then you can use it like this:

  ```
  :your_template_name
  |> MyApp.SendMail.send_template(to: "someemail@example.com", with: %{
    some_data: "asdf"
  })
  ```

  or like this:

  ```
  :your_template_name
  |> MyApp.SendMail.template!(to: "someemail@example.com", with: %{})
  |> MyApp.SendMail.send_template()
  ```

  The keys in `with` argument are supplied to `dynamic_template_data`
  in your template. So if you have a template where you're using
  `{{recovery_link}}` key, make a call like this:

  ```
  MyApp.SendMail.send_template(:your_template_name, to: "xyu@cock.li", with: %{
    recovery_link: "https://yourpre.cc/ious?l=ink"
  })
  ```

  """

  defmacro __using__(opts) do
    quote do
      @config Application.get_env(unquote(opts)[:otp_app], SendMail) ||
                raise(SendMail.Exception, "Config is not provided")
      @sendgrid_api_key @config[:sendgrid_api_key] ||
                          raise(
                            SendMail.Exception,
                            "Key sendgrid_api_key is not provided in the config. Make sure it's not nil"
                          )
      @templates @config[:templates] ||
                   raise(SendMail.Exception, "Templates are not defined in config")
      @url "https://api.sendgrid.com/v3/mail/send"

      @spec template(atom(), to: String.t(), with: term()) ::
              {:ok, map()} | {:error, :no_template}

      def template(template_name, to: email, with: data) do
        case @templates[template_name] do
          nil ->
            {:error, :no_template}

          template_data ->
            personalizations = [
              %{
                to: [%{email: email}],
                dynamic_template_data: data
              }
            ]

            template_data =
              template_data
              |> Map.put(:personalizations, personalizations)

            {:ok, template_data}
        end
      end

      @spec template!(atom(), to: String.t(), with: term()) :: map()

      def template!(template_name, to: to, with: data) do
        case template(template_name, to: to, with: data) do
          {:ok, template_data} ->
            template_data

          {:error, :no_template} ->
            raise SendMail.Exception, "Template #{template_name} is not defined in the config"
        end
      end

      @spec send_template(map() | {:ok, map()}) :: :ok | {:error, SendMail.Error.t()}

      def send_template(template_data) when is_map(template_data) do
        body = Poison.encode!(template_data)

        @url
        |> HTTPoison.post(body, headers())
        |> process_response()
      end

      def send_template({:ok, template_data}), do: send_template(template_data)

      @spec send_template(atom(), to: String.t(), with: term()) ::
              :ok
              | {:error, :no_template}
              | {:error, SendMail.Error.t()}
      def send_template(template_name, to: to, with: data) do
        with {:ok, template_data} <- template(template_name, to: to, with: data) do
          template_data |> send_template()
        end
      end

      defp headers do
        [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{@sendgrid_api_key}"}
        ]
      end

      defp process_response({:ok, %HTTPoison.Response{status_code: code, body: body}})
           when code in [200, 202],
           do: :ok

      defp process_response({:ok, %HTTPoison.Response{status_code: code, body: body}}) do
        {:error, %SendMail.Error{details: body}}
      end

      defp process_response({:error, %HTTPoison.Error{reason: reason}}) do
        {:error, %SendMail.Error{details: reason}}
      end
    end
  end
end
