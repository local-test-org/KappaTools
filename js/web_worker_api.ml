(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2019 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

open Lwt.Infix

class manager () =
  let kasa_worker = Worker.create "KaSaWorker.js" in
  let kasa_mailbox = Kasa_client.new_mailbox () in
  let kamoha_worker = Worker.create "KaMoHaWorker.js" in
  let kamoha_mailbox = Kamoha_client.new_mailbox () in
  let kastor_worker = Worker.create "KaStorWorker.js" in
  let stor_state,update_stor_state = Kastor_client.init_state () in
  object(self)
    val sim_worker = Worker.create "KaSimWorker.js"
    val mutable is_running = true
    initializer
      let () = kasa_worker##.onmessage :=
          (Dom.handler
             (fun response_message ->
                let response_text = response_message##.data in
                let () = Common.debug response_text in
                let () = Kasa_client.receive kasa_mailbox response_text in
                Js._true
             )) in
      let () = kamoha_worker##.onmessage :=
          (Dom.handler
             (fun response_message ->
                let response_text = response_message##.data in
                let () = Common.debug response_text in
                let () = Kamoha_client.receive kamoha_mailbox response_text in
                Js._true
             )) in
      let () = kastor_worker##.onmessage :=
          (Dom.handler
             (fun response_message ->
                let response_text = response_message##.data in
                let () = Common.debug response_text in
                let () = Kastor_client.receive update_stor_state response_text in
                Js._true
             )) in
      let () = sim_worker##.onmessage :=
          (Dom.handler
             (fun (response_message : string Worker.messageEvent Js.t) ->
                let response_text : string = response_message##.data in
                let () = self#receive response_text  in
                Js._true
             )) in
      let () = sim_worker##.onerror :=
          (Dom.handler
             (fun _ -> let () = is_running <- false in Js._true)) in
      let () = kasa_worker##.onerror :=
          (Dom.handler
             (fun _ -> let () = is_running <- false in Js._true)) in
      let () = kamoha_worker##.onerror :=
          (Dom.handler
             (fun _ -> let () = is_running <- false in Js._true)) in
      let () = kastor_worker##.onerror :=
          (Dom.handler
             (fun _ -> let () = is_running <- false in Js._true)) in
        ()
    method private sleep timeout = Js_of_ocaml_lwt.Lwt_js.sleep timeout
    method private post_message (message_text : string) : unit =
      sim_worker##postMessage(message_text)
    inherit Mpi_api.manager ()
    inherit Kasa_client.new_client
        ~post:(fun message_text ->
            let () = Common.debug (Js.string message_text) in
            kasa_worker##postMessage(message_text))
        kasa_mailbox
    inherit Kamoha_client.new_client
        ~post:(fun message_text ->
            let () = Common.debug (Js.string message_text) in
            kamoha_worker##postMessage(message_text))
        kamoha_mailbox
    inherit Kastor_client.new_client
        ~post:(fun message_text ->
            let () = Common.debug (Js.string message_text) in
            kastor_worker##postMessage(message_text))
        stor_state

    method project_parse overwrites =
      self#secret_project_parse >>=
      Api_common.result_bind_lwt
        ~ok:(fun out ->
            self#secret_simulation_load out overwrites >>=
            Api_common.result_bind_lwt
              ~ok:(fun () -> self#init_static_analyser out >|= Api_common.result_kasa))

    method is_running = is_running
    method terminate =
      let () = sim_worker##terminate in
      kasa_worker##terminate

    method is_computing =
      self#sim_is_computing || Kasa_client.is_computing kasa_mailbox ||
      self#story_is_computing
  end
