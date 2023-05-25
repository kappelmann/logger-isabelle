signature ML_CODE_UTIL =
sig
  (* manipulating parsed ML code *)
  (*returns a name variant that ought to avoid name shadowing in antiquotations*)
  val internal_name : string -> string
  val spaces : string list -> string

  (*type of parsed ML code*)
  type code = ML_Lex.token Antiquote.antiquote list

  val flat : code list -> code
  val read : string -> code
  val reads : string list -> code

  val commas : code list -> code

  val enclose : code -> code -> code -> code
  val atomic : code -> code
  val tuple : code list -> code
  val list : code list -> code
end

structure ML_Code_Util : ML_CODE_UTIL =
struct

fun internal_name name = "INTERNAL___" ^ name
val spaces = space_implode " "

(* manipulating parsed ML code *)
type code = ML_Lex.token Antiquote.antiquote list

val flat = flat
val read = ML_Lex.read
val reads = map read #> flat
val commas = separate (ML_Lex.read ",") #> flat

fun enclose start close code = flat [start, code, close]
val atomic = enclose (ML_Lex.read "(") (ML_Lex.read ")")
val tuple = commas #> enclose (ML_Lex.read "(") (ML_Lex.read ")")
val list = commas #> enclose (ML_Lex.read "[") (ML_Lex.read "]")

end