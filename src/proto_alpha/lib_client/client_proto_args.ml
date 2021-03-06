(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2014 - 2018.                                          *)
(*    Dynamic Ledger Solutions, Inc. <contact@tezos.com>                  *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

open Proto_alpha
open Alpha_context
open Cli_entries

type error += Bad_tez_arg of string * string (* Arg_name * value *)
type error += Bad_max_priority of string
type error += Bad_endorsement_delay of string

let () =
  register_error_kind
    `Permanent
    ~id:"badTezArg"
    ~title:"Bad Tez Arg"
    ~description:("Invalid \xEA\x9C\xA9 notation in parameter.")
    ~pp:(fun ppf (arg_name, literal) ->
        Format.fprintf ppf
          "Invalid \xEA\x9C\xA9 notation in parameter %s: '%s'"
          arg_name literal)
    Data_encoding.(obj2
                     (req "parameter" string)
                     (req "literal" string))
    (function Bad_tez_arg (parameter, literal) -> Some (parameter, literal) | _ -> None)
    (fun (parameter, literal) -> Bad_tez_arg (parameter, literal)) ;
  register_error_kind
    `Permanent
    ~id:"badMaxPriorityArg"
    ~title:"Bad -max-priority arg"
    ~description:("invalid priority in -max-priority")
    ~pp:(fun ppf literal ->
        Format.fprintf ppf "invalid priority '%s'in -max-priority" literal)
    Data_encoding.(obj1 (req "parameter" string))
    (function Bad_max_priority parameter -> Some parameter | _ -> None)
    (fun parameter -> Bad_max_priority parameter) ;
  register_error_kind
    `Permanent
    ~id:"badEndorsementDelayArg"
    ~title:"Bad -endorsement-delay arg"
    ~description:("invalid priority in -endorsement-delay")
    ~pp:(fun ppf literal ->
        Format.fprintf ppf "Bad argument value for -endorsement-delay. Expected an integer, but given '%s'" literal)
    Data_encoding.(obj1 (req "parameter" string))
    (function Bad_endorsement_delay parameter -> Some parameter | _ -> None)
    (fun parameter -> Bad_endorsement_delay parameter)


let tez_sym =
  "\xEA\x9C\xA9"

let string_parameter =
  parameter (fun _ x -> return x)

let init_arg =
  default_arg
    ~parameter:"-init"
    ~placeholder:"data"
    ~doc:"initial value of the contract's storage"
    ~default:"Unit"
    string_parameter

let arg_arg =
  default_arg
    ~parameter:"-arg"
    ~placeholder:"data"
    ~doc:"argument passed to the contract's script, if needed"
    ~default:"Unit"
    string_parameter

let delegate_arg =
  arg
    ~parameter:"-delegate"
    ~placeholder:"identity"
    ~doc:"delegate of the contract\n\
          Must be a known identity."
    string_parameter

let source_arg =
  arg
    ~parameter:"-source"
    ~placeholder:"identity"
    ~doc:"source of the bonds to be paid\n\
          Must be a known identity."
    string_parameter

let spendable_switch =
  switch
    ~parameter:"-spendable"
    ~doc:"allow the manager to spend the contract's tokens"

let force_switch =
  switch
    ~parameter:"-force"
    ~doc:"disables the node's injection checks\n\
          Force the injection of branch-invalid operation or force \
         \ the injection of block without a fitness greater than the \
         \ current head."

let delegatable_switch =
  switch
    ~parameter:"-delegatable"
    ~doc:"allow future delegate change"

let tez_format =
  "Text format: `D,DDD,DDD.DDD,DDD`.\n\
   Tez and mutez and separated by a period sign. Trailing and pending \
   zeroes are allowed. Commas are optional, but if present they must \
   be placed every 3 digits."

let tez_parameter param =
  parameter
    (fun _ s ->
       match Tez.of_string s with
       | Some tez -> return tez
       | None -> fail (Bad_tez_arg (param, s)))

let tez_arg ~default ~parameter ~doc =
  default_arg ~parameter ~placeholder:"amount" ~doc ~default (tez_parameter parameter)

let tez_param ~name ~desc next =
  Cli_entries.param
    ~name
    ~desc:(desc ^ " in \xEA\x9C\xA9\n" ^ tez_format)
    (tez_parameter name)
    next

let fee_arg =
  tez_arg
    ~default:"0.05"
    ~parameter:"-fee"
    ~doc:"fee in \xEA\x9C\xA9 to pay to the baker"

let max_priority_arg =
  arg
    ~parameter:"-max-priority"
    ~placeholder:"slot"
    ~doc:"maximum allowed baking slot"
    (parameter (fun _ s ->
         try return (int_of_string s)
         with _ -> fail (Bad_max_priority s)))

let free_baking_switch =
  switch
    ~parameter:"-free-baking"
    ~doc:"only consider free baking slots"

let endorsement_delay_arg =
  default_arg
    ~parameter:"-endorsement-delay"
    ~placeholder:"seconds"
    ~doc:"delay before endorsing blocks\n\
          Delay between notifications of new blocks from the node and \
          production of endorsements for these blocks."
    ~default:"15"
    (parameter (fun _ s ->
         try return (int_of_string s)
         with _ -> fail (Bad_endorsement_delay s)))

let no_print_source_flag =
  switch
    ~parameter:"-no-print-source"
    ~doc:"don't print the source code\n\
          If an error is encountered, the client will print the \
          contract's source code by default.\n\
          This option disables this behaviour."

module Daemon = struct
  let baking_switch =
    switch
      ~parameter:"-baking"
      ~doc:"run the baking daemon"
  let endorsement_switch =
    switch
      ~parameter:"-endorsement"
      ~doc:"run the endorsement daemon"
  let denunciation_switch =
    switch
      ~parameter:"-denunciation"
      ~doc:"run the denunciation daemon"
end
