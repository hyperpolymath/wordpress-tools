;; toml-parser.lfe
;; TOML Parsing Module for WP Praxis Manifest Parser
;;
;; This module provides TOML 1.0 parsing capabilities, converting TOML
;; configuration files into LFE data structures compatible with symbolic
;; dispatch and transformation.

(defmodule toml-parser
  "TOML 1.0 parsing with semantic preservation for symbolic manifests."
  (export all))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun parse-file (filepath)
  "Parse a TOML file and return LFE data structure.

  Args:
    filepath: Path to TOML file (string or binary)

  Returns:
    (tuple 'ok data) on success
    (tuple 'error reason) on failure"
  (try
    (case (file:read_file filepath)
      ((tuple 'ok content)
       (parse-string content))
      ((tuple 'error reason)
       `#(error #(file-read-error ,reason))))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun parse-string (toml-str)
  "Parse TOML from string.

  Args:
    toml-str: TOML content as string or binary

  Returns:
    (tuple 'ok data) on success
    (tuple 'error reason) on failure"
  (try
    (let* ((str (ensure-binary toml-str))
           (options (get-toml-options))
           (parsed (toml:decode str options)))
      (case parsed
        ((tuple 'ok data)
         `#(ok ,(toml->lfe data)))
        ((tuple 'error reason)
         `#(error #(toml-parse-error ,reason)))))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun validate-toml (filepath)
  "Validate TOML file without full parsing.

  Args:
    filepath: Path to TOML file

  Returns:
    'ok on valid TOML
    (tuple 'error reason) on invalid TOML"
  (try
    (case (file:read_file filepath)
      ((tuple 'ok content)
       (let ((options (get-toml-options)))
         (case (toml:decode content options)
           ((tuple 'ok _data) 'ok)
           ((tuple 'error reason) `#(error ,reason)))))
      ((tuple 'error reason)
       `#(error #(file-read-error ,reason))))
    (catch
      ((tuple type reason _stacktrace)
       `#(error #(,type ,reason))))))

(defun encode-to-toml (data)
  "Convert LFE data structure to TOML string.

  Args:
    data: LFE data structure (property list or map)

  Returns:
    (tuple 'ok toml-string) on success
    (tuple 'error reason) on failure"
  (try
    (let* ((erlang-data (lfe->toml data))
           (options (get-toml-options))
           (encoded (toml:encode erlang-data options)))
      (case encoded
        ((tuple 'ok toml-str) `#(ok ,toml-str))
        ((tuple 'error reason) `#(error ,reason))))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

;;; =============================================================================
;;; TOML to LFE Conversion
;;; =============================================================================

(defun toml->lfe (toml-data)
  "Convert TOML data (maps) to LFE property lists.

  TOML is inherently map-based, so we convert maps to property lists
  for consistency with YAML parsing and easier symbolic manipulation."
  (cond
    ;; Map -> Property list
    ((is_map toml-data)
     (map->proplist toml-data))

    ;; List of items
    ((is_list toml-data)
     (lists:map #'toml->lfe/1 toml-data))

    ;; Array of tables (list of maps)
    ((andalso (is_list toml-data)
              (not (=:= toml-data '()))
              (is_map (car toml-data)))
     (lists:map #'map->proplist/1 toml-data))

    ;; Primitive types pass through
    ((orelse (is_binary toml-data)
             (is_integer toml-data)
             (is_float toml-data)
             (is_boolean toml-data))
     toml-data)

    ;; DateTime types
    ((is_tuple toml-data)
     (convert-datetime toml-data))

    ;; Fallback
    ('true toml-data)))

(defun map->proplist (map)
  "Convert Erlang map to property list."
  (when (is_map map)
    (lists:map
      (lambda (key)
        (let ((value (maps:get key map)))
          `#(,key ,(toml->lfe value))))
      (maps:keys map))))

(defun convert-datetime (datetime-tuple)
  "Convert TOML datetime tuples to LFE-friendly format."
  (case datetime-tuple
    ;; RFC 3339 datetime
    ((tuple (tuple year month day) (tuple hour minute second) offset)
     `#(datetime
        #(date #(year ,year) #(month ,month) #(day ,day))
        #(time #(hour ,hour) #(minute ,minute) #(second ,second))
        #(offset ,offset)))

    ;; Local datetime (no offset)
    ((tuple (tuple year month day) (tuple hour minute second))
     `#(local-datetime
        #(date #(year ,year) #(month ,month) #(day ,day))
        #(time #(hour ,hour) #(minute ,minute) #(second ,second))))

    ;; Local date only
    ((tuple year month day)
     `#(local-date #(year ,year) #(month ,month) #(day ,day)))

    ;; Local time only
    ((tuple hour minute second)
     `#(local-time #(hour ,hour) #(minute ,minute) #(second ,second)))

    ;; Other tuples pass through
    (other other)))

;;; =============================================================================
;;; LFE to TOML Conversion
;;; =============================================================================

(defun lfe->toml (lfe-data)
  "Convert LFE data structure back to TOML-compatible Erlang maps."
  (cond
    ;; Property list -> Map
    ((is_proplist lfe-data)
     (proplist->map lfe-data))

    ;; List
    ((is_list lfe-data)
     (lists:map #'lfe->toml/1 lfe-data))

    ;; Tagged datetime
    ((is_tuple lfe-data)
     (convert-datetime-back lfe-data))

    ;; Primitives
    ('true lfe-data)))

(defun proplist->map (proplist)
  "Convert property list to Erlang map."
  (maps:from_list
    (lists:map
      (lambda (pair)
        (case pair
          ((tuple key value)
           `#(,key ,(lfe->toml value)))
          (other
           `#(invalid ,other))))
      proplist)))

(defun is_proplist (data)
  "Check if data is a property list (list of 2-tuples)."
  (andalso
    (is_list data)
    (lists:all
      (lambda (item)
        (andalso (is_tuple item)
                 (=:= (tuple_size item) 2)))
      data)))

(defun convert-datetime-back (tagged-datetime)
  "Convert LFE datetime representation back to TOML datetime tuples."
  (case tagged-datetime
    ((tuple 'datetime (tuple 'date date-parts) (tuple 'time time-parts) (tuple 'offset offset))
     `#(,(extract-date date-parts)
        ,(extract-time time-parts)
        ,offset))

    ((tuple 'local-datetime (tuple 'date date-parts) (tuple 'time time-parts))
     `#(,(extract-date date-parts)
        ,(extract-time time-parts)))

    ((tuple 'local-date date-parts)
     (extract-date date-parts))

    ((tuple 'local-time time-parts)
     (extract-time time-parts))

    (other other)))

(defun extract-date (date-parts)
  "Extract date tuple from property list."
  (let ((year (proplists:get_value 'year date-parts))
        (month (proplists:get_value 'month date-parts))
        (day (proplists:get_value 'day date-parts)))
    `#(,year ,month ,day)))

(defun extract-time (time-parts)
  "Extract time tuple from property list."
  (let ((hour (proplists:get_value 'hour time-parts))
        (minute (proplists:get_value 'minute time-parts))
        (second (proplists:get_value 'second time-parts)))
    `#(,hour ,minute ,second)))

;;; =============================================================================
;;; TOML Type Handling
;;; =============================================================================

(defun get-toml-type (data)
  "Determine the TOML type of data."
  (cond
    ((is_map data) 'table)
    ((is_list data)
     (if (is_proplist data)
       'table
       'array))
    ((is_binary data) 'string)
    ((is_integer data) 'integer)
    ((is_float data) 'float)
    ((is_boolean data) 'boolean)
    ((is_tuple data) 'datetime)
    ('true 'unknown)))

(defun get-table-type (table-data)
  "Determine if table is standard or inline."
  (cond
    ((is_map table-data)
     (if (< (maps:size table-data) 5)
       'inline-table
       'standard-table))
    ((is_proplist table-data)
     (if (< (length table-data) 5)
       'inline-table
       'standard-table))
    ('true 'unknown)))

;;; =============================================================================
;;; Configuration
;;; =============================================================================

(defun get-toml-options ()
  "Get TOML parser options from application environment."
  (let ((default-opts '#m(return_maps true)))
    (case (application:get_env 'manifest_parser 'toml_options)
      ((tuple 'ok opts) (maps:merge default-opts opts))
      ('undefined default-opts))))

;;; =============================================================================
;;; Utility Functions
;;; =============================================================================

(defun ensure-binary (str)
  "Ensure string is binary."
  (cond
    ((is_binary str) str)
    ((is_list str) (list_to_binary str))
    ('true (error `#(invalid-string-type ,str)))))

(defun pretty-print-error (error)
  "Format TOML parsing error for human consumption."
  (case error
    ((tuple 'error (tuple 'toml-parse-error reason))
     (io_lib:format "TOML Parse Error: ~p" (list reason)))
    ((tuple 'error (tuple type reason stacktrace))
     (io_lib:format "TOML Error [~p]: ~p~nStacktrace: ~p"
                    (list type reason stacktrace)))
    ((tuple 'error reason)
     (io_lib:format "TOML Error: ~p" (list reason)))
    (other
     (io_lib:format "Unknown error: ~p" (list other)))))

;;; =============================================================================
;;; Manifest-Specific Helpers
;;; =============================================================================

(defun extract-metadata (filepath)
  "Extract metadata from TOML file for validation."
  (case (parse-file filepath)
    ((tuple 'ok data)
     `#(ok #(file ,filepath
             type ,(get-toml-type data)
             size ,(erlang:external_size data))))
    ((tuple 'error reason)
     `#(error ,reason))))

(defun get-symbols (parsed-data)
  "Extract symbols list from parsed TOML manifest."
  (proplists:get_value 'symbols parsed-data '()))

(defun get-workflows (parsed-data)
  "Extract workflows from parsed TOML manifest."
  (proplists:get_value 'workflows parsed-data '()))

(defun get-metadata (parsed-data)
  "Extract metadata section from parsed TOML manifest."
  (proplists:get_value 'metadata parsed-data '()))

(defun get-symbol-array (parsed-data)
  "Extract array of symbols from [[symbols]] array of tables."
  (proplists:get_value 'symbol parsed-data '()))

(defun normalize-array-of-tables (parsed-data key)
  "Normalize TOML array of tables to list.

  TOML [[key]] syntax creates array of tables, which we normalize
  to a simple list for consistency with YAML arrays."
  (case (proplists:get_value key parsed-data)
    ('undefined '())
    (array-data
      (if (is_list array-data)
        array-data
        (list array-data)))))
