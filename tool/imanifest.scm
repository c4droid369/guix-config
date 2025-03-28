(define-module (tool imanifest)
  ;; Scheme library
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 format)
  #:use-module (ice-9 colorize)
  #:use-module (ice-9 readline)
  ;; Guix utility
  #:use-module (guix profiles)
  #:use-module (guix packages)
  #:use-module (guix inferior)
  ;; Guix packages
  #:use-module (gnu packages)
  ;; Module exports
  #:export (group-color
	    error-color
	    needs
	    compute-imanifest))

(define group-color '(BLUE BOLD))
(define error-color '(RED BOLD))

(define (flatten lst)
  (let loop ((lst lst) (acc '()))
    (cond ((null? lst) acc)
	  ((pair? lst) (loop (car lst) (loop (cdr lst) acc)))
	  (else (cons list acc)))))

(define (needs what x)
  (cond ((procedure? what) (if (what) x '()))
	((boolean? what) (if what x '()))
	(else (let ((deps (delete x (delete-duplicates what))))
		(if (null? deps) x
		    (letrec ((fn (lambda (l)
				   (if (equal? l 'what) deps
				       (if (every (lambda (i) (member i l)) deps)
					   x fn)))))
		      fn))))))

(define (resolve to-resolve)
  (receive (ps is)
      (partition procedure? to-resolve)
    (letrec ((loop (lambda (ps is)
		     (if (null? ps)
			 is
			 (receive (ps+ is+)
			     (partition procedure? (map (lambda (p) (p is)) ps))
			   (loop (if (equal? ps ps+)
				     '()
				     ps+)
				 (flatten (append is is+))))))))
      (loop ps (flatten is)))))

(define (sort-symbols symbols)
  (map string->symbol (sort (map symbol->string symbols) string<)))

(define completions '())

(define (find-completions text xs compls)
  (if (null? xs)
      compls
      (let ((x (car xs)))
	(find-completions text (cdr xs)
			  (if (string-prefix? text x)
			      (cons x compls)
			      compls)))))

(define (make-completer groups)
  (lambda (text state)
    (unless state
      (set! completions (find-completions text (map symbol->string groups) '())))
    (if (null? completions)
	#f
	(let ((compl (car completions)))
	  (set! completions (cdr completions))
	  compl))))

(define (select-from-group group group-name)
  (format #t "~%Enter a list with the tools you want to set up from the `~a' group.~%"
	  (colorize-string (symbol->string group-name) group-color))
  (format #t "Here are the available tools: ~a.~%"
	  (colorize-string (format #f "~a" (sort-symbols (remove (lambda (x)
								   (equal? x '_))
								 (map car group)))) group-color))
  (newline)
  (letrec ((selected (with-input-from-string
			 (with-readline-completion-function
			  (make-completer (map car group))
			  (lambda ()
			    (string-append "(" (readline "> ") ")")))
		       (lambda ()
			 (read (current-input-port)))))
	   (loop (lambda (l acc)
		   (if (null? l)
		       acc
		       (let* ((sel (car l))
			      (next (assoc-ref group sel)))
			 (if (next
			      (loop (cdr l) (append acc (traverse-group next sel)))
			      (begin
				(display (colorize-string (format #f "~%ERROR: There's no group named \"~a\".~%~%" sel)
							  error-color))
				(exit l))))))))
	   (loop (if (equal? selected '(ALL))
		     (map car group)
		     selected)
		 (or (assoc-ref group '_) '())))))

(define (traverse-group group group-name)
  (if (and (not (null? group)) (list? (car group)))
      (select-from-group group group-name)
      group))

(define (compute-packages groups)
  (resolve (select-from-group groups 'base)))

(define (compute-imanifest groups)
  (display "To choose everything from a group you can just type `ALL' (no quotes).")
  (newline)
  (activate-readline)
  (let ((to-install (compute-packages groups)))
    (concatenate-manifests
     (list (specifications->manifest (filter string? to-install))
	   (packages->manifest (filter package? to-install))
	   (packages->manifest (filter inferior-package? to-install))))))
