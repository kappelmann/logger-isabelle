\<^marker>\<open>creator "Kevin Kappelmann"\<close>
section \<open>Logging\<close>
theory Logging
  imports
    Antiquotation_Utils
begin
paragraph \<open>Summary\<close>
text \<open>Generic logging inspired by Apache's Log4J 2
\<^url>\<open>https://logging.apache.org/log4j/2.x/manual/customloglevels.html\<close>
\<close>

ML_file\<open>Data_Structures/map.ML\<close>
ML_file\<open>Data_Structures/hoption_tree.ML\<close>
ML_file\<open>Data_Structures/binding_tree.ML\<close>

ML_file\<open>logger.ML\<close>
ML_file\<open>logging_antiquotations.ML\<close>


end
