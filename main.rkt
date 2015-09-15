#lang racket
(require sugar
         markdown
         web-server/templates
         racket/cmdline
         racket/path)

(define src-dir
  (make-parameter (normalize-path (vector-ref (current-command-line-arguments) 0))))
(define dst-dir
  (make-parameter (normalize-path (vector-ref (current-command-line-arguments) 1))))

; Path Utilities
; Are two paths equal?
(define (path=? a b)
  (string=? (path->string a)
            (path->string b)))

; Is a path a symlink?
(define (symlink? path)
  (not (path=? path (normalize-path path))))

; Is a path a markdown file?
(define (markdown? path)
  (and (equal? (filename-extension path) #"md")
       (file-exists? path)))

(define (relativize src dst)
  (if (path=? src dst) (build-path 'same)
      (find-relative-path src dst)))

(define (hidden? path)
  (not (andmap
    (λ(p) (not (char=? (string-ref (path->string p) 0) #\.)))
     (explode-path path))))

; List the categories a given path belongs to
(define (categories-of path)
  (list* (get-enclosing-dir path)
         (map path-only
              (filter (compose ((curry path=?) path) normalize-path)
                      (filter link-exists?
                              (filter-not hidden?
                                          (sequence->list (in-directory (src-dir)))))))))

; RENDERING

(define (render-page
         #:title page-title
         #:content page-content)
  (include-template "page.html"))

; CATEGORY -> HTML
(define (category->html category-path)
  (render-page
   #:title (last (explode-path category-path))
   #:content (include-template "category.html")))

; ARTICLE -> HTML
(define (article->html article-path)
  (render-page
   #:title (remove-ext (file-name-from-path article-path))
   #:content (let* ([title (remove-ext (file-name-from-path article-path))]
                   [content
                     (with-input-from-file article-path read-markdown)])
               (include-template "article.html"))))

; IO
(define (dtf v path)
  (make-directory* (path-only path))
  (display-to-file v path))

; Write Article HTML
(define (pages)
  (filter-not symlink?
              (filter markdown?
                      (filter-not hidden? (sequence->list(in-directory (src-dir)))))))


(for ([path (pages)])
  (dtf (article->html path)
       (build-path (dst-dir)
                   (find-relative-path (src-dir) (remove-ext path))
                   "index.html")))

; Write Category HTML
(define (categories)
  (cons (src-dir)
  (filter directory-exists?
          (filter-not hidden? (sequence->list (in-directory (src-dir)))))))

(displayln (pages))

(for ([path (categories)])
  (dtf (category->html path)
       (build-path (dst-dir)
                   (relativize (src-dir) path)
                   "index.html")))