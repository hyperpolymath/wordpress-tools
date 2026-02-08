;; yaml-parser-tests.lfe
;; Tests for YAML parser module

(defmodule yaml-parser-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; =============================================================================
;;; Test Fixtures
;;; =============================================================================

(defun test-yaml-simple ()
  "Simple YAML document."
  "name: test\nversion: 1.0\n")

(defun test-yaml-nested ()
  "Nested YAML document."
  "metadata:\n  name: test\n  version: 1.0\nsymbols:\n  - name: symbol1\n")

;;; =============================================================================
;;; Basic Parsing Tests
;;; =============================================================================

(deftest parse-simple-yaml
  (let ((result (yaml-parser:parse-string (test-yaml-simple))))
    (is-tuple result)
    (is-equal 'ok (element 1 result))))

(deftest parse-nested-yaml
  (let ((result (yaml-parser:parse-string (test-yaml-nested))))
    (is-tuple result)
    (is-equal 'ok (element 1 result))))

(deftest parse-empty-yaml
  (let ((result (yaml-parser:parse-string "")))
    (is-tuple result)
    (is-equal 'error (element 1 result))))

;;; =============================================================================
;;; Type Conversion Tests
;;; =============================================================================

(deftest yaml-string-conversion
  (let* ((yaml "key: value\n")
         (result (yaml-parser:parse-string yaml)))
    (case result
      ((tuple 'ok data)
       (is (is_list data))
       (is-equal 'value (proplists:get_value 'key data)))
      (_ (error "Parse failed")))))

(deftest yaml-integer-conversion
  (let* ((yaml "count: 42\n")
         (result (yaml-parser:parse-string yaml)))
    (case result
      ((tuple 'ok data)
       (is-equal 42 (proplists:get_value 'count data)))
      (_ (error "Parse failed")))))

(deftest yaml-boolean-conversion
  (let* ((yaml "enabled: true\n")
         (result (yaml-parser:parse-string yaml)))
    (case result
      ((tuple 'ok data)
       (is-equal 'true (proplists:get_value 'enabled data)))
      (_ (error "Parse failed")))))

(deftest yaml-list-conversion
  (let* ((yaml "items:\n  - one\n  - two\n  - three\n")
         (result (yaml-parser:parse-string yaml)))
    (case result
      ((tuple 'ok data)
       (let ((items (proplists:get_value 'items data)))
         (is (is_list items))
         (is-equal 3 (length items))))
      (_ (error "Parse failed")))))

;;; =============================================================================
;;; Error Handling Tests
;;; =============================================================================

(deftest parse-invalid-yaml
  (let ((result (yaml-parser:parse-string "invalid: [not closed")))
    (is-tuple result)
    (is-equal 'error (element 1 result))))

(deftest parse-nonexistent-file
  (let ((result (yaml-parser:parse-file "/nonexistent/file.yaml")))
    (is-tuple result)
    (is-equal 'error (element 1 result))))

;;; =============================================================================
;;; Manifest-Specific Tests
;;; =============================================================================

(deftest parse-manifest-yaml
  (let* ((manifest "version: 1.0\nsymbols:\n  - name: test\n    type: action\n")
         (result (yaml-parser:parse-string manifest)))
    (case result
      ((tuple 'ok data)
       (is-equal <<"1.0">> (proplists:get_value 'version data))
       (let ((symbols (proplists:get_value 'symbols data)))
         (is (is_list symbols))
         (is-equal 1 (length symbols))))
      (_ (error "Parse failed")))))
