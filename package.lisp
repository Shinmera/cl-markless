#|
 This file is a part of cl-markless
 (c) 2018 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(defpackage #:cl-markless-components
  (:nicknames #:org.shirakumo.markless.components)
  (:use #:cl)
  (:shadow #:list #:number #:set #:variable #:warning #:error #:float #:labels)
  (:export
   #:sized
   #:unit
   #:size
   #:component
   #:unit-component
   #:text-component
   #:text
   #:block-component
   #:inline-component
   #:parent-component
   #:children
   #:root-component
   #:labels
   #:author
   #:copyright
   #:language
   #:label
   #:paragraph
   #:indentation
   #:blockquote-header
   #:blockquote
   #:source
   #:list
   #:list-item
   #:ordered-list
   #:ordered-list-item
   #:number
   #:unordered-list
   #:unordered-list-item
   #:header
   #:depth
   #:horizontal-rule
   #:code-block
   #:language
   #:options
   #:instruction
   #:message-instruction
   #:info
   #:set
   #:variable
   #:value
   #:message
   #:warning
   #:error
   #:include
   #:file
   #:directives-instruction
   #:directives
   #:disable
   #:enable
   #:label
   #:comment
   #:embed
   #:target
   #:image
   #:video
   #:audio
   #:embed-option
   #:loop-option
   #:autoplay-option
   #:width-option
   #:height-option
   #:float-option
   #:direction
   #:footnote
   #:bold
   #:italic
   #:underline
   #:strikethrough
   #:code
   #:subtext
   #:supertext
   #:url
   #:compound
   #:options
   #:compound-option
   #:bold-option
   #:italic-option
   #:underline-option
   #:strikethrough-option
   #:spoiler-option
   #:font-option
   #:font-family
   #:color-option
   #:red
   #:green
   #:blue
   #:size-option
   #:internal-link-option
   #:link-option
   #:target
   #:footnote-reference
   #:target
   #:en-dash
   #:em-dash
   #:newline))

(defpackage #:cl-markless
  (:nicknames #:org.shirakumo.markless)
  (:use #:cl)
  (:local-nicknames
   (#:components #:org.shirakumo.markless.components))
  (:shadow #:debug)
  ;; color-table.lisp
  (:export
   #:*color-table*)
  ;; conditions.lisp
  (:export
   #:markless-condition
   #:implementation-condition
   #:stack-exhausted
   #:instruction-evaluation-undefined
   #:instruction
   #:parser-error
   #:parser-warning
   #:deactivation-disallowed
   #:directive-instance
   #:unknown-instruction
   #:instruction
   #:unknown-embed-type
   #:embed-type
   #:bad-option
   #:option
   #:bad-unit
   #:option-disallowed
   #:embed-type
   #:bad-variable
   #:variable-name
   #:bad-value
   #:variable-name
   #:value
   #:user-warning
   #:message
   #:user-error
   #:message)
  ;; directive.lisp
  (:export
   #:prefix
   #:begin
   #:invoke
   #:end
   #:consume-prefix
   #:consume-end
   #:directive
   #:enabled-p
   #:ensure-directive
   #:root-directive
   #:block-directive
   #:singular-line-directive
   #:inline-directive
   #:surrounding-inline-directive
   #:paragraph
   #:blockquote-header
   #:blockquote
   #:unordered-list
   #:ordered-list
   #:header
   #:horizontal-rule
   #:code-block
   #:instruction
   #:parse-insruction
   #:comment
   #:embed
   #:parse-embed-option
   #:parse-embed-option-type
   #:embed-option-allowed-p
   #:footnote
   #:bold
   #:italic
   #:underline
   #:strikethrough
   #:code
   #:supertext
   #:subtext
   #:compound
   #:parse-compound-option
   #:parse-compound-option-type
   #:footnote-reference
   #:dash
   #:newline
   #:url)
  ;; parser.lisp
  (:export
   #:*default-directives*
   #:compile-dispatch-table
   #:dispatch
   #:stack-entry
   #:stack-entry-component
   #:stack-entry-directive
   #:parser
   #:line-break-mode
   #:directives
   #:block-dispatch-table
   #:inline-dispatch-table
   #:input
   #:stack
   #:stack-push
   #:stack-pop
   #:stack-top
   #:stack-bottom
   #:root
   #:directive
   #:directives-of
   #:disable
   #:enable
   #:evaluate-instruction
   #:read-full-line
   #:parse
   #:stack-unwind
   #:commit
   #:read-block
   #:read-url
   #:read-inline)
  ;; printer.lisp
  (:export
   #:output
   #:output-format
   #:list-output-formats
   #:markless
   #:debug
   #:define-output
   #:output-component
   #:output
   #:output-children)
  ;; size-table.lisp
  (:export
   #:*size-table*)
  ;; toolkit.lisp
  (:export
   #:match!
   #:read-delimited
   #:split-string
   #:starts-with
   #:ends-with
   #:parse-float
   #:to-readtable-case
   #:condense-children
   #:condense-component-tree))
