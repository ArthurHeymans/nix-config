(setq user-full-name "Arthur Heymans"
      user-mail-address "arthur@aheymans.xyz")

(setq gnus-select-method '(nnnil "")
      gnus-secondary-select-methods '((nnimap "gmail"
                                              (nnimap-address "imap.gmail.com")
                                              (nnimap-server-port 993)
                                              (nnimap-stream ssl))
                                      (nnimap "aheymans"
                                              (nnimap-address "imap.gmail.com")
                                              (nnimap-server-port 993)
                                              (nnimap-stream ssl))
                                      (nnimap "9elements"
                                              (nnimap-address "imap.gmail.com")
                                              (nnimap-server-port 993)
                                              (nnimap-stream ssl))
                                      ))

(setq gnus-ignored-newsgroups
      (concat gnus-ignored-newsgroups "\\|^\\[Gmail\\]/Spam"))

                                        ; Reply to mails with matching email address
(setq gnus-posting-styles
      '((".*" ; Matches all groups of messages
         (address "Arthur Heymans <arthur@aheymans.xyz>")
         ("X-Message-SMTP-Method" "smtp smtp.gmail.com 587 arthur@aheymans.xyz")))
      )

(add-hook 'gnus-group-mode-hook 'gnus-topic-mode)

(setq gnus-message-archive-group
           '((".*" "nnimap+aheymans:Sent")))
(setq gnus-gcc-mark-as-read t)
(when window-system
  (setq gnus-sum-thread-tree-indent "  "
	gnus-sum-thread-tree-root "" ;; "● ")
	gnus-sum-thread-tree-false-root "" ;; "◯ ")
	gnus-sum-thread-tree-single-indent "" ;; "◎ ")
	gnus-sum-thread-tree-vertical        "│"
	gnus-sum-thread-tree-leaf-with-other "├─► "
	gnus-sum-thread-tree-single-leaf     "╰─► "))

(setq gnus-user-date-format-alist
      '(((gnus-seconds-today) . "Today, %H:%M")
	((+ 86400 (gnus-seconds-today)) . "Yday, %H:%M")
	(604800 . "%a %H:%M") ;;that's one week
	(t . "%d-%m-%Y")))
(setq gnus-summary-line-format "%O%U%R%z%-12&user-date; %B%(%[%L: %-10,40F%]%) %s\n")

(setq gnus-thread-sort-functions
      '((not gnus-thread-sort-by-date)
        (not gnus-thread-sort-by-number)))

(setq gnus-use-cache t)
