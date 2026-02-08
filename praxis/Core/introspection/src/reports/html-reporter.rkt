#lang racket/base

;;; HTML Reporter
;;; Generates HTML reports for introspection results

(require racket/contract
         racket/string
         racket/list
         racket/hash
         racket/format)

(provide generate-html-report
         save-html-report
         html-template
         format-html-table
         format-html-list)

;; Generate complete HTML report
(define/contract (generate-html-report results)
  (-> hash? string?)

  (define title "WP Praxis Introspection Report")

  (string-append
   (html-header title)
   (html-summary results)
   (html-state-section results)
   (html-trace-section results)
   (html-analysis-section results)
   (html-feedback-section results)
   (html-footer)))

;; Save HTML report to file
(define/contract (save-html-report results path)
  (-> hash? path-string? void?)

  (call-with-output-file path
    #:exists 'replace
    (λ (out)
      (display (generate-html-report results) out))))

;; HTML header
(define (html-header title)
  (format "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"UTF-8\">
  <title>~a</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 3px solid #0066cc; padding-bottom: 10px; }
    h2 { color: #0066cc; margin-top: 30px; }
    .summary { background: #e8f4f8; padding: 15px; border-radius: 5px; margin: 20px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #0066cc; color: white; }
    .critical { color: #d32f2f; font-weight: bold; }
    .high { color: #f57c00; font-weight: bold; }
    .medium { color: #fbc02d; }
    .low { color: #388e3c; }
    .good { color: #4caf50; font-weight: bold; }
  </style>
</head>
<body>
<div class=\"container\">
<h1>~a</h1>\n" title title))

;; HTML summary section
(define (html-summary results)
  (if (hash-has-key? results 'feedback)
      (let ([feedback (hash-ref results 'feedback)])
        (if (hash-has-key? feedback 'summary)
            (let ([summary (hash-ref feedback 'summary)])
              (format "<div class=\"summary\">
<h2>Summary</h2>
<p><strong>Total Issues:</strong> ~a</p>
<p><span class=\"critical\">Critical: ~a</span> |
   <span class=\"high\">High: ~a</span> |
   <span class=\"medium\">Medium: ~a</span> |
   <span class=\"low\">Low: ~a</span></p>
<p><strong>Optimization Opportunities:</strong> ~a</p>
<p><strong>Anti-patterns Detected:</strong> ~a</p>
</div>\n"
                      (hash-ref summary 'total-items 0)
                      (hash-ref summary 'critical 0)
                      (hash-ref summary 'high 0)
                      (hash-ref summary 'medium 0)
                      (hash-ref summary 'low 0)
                      (hash-ref summary 'optimization-opportunities 0)
                      (hash-ref summary 'antipatterns-detected 0)))
            ""))
      ""))

;; HTML state section
(define (html-state-section results)
  (if (hash-has-key? results 'state)
      (let ([state (hash-ref results 'state)])
        (string-append
         "<h2>Symbolic State</h2>\n"
         (if (hash-has-key? state 'statistics)
             (let ([stats (hash-ref state 'statistics)])
               (format "<p><strong>Total Symbols:</strong> ~a</p>
<p><strong>Maximum Depth:</strong> ~a</p>\n"
                       (hash-ref stats 'total-symbols 0)
                       (hash-ref stats 'max-depth 0)))
             "")))
      ""))

;; HTML trace section
(define (html-trace-section results)
  (if (hash-has-key? results 'trace)
      "<h2>Execution Trace</h2>\n<p>Trace data available.</p>\n"
      ""))

;; HTML analysis section
(define (html-analysis-section results)
  (if (hash-has-key? results 'analysis)
      (let ([analysis (hash-ref results 'analysis)])
        (string-append
         "<h2>Semantic Analysis</h2>\n"
         (format "<p><strong>Integrity Score:</strong> ~a</p>\n"
                 (~r (hash-ref analysis 'integrity-score 1.0) #:precision 2))))
      ""))

;; HTML feedback section
(define (html-feedback-section results)
  (if (and (hash-has-key? results 'feedback)
           (hash-has-key? (hash-ref results 'feedback) 'feedback-items))
      (let ([items (hash-ref (hash-ref results 'feedback) 'feedback-items)])
        (if (null? items)
            "<h2>Feedback</h2>\n<p class=\"good\">No issues found!</p>\n"
            (string-append
             "<h2>Feedback Items</h2>\n"
             "<table>\n<tr><th>Priority</th><th>Title</th><th>Description</th></tr>\n"
             (string-join
              (map format-feedback-row items)
              "\n")
             "\n</table>\n")))
      ""))

(define (format-feedback-row item)
  (format "<tr><td class=\"~a\">~a</td><td>~a</td><td>~a</td></tr>"
          (hash-ref item 'priority 'low)
          (string-upcase (symbol->string (hash-ref item 'priority 'low)))
          (hash-ref item 'title "")
          (hash-ref item 'description "")))

;; HTML footer
(define (html-footer)
  "</div>\n</body>\n</html>")

;; HTML template function
(define/contract (html-template content)
  (-> string? string?)

  (string-append (html-header "Report") content (html-footer)))

;; Format hash table as HTML table
(define/contract (format-html-table data)
  (-> hash? string?)

  (string-append
   "<table>\n"
   (string-join
    (for/list ([(k v) (in-hash data)])
      (format "<tr><td><strong>~a</strong></td><td>~a</td></tr>" k v))
    "\n")
   "\n</table>\n"))

;; Format list as HTML list
(define/contract (format-html-list items)
  (-> (listof any/c) string?)

  (string-append
   "<ul>\n"
   (string-join
    (map (λ (item) (format "<li>~a</li>" item)) items)
    "\n")
   "\n</ul>\n"))
