#lang racket

(require
  racket/path
  stiki/parameters
  sugar)

(provide
 (all-defined-out))

(define (without-trailing-slash path)
    (bytes->path (regexp-replace #rx#"/$" (path->bytes path) "")))

(define (with-trailing-slash path)
    (bytes->path (regexp-replace #rx#"/$" (path->bytes path) "")))

(define (change-ext path ext)
  (add-ext (remove-ext path) ext))

(define (exclude-path? path)
  (for/and ([pattern (exclude-patterns)])
    (not (regexp-match pattern (path->string path)))))


; Are two paths equal?
(define (path=? a b)
  (string=? (path->string a)
            (path->string b)))

(define (path<? a b)
  (string<? (path->string a)
            (path->string b)))

(define (symlink? path)
  (not (=
        (file-or-directory-identity path #t)
        (file-or-directory-identity path #f))))

(define (symlink-to? link dest)
  (and (symlink? link)
       (= (file-or-directory-identity link #f)
          (file-or-directory-identity dest #f))))

; Construct a relative path from a src and dst
(define (relativize src dst)
  (if (path=? (without-trailing-slash (simple-form-path src))
              (without-trailing-slash (simple-form-path dst))) (string->path ".")
      (find-relative-path src dst)))

; Title from path
(define (path->title path)
  (remove-ext (last (explode-path path))))

(define (find path args)
 (map (compose without-trailing-slash string->path)
       (string-split	 
        (with-output-to-string
         (λ () (system (string-join
                        (list* "find \"" (path->string path) "\"" args) ""))))
        "\n")))

; Recursively list all links
(define (lslr path)
  (find path
        '(" -type l -not -path \"*/\\.*\"")))

(define (lsdr path)
  (find path
        '(" -type d -not -path \"*/\\.*\"")))
  

; Recursively list all markdown files
(define (lsfr-md path)
  (find path
        '(" -type f ! -type l -path \"*.md\" -not -path \"*/\\.*\"")))

; List Immediate Subfiles
(define (lsf path)
  (find path
        '(" -maxdepth 1 -type f -not -path \"*/\\.*\"")))

; List Immediate Sublinks
(define (lsl path)
  (find path
        '(" -maxdepth 1 -type l -not -path \"*/\\.*\"")))

; List Immediate Subdirectories
(define (lsd path)
  (find path
        '(" -maxdepth 1 -type d -not -path \"*/\\.*\"")))

; List the categories a given path belongs to
(define (categories-of path)
  (map identity
       (list* (get-enclosing-dir path)
              (map path-only
                   (filter ((curryr symlink-to?) path)
                           (lslr (source-directory)))))))

(define (subarticles-of path)
  (append (lsf path)
          (filter (compose file-exists? normalize-path)
                  (lsl path))))

; Subcategories Of
(define (subcategories-of path)
  (filter-not ((curry path=?) path)
              (append (lsd path)
                      (filter (compose directory-exists? resolve-path)
                              (lsl path)))))
