\<^marker>\<open>creator "Kevin Kappelmann"\<close>
section \<open>ML Logger Examples\<close>
theory ML_Logger_Examples
  imports
    ML_Logger
    Setup_Result_Commands
begin

ML_command\<open>
  (*first some simple, barebone logging: print some information*)
  (*the following two are equivalent*)
  val _ = Logger.log Logger.root_logger Logger.INFO @{context} (K "hello root logger")
  val _ = @{log Logger.INFO Logger.root_logger} @{context} (K "hello root logger")
\<close>

ML_command\<open>
  (*@{log} is equivalent to "Logger.log logger Logger.INFO"*)
  val logger = Logger.root_logger
  val _ = @{log} @{context} (K "hello root logger")
\<close>

ML\<open>
  (*to guarantee the existence of a "logger" in an ML structure, one should
    use the HAS_LOGGER signature*)
  structure My_Struct : sig
    include HAS_LOGGER
    val get_n :  Proof.context -> int
  end = struct
    val logger = Logger.setup_new_logger Logger.root_logger "My_Struct"
    fun get_n ctxt = (@{log} ctxt (K "retrieving n..."); 42)
  end
\<close>

ML_command\<open>val n = My_Struct.get_n @{context}\<close>

ML\<open>
  (*we can set up a hierarchy of loggers*)
  val logger = Logger.root_logger
  val parent1 = Logger.setup_new_logger Logger.root_logger "Parent1"
  val child1 = Logger.setup_new_logger parent1 "Child1"
  val child2 = Logger.setup_new_logger parent1 "Child2"

  val parent2 = Logger.setup_new_logger Logger.root_logger "Parent2"
\<close>

ML_command\<open>
  (@{log Logger.INFO Logger.root_logger} @{context} (K "Hello root logger");
  @{log Logger.INFO parent1} @{context} (K "Hello parent1");
  @{log Logger.INFO child1} @{context} (K "Hello child1");
  @{log Logger.INFO child2} @{context} (K "Hello child2");
  @{log Logger.INFO parent2} @{context} (K "Hello parent2"))
\<close>

(*we can use different log levels to show/surpress messages; the log levels are based on
Apache's Log4J 2 (https://logging.apache.org/log4j/2.x/manual/customloglevels.html)*)
ML_command\<open>@{log Logger.DEBUG parent1} @{context} (K "Hello parent1")\<close> (*prints nothings*)
declare [[ML_map_context \<open>Logger.set_log_level parent1 Logger.DEBUG\<close>]]
ML_command\<open>@{log Logger.DEBUG parent1} @{context} (K "Hello parent1")\<close> (*prints message*)
(*ctrl+click on the value below to see all log levels*)
ML_command\<open>Logger.ALL\<close>

(*we can set options for all loggers below a given logger;
below, we set the log level for all loggers below (and including) parent1 to error, thus disabling
warning messages*)
ML_command\<open>
  (@{log Logger.WARN parent1} @{context} (K "Warning from parent1");
  @{log Logger.WARN child1} @{context} (K "Warning from child1"))
\<close>
declare [[ML_map_context \<open>Logger.set_log_levels parent1 Logger.ERR\<close>]]
ML_command\<open>
  (@{log Logger.WARN parent1} @{context} (K "Warning from parent1");
  @{log Logger.WARN child1} @{context} (K "Warning from child1"))
\<close>
declare [[ML_map_context \<open>Logger.set_log_levels parent1 Logger.INFO\<close>]]

(*we can set message filters*)
declare [[ML_map_context \<open>Logger.set_msg_filters Logger.root_logger (match_string "Third")\<close>]]
ML_command\<open>
  (@{log Logger.INFO parent1} @{context} (K "First message");
  @{log Logger.INFO child1} @{context} (K "Second message");
  @{log Logger.INFO child2} @{context} (K "Third message");
  @{log Logger.INFO parent2} @{context} (K "Fourth message"))
\<close>
declare [[ML_map_context \<open>Logger.set_msg_filters Logger.root_logger (K true)\<close>]]

(*one can also use different output channels (e.g. files) and
hide/show some additional logging information;
ctrl+click on below values and explore*)
ML_command\<open>Logger.set_output; Logger.set_show_logger; Logging_Antiquotation.show_log_pos\<close>

(*to set up (local) loggers outside ML environments, the theory Setup_Result_Commands contains two
commans setup_result and local_setup_result*)
experiment
begin
local_setup_result local_logger = \<open>Logger.new_logger Logger.root_logger "Local"\<close>

ML_command\<open>@{log Logger.INFO local_logger} @{context} (K "Hello local world")\<close>
end

(*local_logger is no longer available (the follow thus does not work)*)
(* ML_command\<open>@{log Logger.INFO local_logger} @{context} (K "Hello local world")\<close> *)
(*bring it back to life in global context*)
setup_result local_logger = \<open>Logger.new_logger Logger.root_logger "Local"\<close>
ML_command\<open>@{log Logger.INFO local_logger} @{context} (K "Hello world")\<close>

(*delete it again*)
declare [[ML_map_context \<open>Logger.delete_logger local_logger\<close>]]
(*the logger can no longer be found in the logger hierarchy*)
ML_command\<open>@{log Logger.INFO local_logger} @{context} (K "Hello world")\<close>

end
