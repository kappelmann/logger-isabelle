signature ML_ATTRIBUTE =
sig
  val get_thm : Context.generic -> thm
  val put_thm : thm -> Context.generic -> Context.generic
end

structure ML_Attribute : ML_ATTRIBUTE =
struct

structure Util = Antiquotation_Util

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
    val context_internal = Util.internal_code_name "context"
    val thm_internal = Util.internal_code_name "thm"
    val code =
      ML_Lex.read (Util.spaces ["Context.>> (fn", context_internal, "=>"]) @
      ML_Lex.read (Util.spaces
        ["let val", thm_internal, "= ML_Attribute.get_thm", context_internal]) @
      ML_Lex.read (Util.spaces ["val (", thm_internal, ", ", context_internal, ") ="]) @
        ML_Lex.read (Util.spaces ["Thm.apply_attribute ("]) @ code @ ML_Lex.read ")" @
        ML_Lex.read thm_internal @ ML_Lex.read context_internal @
      ML_Lex.read (Util.spaces
        ["in ML_Attribute.put_thm", thm_internal, context_internal, "end)"])
    val context = ML_Context.expression pos code context
    val thm = get_thm context
  in (SOME context, SOME thm) end

fun run_mixed_attribute (code, pos) =
  let val code = ML_Lex.read "Thm.mixed_attribute (" @ code @ ML_Lex.read ")"
  in run_attribute (code, pos) end

fun run_declaration_attribute (code, pos) =
  let val code = ML_Lex.read "Thm.declaration_attribute (" @ code @ ML_Lex.read ")"
  in run_attribute (code, pos) end

fun run_rule_attribute (code, pos) =
  let val code = ML_Lex.read "Thm.rule_attribute [] (" @ code @ ML_Lex.read ")"
  in run_attribute (code, pos) end

val _ =
  (Theory.setup
    (Attrib.setup \<^binding>\<open>ML_attr\<close>
      (Scan.lift (Parse.position Parse.embedded_ml) >> run_attribute)
      "attribute as ML code");
  Theory.setup
    (Attrib.setup \<^binding>\<open>ML_mattr\<close>
      (Scan.lift (Parse.position Parse.embedded_ml) >> run_mixed_attribute)
      "mixed attribute as ML code");
  Theory.setup
    (Attrib.setup \<^binding>\<open>ML_dattr\<close>
      (Scan.lift (Parse.position Parse.embedded_ml) >> run_declaration_attribute)
      "declaration attribute as ML code");
  Theory.setup
    (Attrib.setup \<^binding>\<open>ML_rattr\<close>
      (Scan.lift (Parse.position Parse.embedded_ml) >> run_rule_attribute)
      "rule attribute as ML code"))

end