signature ANTIQUOTATION_UTIL =
sig
  (* miscellaneous *)
  val spaces : string list -> string

  (* manipulating parsed ML code *)
  (*returns a name variant that ought to avoid name shadowing in antiquotations*)
  val internal_code_name : string -> string
end

structure Antiquotation_Util : ANTIQUOTATION_UTIL =
struct

(* miscellaneous *)
val spaces = space_implode " "

(* manipulating parsed ML code *)
fun internal_code_name name = "INTERNAL___" ^ name

end