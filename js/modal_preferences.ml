(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2018 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

module Html = Tyxml_js.Html5
let configuration_seed_input_id = "simulation_seed_input"
let preferences_modal_id = "preferences_modal"
let settings_client_id_input_id = "settings-client-id-input"

let preferences_button =
  Html.a [ Html.pcdata "Preferences" ]

let option_seed_input =
  Html.input ~a:[
    Html.a_id configuration_seed_input_id;
    Html.a_input_type `Number;
    Html.a_class ["form-control"];
  ] ()
let option_withtrace =
  Html.input ~a:[
    Html.a_input_type `Checkbox;
    Tyxml_js.R.filter_attrib (Html.a_checked ())
      (React.S.map
         (fun s -> s.State_project.model_parameters.State_project.store_trace)
         State_project.model);
  ] ()
let decrease_font =
  Html.button ~a:[
    Html.a_button_type `Button;
    Html.a_class [ "btn"; "btn-default"; "btn-sm" ]
  ] [Html.pcdata "-"]
let increase_font =
  Html.button ~a:[
    Html.a_button_type `Button;
    Html.a_class [ "btn"; "btn-default"; "btn-lg" ]
  ] [Html.pcdata "+"]

let settings_client_id_input =
  Html.input
    ~a:[ Html.a_id settings_client_id_input_id ;
         Html.a_input_type `Text ;
         Html.a_class [ "form-control" ];
         Html.a_placeholder "client id" ;
         Html.a_size 40;
       ] ()

let settings_client_id_input_dom =
  Tyxml_js.To_dom.of_input settings_client_id_input

let option_http_synch =
  Html.input
    ~a:[ Html.a_input_type `Checkbox;
         Tyxml_js.R.filter_attrib (Html.a_checked ()) State_settings.synch]
    ()

let dropdown (model : State_runtime.model) =
  let current_id = State_runtime.spec_id  model.State_runtime.model_current in
  (List.map
     (fun (spec : State_runtime.spec) ->
        let spec_id = State_runtime.spec_id spec in
        Html.option
          ~a:(Html.a_value spec_id ::
              if current_id = spec_id then [Html.a_selected ()] else [])
          (Html.pcdata (State_runtime.spec_label spec)))
     model.State_runtime.model_runtimes)

let backend_options, backend_handle = ReactiveData.RList.create []
let backend_select =
  Tyxml_js.R.Html.select ~a:[Html.a_class ["form-control"]] backend_options

let%html bodies =
  {|
    <h3>Application</h3>
    <div class="form-group">
    <label class="col-md-2">Font size</label>
    <div class="col-md-5">|}[decrease_font; increase_font]{|</div>
    </div>
    <div class="form-group">
    <label class="col-md-2">Backend for new projects</label>
    <div class="col-md-5">|}[backend_select]{|</div>
    </div>
    <h3>Project</h3>
    <div class="form-group">
    <label class="col-md-2" for="|}configuration_seed_input_id{|">Seed</label>
    <div class="col-md-5">|}[option_seed_input]{|</div>
    </div>
    <div class="form-group">
    <div class="col-md-offset-2 col-md-5 checkbox"><label>|}
    [option_withtrace]{|Store trace
    </label></div>
    </div>
    <h3>HTTPS backend</h3>
    <div class="form-group">
    <label class="col-md-2" for="|}settings_client_id_input_id{|">Client id</label>
    <div class="col-md-5">|}[settings_client_id_input]{|</div>
    </div>
    <div class="form-group">
    <div class="col-md-offset-2 col-md-5 checkbox"><label>|}
    [option_http_synch]{|Auto synch
    </label></div>
    </div>|}

let set_button =
  Html.button
    ~a:[ Html.a_button_type `Submit;
         Html.a_class [ "btn"; "btn-primary" ] ]
    [ Html.pcdata "Set" ]

let save_button =
  Html.button
    ~a:[ Html.a_button_type `Button;
         Html.a_class [ "btn"; "btn-default" ] ]
    [ Html.pcdata "Save as default" ]

let modal =
  let head = Html.div
      ~a:[ Html.a_class [ "modal-header" ] ]
      [ Html.button
          ~a:[ Html.a_button_type `Button;
               Html.a_class [ "close" ];
               Html.a_user_data "dismiss" "modal" ]
          [ Html.entity "times" ];
        Html.h4 ~a:[ Html.a_class ["modal-title"] ] [ Html.pcdata "Preferences" ]
      ] in
  let body = Html.div
      ~a:[ Html.a_class [ "modal-body" ] ]
      bodies in
  let foot = Html.div
      ~a:[ Html.a_class [ "modal-footer" ] ]
      [ set_button; save_button;
        Html.button
          ~a:[ Html.a_button_type `Button;
               Html.a_class [ "btn"; "btn-default" ];
               Html.a_user_data "dismiss" "modal" ]
          [ Html.pcdata "Close" ] ] in
  Html.form
    ~a:[ Html.a_class [ "modal-content"; "form-horizontal" ] ]
    [head; body; foot]

let content () = [
  preferences_button;
  Html.div
    ~a:[ Html.a_class [ "modal"; "fade" ];
         Html.a_id preferences_modal_id;
         Html.a_role [ "dialog" ];
         Html.a_tabindex (-1)]
    [ Html.div
        ~a:[ Html.a_class [ "modal-dialog" ]; Html.a_role [ "document" ] ]
        [ modal ] ]
]

let fontSizeParamId = Js.string "kappappFontSize"
let initFontSize () =
  Js.Optdef.case
    Dom_html.window##.localStorage
    (fun () -> 1.4)
    (fun st ->
       Js.Opt.case (st##getItem fontSizeParamId) (fun () -> 1.4) Js.parseFloat)

let setFontSize v =
  let v' = string_of_float v in
  let () = Dom_html.document##.body##.style##.fontSize :=
      Js.string (v'^"em") in
  let () = Js.Optdef.iter
      Dom_html.window##.localStorage
      (fun st -> st##setItem fontSizeParamId (Js.string v')) in
  ()

let onload () =
  let () =
    (Tyxml_js.To_dom.of_form modal)##.onsubmit :=
      Dom_html.handler
        (fun (_ : Dom_html.event Js.t)  ->
           let settings_client_id =
             Js.to_string settings_client_id_input_dom##.value in
           let () = State_settings.set_client_id settings_client_id in

           let synch_checkbox_dom =
             Tyxml_js.To_dom.of_input option_http_synch in
           let is_checked = Js.to_bool (synch_checkbox_dom##.checked) in
           let () = State_settings.set_synch is_checked in

           let input : Dom_html.inputElement Js.t =
             Tyxml_js.To_dom.of_input option_seed_input in
           let value : string = Js.to_string input##.value in
           let model_seed =
             try Some (int_of_string value) with Failure _ -> None in
           let () = State_project.set_seed model_seed in

           let () = State_project.set_store_trace
               (Js.to_bool
                  (Tyxml_js.To_dom.of_input option_withtrace)##.checked) in

           let () =
             Panel_projects_controller.set_manager
               (Js.to_string
                  (Tyxml_js.To_dom.of_select backend_select)##.value) in

           let () =
             Common.modal ~id:("#"^preferences_modal_id) ~action:"hide" in

           Js._false) in
  let () =
    (Tyxml_js.To_dom.of_a preferences_button)##.onclick :=
      Dom_html.handler
        (fun _  ->
           let () =
             settings_client_id_input_dom##.value :=
               Js.string (State_settings.get_client_id ()) in

           let input = Tyxml_js.To_dom.of_input option_seed_input in
           let () = input##.value := Js.string
                 (match (React.S.value State_project.model).
                          State_project.model_parameters.State_project.seed with
                 | None -> ""
                 | Some model_seed -> string_of_int model_seed) in

           let () =
             Common.modal ~id:("#"^preferences_modal_id) ~action:"show" in

           Js._false) in

  let _ =
    React.S.bind
      State_runtime.model
      (fun list_t ->
         let () =
           ReactiveData.RList.set backend_handle (dropdown list_t) in
         React.S.const ()) in

  let currentFontSize = ref (initFontSize ()) in
  let () = setFontSize !currentFontSize in
  let () =
    (Tyxml_js.To_dom.of_button increase_font)##.onclick :=
      Dom_html.handler
        (fun _ ->
           let () = currentFontSize :=
               min 3. (!currentFontSize +. 0.2) in
           let () = setFontSize !currentFontSize in
           Js._false) in
  let () =
    (Tyxml_js.To_dom.of_button decrease_font)##.onclick :=
      Dom_html.handler
        (fun _ ->
           let () = currentFontSize :=
               max 0.2 (!currentFontSize -. 0.2) in
           let () = setFontSize !currentFontSize in
           Js._false) in
  ()
