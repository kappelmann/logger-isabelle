(*  Title:      Logging/antiquotations.ML
    Author:     Kevin Kappelmann
*)
signature LOGGING_ANTIQUOTATIONS =
sig
  val show_pos: bool Config.T
end

structure Logging_Antiquotations : LOGGING_ANTIQUOTATIONS =
struct

val show_pos = Attrib.setup_config_bool @{binding "log_show_pos"} (K false)

val log =
  let
    val scan_default = Scan.optional Args.name
    val scan_option = Scan.option Args.name
    fun body ts (((log_level, logger), output_opt), show_pos_opt) ctxt =
      let
        val output = the_default ("Root_Logger.default_output " ^ log_level) output_opt
        val show_pos = the_default ("Config.get ctxt Logging_Antiquotations.show_pos") show_pos_opt
        val pos = Token.name_of_src ts |> snd
        val info = String.concat [
            "if ", ML_Syntax.atomic show_pos, " then ",
              ML_Syntax.print_string "\n", " ^ ",
              ML_Syntax.atomic ("Position.here " ^ ML_Syntax.atomic (ML_Syntax.print_position pos)),
            "else ", ML_Syntax.print_string ""
          ] |> ML_Syntax.atomic
        val code = String.concat [
            "fn ctxt => fn message_f => ", logger, ".log ctxt ", ML_Syntax.atomic log_level, " ",
            ML_Syntax.atomic output, " (fn _ => message_f () ^ ", info, ")"
          ] |> ML_Syntax.atomic
      in (K ("", code), ctxt) end
  in
    ML_Antiquotation.declaration @{binding "log"}
      (scan_default "Root_Logger.INFO"
        -- scan_default "Logger"
        -- scan_option (*output channel*)
        -- scan_option (*show_pos flag*)
        |> Scan.lift)
      body
  end

val new_logger = ML_Antiquotation.inline @{binding "new_logger"}
  (Scan.lift Args.name_position >>
    (fn (name, pos) => cat_lines [
      "Logger(struct val name = " ^ ML_Syntax.atomic (ML_Syntax.print_string name),
      "val pos = " ^ ML_Syntax.atomic (ML_Syntax.print_position pos) ^ "; end)"
    ]))

(*setup the antiquotations*)
val _ = Theory.setup (
    log #>
    new_logger
  )

end