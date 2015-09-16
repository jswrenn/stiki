#lang racket

(require
  stiki/parameters
  sugar)

(provide
 (all-defined-out))

(define (exclude-path? path)
  (for/and ([pattern (exclude-patterns)])
    (not (regexp-match pattern (path->string path)))))

; A filtered listing of the directory's immediate children
(define (ls path)
  (filter exclude-path?
          (directory-list path #:build? #t)))

;  A filtered recursive listing of the directory's children
(define (lsr path)
  (filter exclude-path?
          (map ((curry find-relative-path) path)
               (sequence->list (in-directory path)))))

; Are two paths equal?
(define (path=? a b)
  (string=? (path->string a)
            (path->string b)))

(define (symlink? path)
  (not (=
        (file-or-directory-identity path #t)
        (file-or-directory-identity path #f))))

(define (symlink-to? link dest)
  (and (symlink? link)
       (= (file-or-directory-identity link #f)
          (file-or-directory-identity dest #f))))

; Is a path a markdown file?
(define (markdown? path)
  (and (equal? (filename-extension path) #"md")
       (file-exists? path)))

; Construct a relative path from a src and dst
(define (relativize src dst)
  (if (path=? src dst) (build-path 'same)
      (find-relative-path src dst)))

; Title from path
(define (path->title path)
  (remove-ext (last (explode-path path))))

; List the categories a given path belongs to
(define (categories-of path)
  (list* (get-enclosing-dir path)
         (map path-only
              (filter ((curryr symlink-to?) path)
                      (lsr (source-directory))))))

(define (fast-directory-list path)
  (string-split	 
   (with-output-to-string
    (λ () (system
           (string-join (list
                         "find "
                         (path->string path)
                         " -not -path \"*/\\.*\"")))))
   "\n"))