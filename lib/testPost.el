(use-package request)
(request
 "localhost:4000/receiveAward"
 :type "POST"
 :data (json-encode '(("type" . "quest") ("amount" . 5)))
 :headers '(("Content-Type" . "application/json"))
 :success (cl-function
           (lambda (&key data &allow-other-keys)
             (message "I sent: %S" (assoc-default 'form data)))))

(request
 "localhost:4000/totalPoints" 
 :success (function*
           (lambda (&key data &allow-other-keys)
             (message "I sent: %S" (assoc-default 'args data)))))
