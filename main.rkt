#lang racket
(require stiki/path-utils
         stiki/parameters
         sugar
         markdown
         web-server/templates
         scribble/text
         racket/path
         "article.html"
         "category.html")

(cond
  [(= (vector-length (current-command-line-arguments)) 4) '()]
  [else (begin
          (displayln "Usage: racket -l stiki/main <src-dir> <dst-dir> <edit-url> <history-url>")
          (exit))])

(source-directory
 (normalize-path (vector-ref (current-command-line-arguments) 0)))

(destination-directory
 (normalize-path (vector-ref (current-command-line-arguments) 1)))

(edit-url-pattern
 (vector-ref (current-command-line-arguments) 2))

(history-url-pattern
 (vector-ref (current-command-line-arguments) 3))

(exclude-patterns
 (map pregexp
       (if (file-exists? (build-path (source-directory) ".stikiignore"))
           (cons ".stikiignore"
                 (file->lines (build-path (source-directory) ".stikiignore")))
           '((".stikiignore")))))


; IO
(define (dtf v path)
  (make-directory* (path-only path))
  (with-output-to-file path (thunk (output v))))

; Write Category HTML
(for ([path (filter directory-exists? (lsr (source-directory)))])
  (displayln path)
  (dtf (render-category (path->title path) (normalize-path path))
       (build-path (destination-directory)
                   (relativize (source-directory) path)
                   "index.html")))

; Write Article HTML
(for ([path (filter-not symlink? (filter markdown? (lsr (source-directory))))])
  (dtf (render-article
        (path->title path)
        (normalize-path path)
        (with-input-from-file path read-markdown))
       (build-path (destination-directory)
                   (find-relative-path (source-directory) (remove-ext path))
                   "index.html"))
  (displayln path))
