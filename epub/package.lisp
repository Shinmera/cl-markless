(defpackage #:cl-markless-epub
  (:nicknames #:org.shirakumo.markless.epub)
  (:use #:cl #:org.shirakumo.markless)
  (:local-nicknames
   (#:components #:org.shirakumo.markless.components))
  (:shadow #:output)
  (:shadowing-import-from #:org.shirakumo.markless #:debug)
  (:export
   #:output
   #:epub
   #:id
   #:date
   #:title
   #:cover
   #:stylesheet
   #:embeds
   #:if-exists))
