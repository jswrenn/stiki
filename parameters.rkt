#lang racket

(provide (all-defined-out))

(define source-directory (make-parameter #f))
(define destination-directory (make-parameter #f))
(define edit-url-pattern (make-parameter #f))
(define history-url-pattern (make-parameter #f))
(define exclude-patterns (make-parameter #f))

