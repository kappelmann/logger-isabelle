signature ML_ATTRIBUTE =
sig

  val get_thm : Context.generic -> thm
  val put_thm : thm -> Context.generic -> Context.generic

  val run_attribute :
    ML_Lex.token Antiquote.antiquote list * Position.T -> attribute
  val run_mixed_attribute :
    ML_Lex.token Antiquote.antiquote list * Position.T -> attribute
  val run_declaration_attribute :
    ML_Lex.token Antiquote.antiquote list * Position.T -> attribute
  val run_Kdeclaration_attribute :
    ML_Lex.token Antiquote.antiquote list * Position.T -> attribute
  val run_rule_attribute :
    ML_Lex.token Antiquote.antiquote list * Position.T -> attribute
  val run_Krule_attribute :
    ML_Lex.token Antiquote.antiquote list * Position.T -> attribute

end

structure ML_Attribute : ML_ATTRIBUTE =
struct

structure Util = ML_Code_Util

structure Thm_Data = Generic_Data(
  type T = thm
  val empty = Drule.dummy_thm
  val merge = fst
)

val get_thm = Thm_Data.get
val put_thm = Thm_Data.put

fun run_attribute (code, pos) (context, thm) =
  let
    val context = put_thm thm context
    val context_internal = Util.internal_name "context" |> Util.read
    val thm_internal = Util.internal_name "thm" |> Util.read
    val code =
      Util.read "Context.>> (fn" @ context_internal @ Util.read "=>" @
      Util.read "let val" @ thm_internal @ Util.read "= ML_Attribute.get_thm" @
        context_internal @
      Util.read "val" @ Util.tuple [thm_internal, context_internal] @ Util.read "=" @
        Util.read "Thm.apply_attribute" @ Util.atomic code @ thm_internal @ context_internal @
      Util.read "in ML_Attribute.put_thm" @ thm_internal @ context_internal @ Util.read "end)"
    val context = ML_Context.expression pos code context
    val thm = get_thm context
  in (SOME context, SOME thm) end

fun run_mixed_attribute (code, pos) =
  let val code = ML_Lex.read "Thm.mixed_attribute" @ Util.atomic code
  in run_attribute (code, pos) end

fun run_declaration_attribute (code, pos) =
  let val code = ML_Lex.read "Thm.declaration_attribute" @ Util.atomic code
  in run_attribute (code, pos) end

fun run_Kdeclaration_attribute (code, pos) =
  let val code =
    ML_Lex.read "Thm.declaration_attribute" @ (Util.atomic (ML_Lex.read "K" @ Util.atomic code))
  in run_attribute (code, pos) end

fun run_rule_attribute (code, pos) =
  let val code = ML_Lex.read "Thm.rule_attribute []" @ Util.atomic code
  in run_attribute (code, pos) end

fun run_Krule_attribute (code, pos) =
  let val code =
    ML_Lex.read "Thm.rule_attribute []" @ (Util.atomic (ML_Lex.read "K" @ Util.atomic code))
  in run_attribute (code, pos) end

val _ =
  let val parse_pos_ml = Scan.lift (Parse.position Parse.embedded_ml)
  in
    Theory.setup
      (Attrib.setup \<^binding>\<open>ML_attr\<close>
        (parse_pos_ml >> run_attribute)
        "attribute as ML code" #>
      Attrib.setup \<^binding>\<open>ML_mattr\<close>
        (parse_pos_ml >> run_mixed_attribute)
        "mixed attribute as ML code" #>
      Attrib.setup \<^binding>\<open>ML_dattr\<close>
        (parse_pos_ml >> run_declaration_attribute)
        "declaration attribute as ML code" #>
      Attrib.setup \<^binding>\<open>ML_Kdattr\<close>
        (parse_pos_ml >> run_Kdeclaration_attribute)
        "context only declaration attribute as ML code" #>
      Attrib.setup \<^binding>\<open>ML_rattr\<close>
        (parse_pos_ml >> run_rule_attribute)
        "rule attribute as ML code" #>
      Attrib.setup \<^binding>\<open>ML_Krattr\<close>
        (parse_pos_ml >> run_Krule_attribute)
        "theorem only rule attribute as ML code")
  end

end