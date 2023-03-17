(*  Title:      Logging/antiquotations.ML
    Author:     Kevin Kappelmann
*)
signature LOGGING_ANTIQUOTATIONS =
sig
  val show_pos: bool Config.T
end

structure Logging_Antiquotations : LOGGING_ANTIQUOTATIONS =
struct

structure Util = Antiquotation_Util

val show_pos = Attrib.setup_config_bool @{binding "log_show_pos"} (K false)

val log =
  let
    fun body ts ((log_level, logger_binding), show_pos_opt) =
      let
        val (_, pos) = Token.name_of_src ts
        val ctxt_internal = Util.internal_code_name "ctxt"
        val show_pos = the_default
          (Util.spaces ["Config.get", ctxt_internal, "Logging_Antiquotations.show_pos"])
          show_pos_opt
        val info = Util.spaces [
            "if", ML_Syntax.atomic show_pos,
            "then",
              ML_Syntax.print_string "\n", "^",
              ML_Syntax.atomic ("Position.here" ^ ML_Syntax.atomic (ML_Syntax.print_position pos)),
            "else", ML_Syntax.print_string ""
          ] |> ML_Syntax.atomic
        val message_f_internal = Util.internal_code_name "message_f"
        val code = Util.spaces [
            "fn", ctxt_internal, "=> fn", message_f_internal, "=> Logger.log",
            ML_Syntax.atomic logger_binding,
            ML_Syntax.atomic log_level,
            ctxt_internal,
            "(fn _ =>", message_f_internal, "() ^", info, ")"
          ] |> ML_Syntax.atomic
      in pair (K ("", code)) end
  in
    ML_Antiquotation.declaration @{binding "log"}
      (Scan.optional Parse.embedded "Logger.INFO"
        -- Scan.optional Parse.embedded "logger" (*works in particular if structure implements HAS_LOGGER*)
        -- Scan.option Parse.embedded
        |> Scan.lift)
      body
  end

(*setup the antiquotation*)
val _ = Theory.setup log

end