(defun testRpg ()
  (org-element-map (org-element-parse-buffer) 'headline
    (lambda (headline)
      (if (org-element-property :TODO))
      (message "%s" headline)
      (setq headline (org-json-straigten-tree headline)) 
      (setq headline (json-encode-list headline)) 
      (setq headline (let ((json-object-type 'plist)
                           (json-array-type 'list) )
                       (json-read-from-string headline)))
      (setq headline (stringToSymbols headline))
      (org-element-interpret-data headline))))

(remove-hook 'org-after-todo-state-change-hook
             (lambda () org-state))

(json-plist-p `(:text ,(+ 1 1)))



(defun org-json-straigten-tree (tree)
  "Null out circular references in the org-element TREE"
  (org-element-map tree (append org-element-all-elements
				org-element-all-objects '(plain-text))

    ;; the crux of this is to nullify references that turn the tree
    ;; into a Circular Object which the json module can't handle
    (lambda (x) 
      ;; guaranteed circluar
      (if (org-element-property :parent x)
	  (org-element-put-property x :parent "none"))
      ;; maybe circular if multiple structures accidently identical
      (if (org-element-property :structure x)
	  (org-element-put-property x :structure "none"))
      ))
  tree)

(defun stringToSymbols (list)
  (when (stringp (car-safe list))
    (setq list (-replace-at 0 (make-symbol (car list)) list)))
  (-map
   (lambda(x) (if (listp x)
                  (stringToSymbols x)
                x))
   list))
