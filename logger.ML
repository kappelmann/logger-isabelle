(*  Title:      Logging/logger.ML
    Author:     Kevin Kappelmann, Paul Bachmann

Hierarchical logger, indexed on bindings.
The log levels are based on Apache's Log4J 2
https://logging.apache.org/log4j/2.x/manual/customloglevels.html
*)
signature LOGGER =
sig
  type log_level = int
  val OFF   : log_level
  val FATAL : log_level
  (*error log level*)
  val ERR   : log_level
  val WARN  : log_level
  val INFO  : log_level
  val DEBUG : log_level
  val TRACE : log_level
  val ALL   : log_level

  type logger_name = bstring
  type logger_binding

  val root_logger : logger_binding
  (*takes parent logger and creates a child logger with the given name*)
  val create_child_logger : logger_binding -> logger_name -> logger_binding
  val pretty_binding : logger_binding -> Pretty.T

  type logger_output = log_level -> string -> unit
  val default_output : logger_output

  type logger_config
  val config : logger_output -> log_level -> bool -> logger_config
  val default_config : logger_config
  val set_config_log_level : log_level -> logger_config -> logger_config
  val set_config_output : logger_output -> logger_config -> logger_config
  (*set whether to print the logger's name when logging*)
  val set_config_show_logger : bool -> logger_config -> logger_config

  val lookup_logger : logger_binding -> Context.generic -> logger_config option

  val map_logger : logger_binding ->
    (logger_config option -> logger_config option) -> Context.generic ->
    Context.generic
  val map_loggers : logger_binding ->
    (logger_config option -> logger_config option) -> Context.generic ->
    Context.generic

  val insert_logger : (logger_binding * logger_config) ->
    Context.generic -> Context.generic
  val insert_logger_safe : (logger_binding * logger_config) ->
    Context.generic -> Context.generic

  val delete_logger : logger_binding -> Context.generic -> Context.generic
  val cut_loggers : logger_binding -> Context.generic -> Context.generic

  val set_log_level : logger_binding -> log_level -> Context.generic -> Context.generic
  val set_log_levels : logger_binding -> log_level -> Context.generic -> Context.generic

  (*creates and inserts child logger with default configuration into context*)
  val new_logger : logger_binding -> logger_name -> Context.generic ->
    (logger_binding * Context.generic)
  (*registers new logger to background theory*)
  val setup_new_logger : logger_binding -> logger_name -> logger_binding

  (*prints message created by passed function to the logger's output if the
    logger's log_level is greater or equal than the passed level; uses lazy
    computation of the message to avoid computations in case the log level
    blocks printing of the message.*)
  val log : logger_binding -> log_level -> Proof.context -> (unit -> string) -> unit

  (* logging functions for different log levels *)
  val fatal : logger_binding -> Proof.context -> (unit -> string) -> unit
  val err : logger_binding -> Proof.context -> (unit -> string) -> unit
  val warn : logger_binding -> Proof.context -> (unit -> string) -> unit
  val info : logger_binding -> Proof.context -> (unit -> string) -> unit
  val debug : logger_binding -> Proof.context -> (unit -> string) -> unit
  val trace : logger_binding -> Proof.context -> (unit -> string) -> unit

end

structure Logger : LOGGER =
struct

type log_level = int
(*values for different log levels*)
val OFF = 0
val FATAL = 100
val ERR = 200
val WARN = 300
val INFO = 400
val DEBUG = 500
val TRACE = 600
val ALL = 1000

type logger_name = bstring
datatype logger_binding = Logger_Binding of binding

fun binding_of (Logger_Binding binding) = binding

val root_logger_name = "Root"
val root_logger = Binding.name root_logger_name |> Logger_Binding
fun create_child_logger (Logger_Binding parent) child_name =
  let val child = Binding.qualify_name true parent child_name
  in
    if Symbol_Pos.is_identifier (Binding.name_of child)
    then Logger_Binding child
    else error ("Bad identifier for child logger " ^ ML_Syntax.print_string child_name)
  end
val pretty_binding = Binding.pretty o binding_of

type logger_output = log_level -> string -> unit

fun default_output log_level =
  if log_level <= WARN then warning
  else if log_level < DEBUG then writeln
  else tracing

type logger_config = {
    log_level : log_level,
    output : logger_output,
    show_logger : bool
  }
fun config output log_level show_logger =
  {log_level = log_level, output = output, show_logger = show_logger}
val default_config = config default_output INFO true
fun set_config_log_level log_level {output, show_logger,...} =
  {log_level = log_level, output = output, show_logger = show_logger}
fun set_config_output output {log_level, show_logger,...} =
  {log_level = log_level, output = output, show_logger = show_logger}
fun set_config_show_logger show_logger {log_level, output,...} =
  {log_level = log_level, output = output, show_logger = show_logger}

fun log_config binding {log_level, output, show_logger} level message_f =
  if level > log_level then ()
  else
    let val msg = message_f ()
      |> show_logger ?  (fn msg => cat_lines [
          "Logger: " ^ Pretty.string_of (pretty_binding binding),
          msg
        ])
    in output level msg end

structure BT = Binding_Tree

val init_tree = BT.insert (binding_of root_logger, default_config) BT.empty

structure Logger_Data = Generic_Data(
  type T = logger_config BT.binding_tree
  val empty = init_tree
  val merge = BT.merge
)

fun lookup_logger (Logger_Binding binding) =
  Logger_Data.get #> (fn bt => BT.lookup bt binding)
fun map_logger (Logger_Binding binding) f = Logger_Data.map (BT.map binding f)
fun map_loggers (Logger_Binding binding) f = Logger_Data.map (BT.map_below binding f)
fun insert_logger bcp = Logger_Data.map (apfst binding_of bcp |> BT.insert)
fun insert_logger_safe bcp = Logger_Data.map (apfst binding_of bcp |> BT.insert_safe)
fun delete_logger (Logger_Binding binding) = Logger_Data.map (BT.delete_safe binding)
fun cut_loggers (Logger_Binding binding) = Logger_Data.map (BT.cut_safe binding)

fun set_log_level binding log_level = map_logger binding
  (set_config_log_level log_level |> Option.map)
fun set_log_levels binding log_level = map_loggers binding
  (set_config_log_level log_level |> Option.map)

fun new_logger parent child_name context =
  let val child = create_child_logger parent child_name
  in (child, insert_logger (child, default_config) context) end
fun setup_new_logger parent child_name = Context.>>> (new_logger parent child_name)

fun log binding log_level ctxt message_f =
  case lookup_logger binding (Context.Proof ctxt) of
    SOME config => log_config binding config log_level message_f
  | NONE =>
      let fun warn_msg _ =
        "Logger " ^ Pretty.string_of (pretty_binding binding) ^ " not found."
      in
        if binding = root_logger
        then default_output WARN (warn_msg ())
        else log root_logger WARN ctxt warn_msg
      end

fun fatal binding = log binding FATAL
fun err binding = log binding ERR
fun warn binding = log binding WARN
fun info binding = log binding INFO
fun debug binding = log binding DEBUG
fun trace binding = log binding TRACE

end

signature HAS_LOGGER =
sig
  val logger : Logger.logger_binding
end
