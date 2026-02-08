;; validator-tests.lfe
;; Tests for manifest validator

(defmodule validator-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

(defun test-manifest ()
  '(#(version "1.0")
    #(format yaml)
    #(metadata (#(name "test")))
    #(symbols (#(#(name test-symbol)
                  #(type action)
                  #(context default)
                  #(dependencies ()))))))

(deftest validate-correct-manifest
  (let ((result (manifest-validator:validate (test-manifest))))
    (is-equal 'ok result)))

(deftest validate-missing-version
  (let* ((manifest (lists:keydelete 'version 1 (test-manifest)))
         (result (manifest-validator:validate manifest)))
    (is-tuple result)
    (is-equal 'error (element 1 result))))

(deftest detect-circular-dependencies
  (let ((symbols '(#(#(name a) #(dependencies (b)))
                   #(#(name b) #(dependencies (a))))))
    (let ((result (manifest-validator:check-circular-dependencies symbols)))
      (is-tuple result)
      (is-equal 'error (element 1 result)))))
