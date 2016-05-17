(use-package request)
(request
 "localhost:4000/receiveAward"
 :type "POST"
 :data (json-encode '(("type" . "quest") ("amount" . 5)))
 :headers '(("Content-Type" . "application/json"))
 :success (cl-function
           (lambda (&key data &allow-other-keys)
             (message "I sent: %S" (assoc-default 'form data)))))


(use-package request-deferred :ensure t)
(deferred:$
  (request-deferred
   "http://jsonplaceholder.typicode.com/posts/1"
   :parser 'json-read)
  (deferred:nextc it (lambda (:data data &rest args) (message "%s" (alist-get 'userId data)))))
  t)
(require 'request-deferred)

(deferred:$
  (request-deferred "http://httpbin.org/get" :parser 'json-read)
  (deferred:nextc it
    (lambda (response)
      (message "Got: %S" (request-response-data response)))))

(progn
  (request
   "http://jsonplaceholder.typicode.com/posts/1"
   :parser 'json-read
   :success (lambda (resp) (message "%s" (alist-get 'userId (request-response-data resp)))))
  t)
