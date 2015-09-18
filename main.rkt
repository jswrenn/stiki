#lang racket
(require stiki/path-utils
         stiki/parameters
         sugar
         markdown
         web-server/templates
         scribble/text
         racket/path
         (prefix-in xml: xml)
         "article.html"
         "category.html")

#;(cond
  [(= (vector-length (current-command-line-arguments)) 4) '()]
  [else (begin
          (displayln "Usage: racket -l stiki/main <src-dir> <dst-dir> <edit-url> <history-url>")
          (exit))])

(source-directory
 (without-trailing-slash
  (simple-form-path
   (string->path (vector-ref (current-command-line-arguments) 0)))))

(destination-directory
 (without-trailing-slash
  (simple-form-path
   (string->path (vector-ref (current-command-line-arguments) 1)))))

(edit-url-pattern
 (vector-ref (current-command-line-arguments) 2))

(history-url-pattern
 (vector-ref (current-command-line-arguments) 3))



#;(edit-url-pattern "")
#;(history-url-pattern "")

(define (rm-ext path)
    (bytes->path (regexp-replace #rx#"\\.md*$" (path->bytes path) "")))

(define (ch-ext path)
    (bytes->path (regexp-replace #rx#"\\.md*$" (path->bytes path) "")))

(define (xexpr-map f x)
  ;;((xexpr/c (listof xexpr/c) . -> . (listof xexpr/c)) xexpr/c . -> . xexpr/c)
  (define (inner ps f x)
    (match x
      ;; xexpr with explicit attributes (even if just '())
      [`(,(? symbol? tag) ([,(? symbol? ks) ,(? string? vs)] ...) . ,es)
       (f `(,tag
            ,(map list ks vs)
            ,@(append* (map (curry inner (cons x ps) f)
                            es)))
          ps)]
      ;; xexpr with no attributes: transform to empty list
      [`(,(? symbol? tag) . ,es) (inner ps f `(,tag () ,@es))]
      [x (f x ps)]))
  (append* (inner '() f x)))


(define preprocess
  ((curry xexpr-map)
   (lambda (xexpr _)
     (match xexpr
       ;; Change p to div
      ; [`(p ,as . ,es) `((div ,as ,@es))]
       [`(a ([href ,src]) . ,es)
        `((a ([href ,(path->string (ch-ext src))]) ,@es))]
       ;; Replace (em x ...) with x ...
       ;[`(em ,_ . ,es) `(,@es)]
       ;; Delete (strong _ ...) completely
       ;[`(strong . ,_) `()]
       ;; Remains as-is.
       [x `(,x)]))))


; IO
(define (dtf v path)
  (make-directory* (path-only path))
  (with-output-to-file path (thunk (output v))))

; Write Category HTML
(for ([path (lsdr (source-directory))])
  (dtf (render-category (path->title path)
                        path)
       (build-path (destination-directory)
                   (relativize (source-directory)
                               path)
                   "index.html"))
  (printf "Processing Category: ~a\n" path))


;(map (λ(x) (if (xml:xexpr? x) (preprocess x) x))
;                            (with-input-from-file path read-markdown)))

; Write Article HTML
(for ([path (lsfr-md (source-directory))])
  (dtf (render-article (path->title path)
                       path
                      (with-input-from-file path read-markdown))
       (build-path (destination-directory)
                   (relativize (source-directory)
                               path)))
  (printf "Rendering Article: ~a\n" path))
