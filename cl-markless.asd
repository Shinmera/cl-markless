#|
 This file is a part of cl-markless
 (c) 2018 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(asdf:defsystem cl-markless
  :version "1.0.0"
  :license "Artistic"
  :author "Nicolas Hafner <shinmera@tymoon.eu>"
  :maintainer "Nicolas Hafner <shinmera@tymoon.eu>"
  :description "A parser implementation for Markless"
  :homepage "https://github.com/Shinmera/cl-markless"
  :serial T
  :components ((:file "package")
               (:file "conditions")
               (:file "component")
               (:file "parser")
               (:file "documentation"))
  :depends-on (:documentation-utils))
