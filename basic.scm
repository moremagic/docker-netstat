#!/usr/bin/env gosh

;;
;; Sample web server to show how to use makiki.  Run it in the
;; top source directory of Gauche-makiki.
;;

(add-load-path ".." :relative)
(use gauche.threads)
(use gauche.parseopt)
(use gauche.process)
(use text.html-lite)
(use srfi-1)
(use srfi-13)
(use makiki)

;; main program just starts the server.
;; logs goes to stdout (:access-log #t :error-log #t)
;; we pass the timestamp to :app-data - it is avaliable to the 'app'
;;  argument in the http handlers below.
(define (main args)
  (let-args (cdr args) ([port "p|port=i" 8012])
    (start-http-server :access-log #t :error-log #t :port port
                       :app-data (sys-ctime (sys-time))))
  0)

;; The root path handler.  We show some html, constructed by text.html-lite.
(define-http-handler "/"
  (^[req app]
    (respond/ok req
      (html:html
       (html:head (html:title "Makiki"))
       (html:body (html:h1 "You're running Makiki http server")
                  (html:p "The server is running since " app
                          "at port " (request-server-port req)
                          " on host " (request-server-host req)
                          ".")
                  (html:p
                   (html:a :href "/src/" "Browse makiki source"))
                  (html:p
                   (html:a :href "/echo-headers" "View request headers"))
                  (html:p
                   (html:a :href "/netstat" "host-netstat"))
                  (html:p
                   (html:a :href "/port-check" "port-check")))))))

;; The path '/src/' shows the current directory and below.
;; We pass the proc to extract path below '/src' to the :path-trans
;; arg of file-handler, which will interpret the translated path relative
;; to the document-root, which defaults to ".".
(define-http-handler #/^\/src(\/.*)$/
  (file-handler :path-trans (^[req] ((request-path-rxmatch req) 1))))

;; Redirect "/src" to "/src/".
(define-http-handler "/src"
  (^[req app] (respond/redirect req "/src/")))

;; '/echo-header' reports back http request headers, handy for diagnostics.
(define-http-handler "/echo-headers"
  (^[req app]
    (respond/ok req
                (html:html
                 (html:head (html:title "echo-header"))
                 (html:body (html:h1 "Request headers")
                            (html:pre
                             (map (^p (map (^v #`",(car p): ,v\n") (cdr p)))
                                  (request-headers req))))))))


;; netstat app
(define-http-handler "/netstat"
  (^[req app]
    (respond/ok req
        (html:html
          (html:head (html:title "Makiki-netstat"))
          (html:body (html:h1 "You're running server netstat")
            (html:pre
              (string-join
                (cmd-call '(netstat -an)) "\r\n")))))))

;; port-check app
(define-http-handler "/port-check"
  (^[req app]
    (respond/ok req
        (html:html
          (html:head (html:title "Makiki-port-check"))
          (html:body (html:h1 "You're running server port-check")
            (html:p "The server is running since " app
                    "at port " (request-server-port req)
                    " on host " (request-server-host req)
                    ".")
            (html:pre
              (string-join (use-port-string (iota (- 51000 32700) 32700)
                (strlist->numlist
                  (map (^[s] (string-drop s 3))
                    (partition (^[s] (string-prefix? ":::" s))
                      (map (pick-num 4)
                        (map (^[str] (string-split str #/\s+/)) (cmd-call '(netstat -an)))))))) "</br>")))))))


(define cmd-call
    (^(cmd)
        (process-output->string-list cmd)))

(define pick-num
  (^[num]
    (^[lst] (car (reverse (take* lst num))))))

(define use-port-string
  (^(lst use)
     (map (^p (if (member p use) #"~|p|(* in use)" #"~|p|")) lst)))

(define strlist->numlist
  (^[strlst]
    (map string->number strlst)))

;;(map (^(lst) (pick lst 3)) '((1 2 3 4) (5 6 7 8) (9 10 11 12) (13 14 15 16)))
;;(string-join (use-port-string (iota (- 50201 49000) 49000) (list 49010 50000)) "</br>\r\n")



;; Local variables:
;; mode: scheme
;; end:
