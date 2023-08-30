A hierarchical logger for Isabelle/ML.
Features:
1. Per logger configuration, including
    1. output function (e.g. print to console or file)
    2. log level: suppress and enable log messages based on severity
    3. message filter: suppress and enable log messages based on a filter function
2. Hierarchical configuration: set options based on logger name spaces;
   for example, disable logging for all loggers registered below `Root.Unification.*`
3. Logging antiquotation to optionally print positional information of logging message
4. Commands and attributes to configure loggers using ML function calls.
