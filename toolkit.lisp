#|
 This file is a part of cl-markless
 (c) 2018 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.markless)

(defun decompose-rgb (hex)
  (list (ldb (byte 8 16) hex)
        (ldb (byte 8  8) hex)
        (ldb (byte 8  0) hex)))

(defmacro match! (prefix line cursor)
  (let ((lineg (gensym "LINE")) (cursorg (gensym "CURSOR")))
    `(let ((,lineg ,line)
           (,cursorg ,cursor))
       (declare (type simple-string ,lineg))
       (declare (type (unsigned-byte 32) ,cursorg))
       (declare (optimize speed))
       ,(loop for form = `(+ ,cursorg ,(length prefix))
              then `(when (char= ,(aref prefix i) (aref ,lineg (+ ,cursorg ,i)))
                      ,form)
              for i downfrom (1- (length prefix)) to 0
              finally (return `(when (<= (+ ,cursorg ,(length prefix)) (length ,lineg))
                                 ,form))))))

(defun read-space-delimited (line cursor)
  (values (with-output-to-string (stream)
            (loop while (< cursor (length line))
                  for char = (aref line cursor)
                  while (char/= #\  char)
                  do (write-char char stream)
                     (incf cursor)))
          cursor))

(defun split-string (string split &optional (start 0))
  (let ((parts ())
        (buffer (make-string-output-stream)))
    (flet ((commit ()
             (let ((string (get-output-stream-string buffer)))
               (when (string/= "" string)
                 (push string parts)))))
      (loop for i from start below (length string)
            for char = (aref string i)
            do (if (char= char split)
                   (commit)
                   (write-char char buffer))
            finally (commit))
      (nreverse parts))))

(defun split-options (line cursor end)
  (let* ((options ())
         (buffer (make-string-output-stream)))
    (flet ((commit ()
             (let ((string (string-trim " " (get-output-stream-string buffer))))
               (when (string/= "" string)
                 (push string options)))))
      (loop while (< cursor (length line))
            for char = (aref line cursor)
            do (cond ((char= #\\ char)
                      (incf cursor)
                      (write-char (aref line cursor) buffer))
                     ((char= #\, char)
                      (commit))
                     ((char= end char)
                      (incf cursor)
                      (return))
                     (T
                      (write-char char buffer)))
               (incf cursor))
      (commit))
    (values (nreverse options) cursor)))

(defun starts-with (beginning string &optional (start 0))
  (and (<= (length beginning) (- (length string) start))
       (string= beginning string :start2 start :end2 (+ start (length beginning)))))

(defun ends-with (end string)
  (and (<= (length end) (length string))
       (string= end string :start2 (- (length string) (length end)))))

(defun parse-float (string &key (start 0) (end (length string)))
  (let* ((dot (or (position #\. string :start start :end end) end))
         (whole (parse-integer string :start start :end dot)))
    (incf dot)
    (float
     (if (< dot end)
         (let ((fractional (parse-integer string :start dot :end end)))
           (+ whole (/ fractional (expt 10 (- end dot)))))
         whole))))

(defun parse-unit (string &key (start 0))
  (let* ((unit (cond ((ends-with "em" string) :em)
                     ((ends-with "pt" string) :pt)
                     ((ends-with "px" string) :px)
                     ((ends-with "%" string) :%)
                     (T (error "FIXME: better error"))))
         (size (parse-float string :start start :end (- (length string) (length (string unit))))))
    (values size unit)))

(defun to-readtable-case (string case)
  (ecase case
    (:downcase (string-downcase string))
    (:upcase (string-upcase string))
    (:preserve string)
    (:invert (error "FIXME: Implement INVERT read-case."))))

(defun condense-children (children)
  (let ((buffer (make-string-output-stream))
        (result (make-array 0 :adjustable T :fill-pointer T)))
    (labels ((commit ()
               (let ((string (get-output-stream-string buffer)))
                 (when (string/= "" string)
                   (vector-push-extend string result))))
             (traverse (children)
               (loop for child across children
                     do (cond ((stringp child)
                               (write-string child buffer))
                              ((typep child 'components:instruction))
                              ((typep child 'components:comment))
                              ((eql 'components:parent-component (type-of child))
                               (traverse (components:children child)))
                              (T
                               (commit)
                               (vector-push-extend child result))))))
      (traverse children)
      (let ((string (string-right-trim '(#\Newline) (get-output-stream-string buffer))))
        (when (string/= "" string)
          (vector-push-extend string result)))
      result)))

(defun condense-component-tree (component)
  (loop for child across (setf (components:children component)
                               (condense-children component))
        do (when (typep child 'components:parent-component)
             (condense-component-tree child)))
  component)

(defun vector-push-front (element vector)
  (vector-push-extend (aref vector (1- (length vector))) vector)
  (loop for i downfrom (- (length vector) 2) to 1
        do (setf (aref vector i) (aref vector (1- i))))
  (setf (aref vector 0) element))

(defun delegate-paragraph (parser line cursor)
  (let* ((component (stack-entry-component (stack-top (stack parser))))
         (children (components:children component))
         (sibling (when (< 0 (length children))
                      (aref children (1- (length children))))))
    (unless (or (typep sibling 'components:paragraph)
                (typep component 'components:paragraph))
      (commit (directive 'paragraph parser) (make-instance 'components:paragraph) parser))
    (read-inline parser line cursor #\Nul)))
