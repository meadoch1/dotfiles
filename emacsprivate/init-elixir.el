;; Elixir
;; Treat _ as a word character
(with-eval-after-load 'elixir-mode
  (modify-syntax-entry ?_ "w" elixir-mode-syntax-table))

(setq alchemist-test-ask-about-save nil)
(setq alchemist-goto-elixir-source-dir "~/git/elixir")
(setq alchemist-goto-erlang-source-dir "~/git/otp")

(defun elixir-flycheck-project-root ()
  (locate-dominating-file buffer-file-name "mix.exs"))

(defun elixir-flycheck-cd-option ()
  (format "IEx.Helpers.cd(\"%s\")"
          (elixir-flycheck-project-root)))

;; Add flychecker for dialyzer
(with-eval-after-load 'flycheck
  (flycheck-define-checker elixir-dogma
    "Defines a checker for elixir with dogma"
    :command ("elixir" "-e" (eval (elixir-flycheck-cd-option)) "-S"
              "mix" "dogma" "--format" "flycheck" "--stdin" source-original)
    :predicate
    (lambda ()
      (let ((root (elixir-flycheck-project-root)))
        (and
         root
         (flycheck-buffer-saved-p)
         (file-exists-p (concat root "mix.exs"))
         (file-exists-p (concat root "deps/dogma")))))
    :standard-input t
    :error-patterns
    (
     (info line-start (file-name) ":" line ":" column ": " (or "C" "R" "D") ": " (optional (id (one-or-more (not (any ":")))) ": ") (message) line-end)
     (warning line-start (file-name) ":" line ":" column ": " (or "W" "E" "F") ": " (optional (id (one-or-more (not (any ":")))) ": ") (message) line-end))
    :error-filter
    (lambda (errors)
      (dolist (err (flycheck-sanitize-errors errors))
        (setf (flycheck-error-filename err)
              (concat (elixir-flycheck-project-root)
                      (flycheck-error-filename err))))
      errors)
    :modes (elixir-mode))

  (flycheck-define-checker elixir-credo
    "Erlang syntax checker based on dialyzer."
    :command ("elixir" "-e" (eval (elixir-flycheck-cd-option)) "-S"
              "mix" "credo" "--format" "flycheck" source-inplace)
    :standard-input t
    :predicate
    (lambda ()
      (let ((root (elixir-flycheck-project-root)))
        (and
         root
         (file-exists-p (concat root "mix.exs"))
         (file-exists-p (concat root "deps/credo")))))
    :error-patterns
    ((info line-start (file-name) ":" line ":" column ": " (or "F" "R" "C")  ": " (message) line-end)
     (info line-start (file-name) ":" line ": " (or "F" "R" "C")  ": " (message) line-end)
     (warning line-start (file-name) ":" line ":" column ": " (or "D" "W")  ": " (message) line-end)
     (warning line-start (file-name) ":" line ": " (or "D" "W")  ": " (message) line-end))
    :modes elixir-mode)

  (flycheck-define-checker elixir-dialyzer
    "Erlang syntax checker based on dialyzer."
    :command ("elixir" "-e" (eval (elixir-flycheck-cd-option)) "-S"
              "mix" "dialyzer" source-original)
    :predicate
    (lambda ()
      (let ((root (elixir-flycheck-project-root)))
        (and
         root
         (flycheck-buffer-saved-p)
         (file-exists-p (concat root "mix.exs"))
         (file-exists-p (concat root "deps/dialyxir")))))
    :error-patterns
    ((warning line-start
              (file-name)
              ":"
              line
              ": warning: "
              (message)
              line-end)
     (error line-start
            (file-name)
            ":"
            line
            ":"
            (message)
            line-end))
    :error-filter
    (lambda (errors)
      (dolist (err (flycheck-sanitize-errors errors))
        (setf (flycheck-error-filename err)
              (concat (elixir-flycheck-project-root)
                      (flycheck-error-filename err))))
      errors)
    :modes elixir-mode)

  (add-to-list 'flycheck-checkers 'elixir-credo)
  (add-to-list 'flycheck-checkers 'elixir-dogma)
  (add-to-list 'flycheck-checkers 'elixir-dialyzer t)
  (flycheck-add-next-checker 'elixir-credo '(t . elixir-dogma))
  (flycheck-add-next-checker 'elixir-dogma '(t . elixir-dialyzer)))

(add-hook 'elixir-mode-hook (lambda ()
                              (flycheck-mode)))

;; Pin alchemist windows to bottom
(push '("*alchemist test report*"
        :position bottom :noselect t :dedicated t :stick t :height 25)
      popwin:special-display-config)
(push '("*alchemist mix*"
        :position bottom :noselect t :dedicated t :stick t :height 25)
      popwin:special-display-config)
(push '("*alchemist help*"
        :position bottom :noselect t :dedicated t :stick t :height 25)
      popwin:special-display-config)
(push '("*Alchemist-IEx*"
        :position bottom :noselect t :dedicated t :stick t :height 25)
      popwin:special-display-config)

(provide 'init-elixir)
