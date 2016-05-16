defmodule Dayron.Config do
  @moduledoc """
  Helpers to handle application configuration values.
  """
  alias Dayron.Model

  @doc """
  Parses the OTP configuration for compilation time.
  """
  def parse(repo, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config  = Application.get_env(otp_app, repo, [])
    adapter = opts[:adapter] || config[:adapter] || Dayron.HTTPoisonAdapter
    logger = get_logger(config)

    case parse_url(opts[:url] || config[:url]) do
      {:ok, url} -> config = Keyword.put(config, :url, url)
      {:error, :missing_url} ->
        raise ArgumentError, "missing :url configuration in " <>
                             "config #{inspect otp_app}, #{inspect repo}"
      {:error, _} ->
        raise ArgumentError, "invalid URL for :url configuration in " <>
                             "config #{inspect otp_app}, #{inspect repo}"
    end

    {otp_app, adapter, logger, config}
  end

  @doc """
  Given a config map, model and options, returns the complete url for the api
  request.

  ## Example

      > Config.get_request_url(config, MyModel, [id: id])
      "http://api.example.com/mymodels/id"
  """
  def get_request_url(config, model, opts) do
    config[:url] <> Model.url_for(model, opts)
  end

  @doc """
  Returns the headers list as set in application config
  """
  def get_headers(config) do
    Keyword.get(config, :headers, [])
  end

  @doc """
  Based on application configuration, returns a boolean indicating if reponses
  log is enabled
  """
  def get_logger(config) do
    Keyword.get(config, :logger, Dayron.BasicLogger)
  end

  @doc """
  Returns a `%Dayron.Request` with provided data and application config
  """
  def init_request_data(config, method, model, opts \\ []) do
    %Dayron.Request{
      method: method,
      url: get_request_url(config, model, opts),
      body: opts[:body],
      headers: get_headers(config),
      options: opts[:options]
    }
  end

  @doc """
  Parses the application configuration :url key, accepting system env or a
  binary
  """
  def parse_url({:system, env}) when is_binary(env) do
    parse_url(System.get_env(env) || "")
  end

  def parse_url(url) when is_binary(url) do
    info = url |> URI.decode() |> URI.parse()

    if is_nil(info.host), do: {:error, :invalid_url}, else: {:ok, url}
  end

  def parse_url(_), do: {:error, :missing_url}
end
