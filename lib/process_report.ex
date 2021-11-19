defmodule ProcessReport do
  def wait_for_messages do
    receive do
      {:basic_deliver, payload, _meta} ->
        {status, result} = JSON.decode(payload)
        generate_report(result)
        wait_for_messages()
    end
  end

  def generate_report(result) do
    url = mount_jasper_url()
    HTTPoison.start
    options = [params: [
      name: result["patient_name"],
      birth_date: result["birth_date"],
      city: result["city"],
      result: result["result"]
    ]]
    { ok, body } = HTTPoison.request(:get, url, [], [], options)
    path = "reports/neomed-#{:os.system_time(:millisecond)}.pdf"
    save_file(path, body.body)
  end

  def save_file(path, file) do
    File.write!(path, file)
  end

  def mount_jasper_url() do
    report_file = "SimpleExternalJ"
    report_type = "pdf"
    "http://localhost/jasperserver/rest_v2/reports/Reports/#{report_file}.#{report_type}?j_username=jasperadmin&j_password=bitnami"
  end
end

queue = "reports_request"
{:ok, connection} = AMQP.Connection.open
{:ok, channel} = AMQP.Channel.open(connection)
AMQP.Queue.declare(channel, queue, durable: true)
AMQP.Basic.consume(channel, queue, nil, no_ack: true)
IO.puts " [*] Waiting for messages. To exit press CTRL+C, CTRL+C"

ProcessReport.wait_for_messages()
