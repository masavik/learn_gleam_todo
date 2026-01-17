import envoy
import gleam/erlang/process

import gleam/http
import gleam/result
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist

fn middleware(req: Request, handler: fn(Request) -> Response) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)

  handler(req)
}

fn get_todos_handler() -> Response {
  wisp.ok()
  |> wisp.string_body("GET Todos")
}

fn post_todos_handler() -> Response {
  wisp.created()
}

fn todos_handler(req: Request) -> Response {
  case req.method {
    http.Get -> get_todos_handler()
    http.Post -> post_todos_handler()
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn get_todo_handler(id: String) -> Response {
  wisp.ok()
  |> wisp.string_body("GET Todo with ID: " <> id)
}

fn delete_todo_handler(_id: String) -> Response {
  wisp.no_content()
}

fn todo_handler(req: Request, id: String) -> Response {
  case req.method {
    http.Get -> get_todo_handler(id)
    http.Delete -> delete_todo_handler(id)
    _ -> wisp.method_not_allowed([http.Get, http.Delete])
  }
}

fn handler(req: Request) -> Response {
  use _ <- middleware(req)

  case wisp.path_segments(req) {
    ["todos"] -> todos_handler(req)
    ["todo", id] -> todo_handler(req, id)
    _ -> wisp.not_found()
  }
  // wisp.ok()
  // |> wisp.string_body("Hello from Wisp and Gleam")
}

pub fn main() -> Nil {
  // The following statement configures the logger
  wisp.configure_logger()

  // Wisp requires a unique secret so we use `envoy`
  // to read it from the environment variable
  let secret =
    result.unwrap(envoy.get("SECRET_KEY_BASE"), "wisp_secret_fallback")

  let assert Ok(_) =
    wisp_mist.handler(handler, secret)
    // pub fn handler(
    //   handler: fn(request.Request(wisp.Connection)) -> response.Response(
    //     wisp.Body,
    //   ),
    //   secret_key_base: String,
    // ) -> fn(request.Request(mist.Connection)) -> response.Response(
    //   mist.ResponseData,
    // )
    |> mist.new
    // pub fn new(
    //   handler: fn(request.Request(in)) -> response.Response(out),
    // ) -> Builder(in, out)
    |> mist.port(18_080)
    // pub fn port(
    //   builder: Builder(in, out),
    //   port: Int,
    // ) -> Builder(in, out)
    |> mist.start
  // pub fn start(
  //   builder: Builder(Connection, ResponseData),
  // ) -> Result(
  //   actor.Started(static_supervisor.Supervisor),
  //   actor.StartError,
  // )
  // `Connection` is a Re-exported type that represents the default `Request` body type. See
  // `mist.read_body` to convert this type into a `BitString`. The `Connection`
  // also holds some additional information about the request. Currently, the
  // only useful field is `client_ip` which is a `Result` with a tuple of
  // integers representing the IPv4 address.
  // pub type Connection =
  //   InternalConnection
  process.sleep_forever()
}
