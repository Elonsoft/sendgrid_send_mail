# SendgridSendMail

Module for sending e-mails via SendGrid

## Configuration

```elixir
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

```elixir
defmodule MyApp.SendMail do
  use SendMail, otp_app: :my_app
end
```

Then you can use it like this:

```elixir
:your_template_name
|> MyApp.SendMail.send_template(to: "someemail@example.com", with: %{
  some_data: "asdf"
})

```
or like this:

```elixir
:your_template_name
|> MyApp.SendMail.template!(to: "someemail@example.com", with: %{})
|> MyApp.SendMail.send_template()
```

## Installation

```elixir
def deps do
  [
    {
      :sendgrid_send_mail,
      github: "Elonsoft/sendgrid_send_mail",
      branch: "master"
    }
  ]
end
```
