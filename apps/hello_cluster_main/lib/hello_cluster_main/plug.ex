defmodule HelloClusterMain.Plug do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/greet" do
    text_resp(conn, 200, HelloClusterMain.greet())
  end

  get "/greet/:name" do
    text_resp(conn, 200, HelloClusterMain.greet(conn.path_params["name"]))
  end

  get "/cluster_info" do
    reply =
      [:this, :visible]
      |> Node.list()
      |> Enum.join(", ")

    text_resp(conn, 200, reply)
  end

  match _ do
    text_resp(conn, 404, "Not Found")
  end

  defp text_resp(conn, status, text) do
    conn
    |> put_resp_header("content-type", "text/plain")
    |> send_resp(status, [text, ?\n])
  end
end
