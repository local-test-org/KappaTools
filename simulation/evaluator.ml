(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

let do_interactive_directives
    ~outputs ~max_sharing ~new_syntax contact_map env counter graph state e =
  let cc_preenv =
    Pattern.PreEnv.of_env (Model.domain env) in
  let contact_map' = Array.map Array.copy contact_map in
  let e',_ =
    List_util.fold_right_map
      (LKappa.modif_expr_of_ast
         ~new_syntax
         (Model.signatures env)
         (Model.tokens_finder env)
         (Model.algs_finder env) contact_map') e [] in
  let () =
    if Tools.array_fold_lefti
        (fun n -> Tools.array_fold_lefti
            (fun s b x -> b || x != contact_map.(n).(s)))
        false contact_map' then
      raise (ExceptionDefn.Malformed_Decl
               (Locality.dummy_annot "Creating new link type is forbidden")) in
  let cc_preenv', e'' = Eval.compile_modifications_no_track
      ~compileModeOn:false contact_map cc_preenv [||] (* TODO: add blacklists *) e' in
  let env',graph' =
    if cc_preenv == cc_preenv' then (env,graph)
    else
      let fenv,_ = Pattern.finalize ~max_sharing cc_preenv' contact_map in
      (Model.new_domain fenv env,
       List.fold_left
         (Rule_interpreter.incorporate_extra_pattern fenv)
         graph
         (Primitives.extract_connected_components_modifications e'')) in
  e'',
  (env',
   State_interpreter.do_modifications ~outputs env' counter graph' state e'')

let get_pause_criteria ~max_sharing ~new_syntax contact_map env graph b =
  let cc_preenv =
    Pattern.PreEnv.of_env (Model.domain env) in
  let b' =
    LKappa.bool_expr_of_ast ~new_syntax
      (Model.signatures env) (Model.tokens_finder env)
      (Model.algs_finder env) b in
  let cc_preenv',(b'',pos_b'' as bpos'') =
    Eval.compile_bool ~compileModeOn:false  contact_map cc_preenv b' in
  let env',graph' =
    if cc_preenv == cc_preenv' then (env,graph)
    else
      let fenv,_ = Pattern.finalize ~max_sharing cc_preenv' contact_map in
      (Model.new_domain fenv env,
       List.fold_left
         (Rule_interpreter.incorporate_extra_pattern fenv)
         graph
         (Primitives.extract_connected_components_bool bpos'')) in
  let () = if try Alg_expr.stops_of_bool
                    (Model.all_dependencies env) b'' <> []
    with ExceptionDefn.Unsatisfiable -> true then
      raise (ExceptionDefn.Malformed_Decl
               ("[T] can only be used in inequalities",pos_b'')) in
  (env',graph',b'')
