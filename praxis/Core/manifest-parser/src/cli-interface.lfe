;; cli-interface.lfe
;; Command-Line Interface for WP Praxis Manifest Parser
;;
;; This module provides CLI commands for parsing, validating, and
;; transforming manifest files from the command line.

(defmodule cli-interface
  "Command-line interface for manifest parser."
  (export all))

;;; =============================================================================
;;; Main Entry Point
;;; =============================================================================

(defun main (args)
  "Main CLI entry point.

  Args:
    args: List of command-line arguments

  Returns:
    Exit code (0 for success, non-zero for error)"
  (try
    (case (parse-cli-args args)
      ((tuple 'ok command options)
       (execute-command command options))
      ((tuple 'error reason)
       (print-error reason)
       1))
    (catch
      ((tuple type reason _stacktrace)
       (print-error `#(,type ,reason))
       2))))

;;; =============================================================================
;;; Command Execution
;;; =============================================================================

(defun execute-command (command options)
  "Execute CLI command.

  Commands:
    parse <file> - Parse and display manifest
    validate <file> - Validate manifest
    transform <file> - Transform and output canonical format
    optimize <file> - Optimize manifest
    inspect <file> - Inspect manifest structure
    export <file> <output> - Export to JSON
    help - Show help"
  (case command
    ('parse (cmd-parse options))
    ('validate (cmd-validate options))
    ('transform (cmd-transform options))
    ('optimize (cmd-optimize options))
    ('inspect (cmd-inspect options))
    ('export (cmd-export options))
    ('schema (cmd-schema options))
    ('help (cmd-help options))
    ('version (cmd-version options))
    (_ (progn
         (print-error `#(unknown-command ,command))
         1))))

;;; =============================================================================
;;; Command Implementations
;;; =============================================================================

(defun cmd-parse (options)
  "Parse manifest file and display result."
  (let ((filepath (proplists:get_value 'file options)))
    (if (=:= filepath 'undefined)
      (progn
        (io:format "Error: No file specified~n")
        1)
      (case (manifest-transformer:transform-file filepath)
        ((tuple 'ok manifest)
         (print-manifest manifest options)
         0)
        ((tuple 'error reason)
         (print-error reason)
         1)))))

(defun cmd-validate (options)
  "Validate manifest file."
  (let ((filepath (proplists:get_value 'file options)))
    (if (=:= filepath 'undefined)
      (progn
        (io:format "Error: No file specified~n")
        1)
      (case (manifest-transformer:transform-file filepath)
        ((tuple 'ok manifest)
         (case (manifest-validator:validate manifest)
           ('ok
            (io:format "✓ Manifest is valid~n")
            0)
           ((tuple 'error errors)
            (io:format "✗ Validation failed:~n")
            (print-errors errors)
            1)))
        ((tuple 'error reason)
         (print-error reason)
         1)))))

(defun cmd-transform (options)
  "Transform manifest to canonical format."
  (let ((filepath (proplists:get_value 'file options))
        (output (proplists:get_value 'output options)))
    (if (=:= filepath 'undefined)
      (progn
        (io:format "Error: No file specified~n")
        1)
      (case (manifest-transformer:transform-file filepath)
        ((tuple 'ok manifest)
         (case (manifest-transformer:normalize manifest)
           ((tuple 'ok normalized)
            (output-manifest normalized output options)
            0)
           ((tuple 'error reason)
            (print-error reason)
            1)))
        ((tuple 'error reason)
         (print-error reason)
         1)))))

(defun cmd-optimize (options)
  "Optimize manifest."
  (let ((filepath (proplists:get_value 'file options))
        (output (proplists:get_value 'output options)))
    (if (=:= filepath 'undefined)
      (progn
        (io:format "Error: No file specified~n")
        1)
      (case (manifest-transformer:transform-file filepath)
        ((tuple 'ok manifest)
         (let ((optimized (symbolic-optimizer:optimize manifest)))
           (output-manifest optimized output options)
           0))
        ((tuple 'error reason)
         (print-error reason)
         1)))))

(defun cmd-inspect (options)
  "Inspect manifest structure."
  (let ((filepath (proplists:get_value 'file options)))
    (if (=:= filepath 'undefined)
      (progn
        (io:format "Error: No file specified~n")
        1)
      (case (manifest-transformer:transform-file filepath)
        ((tuple 'ok manifest)
         (print-inspection manifest options)
         0)
        ((tuple 'error reason)
         (print-error reason)
         1)))))

(defun cmd-export (options)
  "Export manifest to JSON."
  (let ((filepath (proplists:get_value 'file options))
        (output (proplists:get_value 'output options)))
    (if (=:= filepath 'undefined)
      (progn
        (io:format "Error: No file specified~n")
        1)
      (if (=:= output 'undefined)
        (progn
          (io:format "Error: No output file specified~n")
          1)
        (case (manifest-transformer:transform-file filepath)
          ((tuple 'ok manifest)
           (case (json-exporter:export-manifest-to-file manifest output)
             ('ok
              (io:format "Exported to ~s~n" (list output))
              0)
             ((tuple 'error reason)
              (print-error reason)
              1)))
          ((tuple 'error reason)
           (print-error reason)
           1))))))

(defun cmd-schema (_options)
  "Output JSON schema for manifests."
  (case (json-exporter:export-json-schema)
    ((tuple 'ok schema)
     (io:format "~s~n" (list schema))
     0)
    ((tuple 'error reason)
     (print-error reason)
     1)))

(defun cmd-help (_options)
  "Display help information."
  (io:format "~s" (list (help-text)))
  0)

(defun cmd-version (_options)
  "Display version information."
  (io:format "WP Praxis Manifest Parser v0.1.0~n")
  (io:format "LFE-based symbolic manifest parsing system~n")
  0)

;;; =============================================================================
;;; CLI Argument Parsing
;;; =============================================================================

(defun parse-cli-args (args)
  "Parse command-line arguments.

  Returns:
    (tuple 'ok command options) | (tuple 'error reason)"
  (case args
    ('()
     '#(ok help ()))
    ((cons command rest)
     (let ((cmd-atom (parse-command command)))
       (case (parse-options rest '())
         ((tuple 'ok options)
          `#(ok ,cmd-atom ,options))
         ((tuple 'error reason)
          `#(error ,reason)))))))

(defun parse-command (command-str)
  "Parse command string to atom."
  (case command-str
    ("parse" 'parse)
    ("validate" 'validate)
    ("transform" 'transform)
    ("optimize" 'optimize)
    ("inspect" 'inspect)
    ("export" 'export)
    ("schema" 'schema)
    ("help" 'help)
    ("--help" 'help)
    ("-h" 'help)
    ("version" 'version)
    ("--version" 'version)
    ("-v" 'version)
    (_ (list_to_atom command-str))))

(defun parse-options
  (['() acc] `#(ok ,(lists:reverse acc)))
  ([(cons "--file" (cons filepath rest)) acc]
   (parse-options rest (cons `#(file ,filepath) acc)))
  ([(cons "-f" (cons filepath rest)) acc]
   (parse-options rest (cons `#(file ,filepath) acc)))
  ([(cons "--output" (cons outpath rest)) acc]
   (parse-options rest (cons `#(output ,outpath) acc)))
  ([(cons "-o" (cons outpath rest)) acc]
   (parse-options rest (cons `#(output ,outpath) acc)))
  ([(cons "--format" (cons format rest)) acc]
   (let ((fmt (list_to_atom format)))
     (parse-options rest (cons `#(format ,fmt) acc))))
  ([(cons "--verbose" rest) acc]
   (parse-options rest (cons '#(verbose true) acc)))
  ([(cons "--json" rest) acc]
   (parse-options rest (cons '#(output-format json) acc)))
  ([(cons "--pretty" rest) acc]
   (parse-options rest (cons '#(pretty true) acc)))
  ([(cons arg rest) acc]
   ;; Positional argument (assume it's the file)
   (if (andalso (not (lists:member arg '("--" "-")))
                (not (=:= (binary:first (list_to_binary arg)) #b(45))))
     (parse-options rest (cons `#(file ,arg) acc))
     (parse-options rest acc))))

;;; =============================================================================
;;; Output Functions
;;; =============================================================================

(defun print-manifest (manifest options)
  "Print manifest to stdout."
  (let ((format (proplists:get_value 'output-format options 'lfe))
        (pretty (proplists:get_value 'pretty options 'false)))
    (case format
      ('json
       (case (if pretty
               (json-exporter:to-json-pretty manifest)
               (json-exporter:to-json manifest))
         ((tuple 'ok json)
          (io:format "~s~n" (list json)))
         ((tuple 'error reason)
          (print-error reason))))
      ('lfe
       (io:format "~p~n" (list manifest)))
      (_
       (io:format "~p~n" (list manifest))))))

(defun output-manifest (manifest output options)
  "Output manifest to file or stdout."
  (case output
    ('undefined
     (print-manifest manifest options))
    (filepath
     (let ((format (proplists:get_value 'output-format options 'json)))
       (case format
         ('json
          (case (json-exporter:export-manifest-to-file manifest filepath)
            ('ok
             (io:format "Written to ~s~n" (list filepath)))
            ((tuple 'error reason)
             (print-error reason))))
         (_
          (case (file:write_file filepath
                                 (io_lib:format "~p~n" (list manifest)))
            ('ok
             (io:format "Written to ~s~n" (list filepath)))
            ((tuple 'error reason)
             (print-error reason)))))))))

(defun print-inspection (manifest _options)
  "Print inspection information."
  (let ((info (symbolic-introspection:inspect-manifest manifest)))
    (io:format "~n=== Manifest Inspection ===~n")
    (io:format "Version: ~p~n" (list (proplists:get_value 'version info)))
    (io:format "Format: ~p~n" (list (proplists:get_value 'format info)))
    (io:format "Symbols: ~p~n" (list (proplists:get_value 'symbols info)))
    (io:format "Workflows: ~p~n" (list (proplists:get_value 'workflows info)))
    (io:format "Contexts: ~p~n" (list (proplists:get_value 'contexts info)))
    (io:format "Dispatches: ~p~n" (list (proplists:get_value 'dispatches info)))
    (io:format "~n")

    ;; Print symbol names
    (let ((symbol-names (symbolic-introspection:list-all-symbols manifest)))
      (io:format "Symbol Names:~n")
      (lists:foreach
        (lambda (name)
          (io:format "  - ~p~n" (list name)))
        symbol-names))

    ;; Print workflow names
    (let ((workflow-names (symbolic-introspection:list-all-workflows manifest)))
      (io:format "~nWorkflow Names:~n")
      (lists:foreach
        (lambda (name)
          (io:format "  - ~p~n" (list name)))
        workflow-names))))

(defun print-error (reason)
  "Print error message."
  (io:format "Error: ~p~n" (list reason)))

(defun print-errors (errors)
  "Print multiple errors."
  (lists:foreach
    (lambda (error)
      (io:format "  - ~p~n" (list error)))
    errors))

;;; =============================================================================
;;; Help Text
;;; =============================================================================

(defun help-text ()
  "Return help text string."
  "WP Praxis Manifest Parser - LFE-based symbolic manifest processing

USAGE:
  manifest-parser <command> [options]

COMMANDS:
  parse <file>              Parse and display manifest
  validate <file>           Validate manifest structure
  transform <file>          Transform to canonical format
  optimize <file>           Optimize manifest
  inspect <file>            Inspect manifest structure
  export <file> <output>    Export to JSON
  schema                    Output JSON schema
  help                      Show this help
  version                   Show version

OPTIONS:
  -f, --file <path>         Input manifest file
  -o, --output <path>       Output file path
  --format <yaml|toml>      Input format (auto-detected by default)
  --json                    Output as JSON
  --pretty                  Pretty-print output
  --verbose                 Verbose output

EXAMPLES:
  # Parse a YAML manifest
  manifest-parser parse manifest.yaml

  # Validate a TOML manifest
  manifest-parser validate config.toml

  # Optimize and export to JSON
  manifest-parser optimize manifest.yaml --output optimized.json --json

  # Inspect manifest structure
  manifest-parser inspect manifest.yaml

  # Get JSON schema
  manifest-parser schema

For more information, see the documentation in docs/

")

;;; =============================================================================
;;; Escript Entry Point
;;; =============================================================================

(defun escript-main (args)
  "Entry point for escript executable.

  This allows the parser to be run as a standalone script."
  (let ((exit-code (main args)))
    (halt exit-code)))
