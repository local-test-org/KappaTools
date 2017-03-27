
(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

open Lwt.Infix

let set_manager (runtime_id : string) : unit =
  Common.async
    (fun () ->
       State_error.wrap
         __LOC__
         (State_runtime.create_spec ~load:true runtime_id >>=
          (fun r -> State_project.sync () >>=
            fun r' -> Lwt.return (Api_common.result_combine [r; r']))) >>=
       (Api_common.result_bind_lwt ~ok:State_file.sync) >>=
       (fun _ -> Lwt.return_unit)
    )

let with_file (handler : Api_types_j.file Api.result -> unit Api.result Lwt.t) : unit =
    Common.async
    (fun () ->
       State_error.wrap
         __LOC__
         ((State_file.get_file ()) >>=
          handler)
       >>= (fun _ -> Lwt.return_unit)
    )

let set_content ~(filename : string) ~(filecontent : string) : unit =
  with_file
    (Api_common.result_bind_lwt
       ~ok:(fun file ->
           let current_filename = file.Api_types_j.file_metadata.Api_types_j.file_metadata_id in
           if filename = current_filename then
             (State_file.set_content filecontent >>=
              (fun r -> State_project.sync () >>=
                fun r' -> Lwt.return (Api_common.result_combine [r; r'])))
             >>= (fun _ -> Lwt.return (Api_common.result_ok ()))
           else
             let msg = Format.sprintf "file name mismatch %s %s" filename current_filename in
             let () = Common.error (Js.string msg) in
             Lwt.return (Api_common.result_ok ())
         )
    )
