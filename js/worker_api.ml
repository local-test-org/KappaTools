class manager
    ?(timeout : float = 10.)
    () =
  object(self)
    val worker = Worker.create "worker_worker.js"
    initializer
      let () = worker##.onmessage :=
	  (Dom.handler
             (fun (response_message : string Worker.messageEvent Js.t) ->
		let response_text : string =
		  response_message##.data
		in
                let () = self#receive response_text  in
		Js._true
             ))
      in ()
    method sleep timeout = Lwt_js.sleep timeout
    method post_message (message_text : string) : unit =
      worker##postMessage(message_text)
    inherit Mpi_api.manager ~timeout:timeout ()
  end
