#|
 This file is a part of cl-markless
 (c) 2018 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.markless.epub)

(defvar *path* NIL)

(defclass epub (output-format)
  ((id :initarg :id :initform NIL :accessor id)
   (date :initarg :date :initform NIL :accessor date)
   (title :initarg :title :initform NIL :accessor title)
   (cover :initarg :cover :initform NIL :accessor cover)
   (stylesheet :initarg :stylesheet :initform NIL :accessor stylesheet)
   (embeds :initarg :embeds :initform NIL :accessor embeds)
   (if-exists :initarg :if-exists :initform :error :accessor if-exists)))

(defun output (markless target &rest args)
  (etypecase markless
    (pathname
     (let ((*path* markless))
       (apply #'output (cl-markless:parse markless T) target args)))
    (string
     (apply #'output (cl-markless:parse markless T) target args))
    (components:component
     (create-epub (apply #'make-instance 'epub args) target markless))))

(defmethod output-component ((component components:root-component) (target pathname) (format epub))
  (create-epub format target component))

(defmethod create-epub ((epub epub) path root)
  (let ((date (get-universal-time))
        (*path* (or *path* path)))
    (autocomplete-metadata root epub)
    (zip:with-output-to-zipfile (zip path :if-exists (if-exists epub))
      (flet ((file (name streamish)
               (zip:write-zipentry zip name (ensure-input-stream streamish)
                                   :file-mode #o640
                                   :file-write-date date))
             (dir (name)
               (zip:write-zipentry zip name (make-concatenated-stream)
                                   :file-mode #o755
                                   :file-write-date date))
             (make-document (xml)
               (output-component root xml 'cl-markless-plump:plump))
             (make-cover (xml path)
               (let ((element (make-element xml "figure" '(("id" "cover")))))
                 (make-element element "img" `(("src" ,path))))))
        (file "mimetype" "application/epub+zip")
        (dir "META-INF/")
        (file "META-INF/container.xml" (meta-inf/container))
        (dir "OEBPS/")
        (file "OEBPS/document.opf" (oebps/opf root epub))
        (file "OEBPS/document.xhtml" (oebps/html epub #'make-document))
        (file "OEBPS/stylesheet.css" (stylesheet epub))
        (dir "OEBPS/embed/")
        (loop for (path target) in (embeds epub)
              do (file (format NIL "OEBPS/~a" target) (merge-pathnames path *path*)))
        (when (cover epub)
          (let ((path (format NIL "embed/cover.~a" (pathname-type (cover epub)))))
            (file (format NIL "OEBPS/~a" path) (merge-pathnames (cover epub) *path*))
            (file "OEBPS/cover.xhtml" (oebps/html epub (lambda (xml) (make-cover xml path))))))))
    path))

(defun autocomplete-metadata (root epub)
  (let ((title (cons most-positive-fixnum "untitled"))
        (counter 0)
        (embeds ()))
    (labels ((traverse (component)
               (typecase component
                 (components:header
                  (when (< (components:depth component) (car title))
                    (setf (car title) (components:depth component))
                    (setf (cdr title) (components:text component))))
                 (components:embed
                  (let ((target (components:target component)))
                    (cond ((cl-markless:starts-with "#" target))
                          ((cl-markless:read-url target 0)
                           (warn "Embeds to URLs will not work in epubs."))
                          (T
                           (let* ((path (uiop:parse-native-namestring target))
                                  (target (format NIL "embed/~a-~a.~a"
                                                  (pathname-name path) (incf counter) (pathname-type path))))
                             (setf (components:target component) target)
                             (push (list path target) embeds))))))
                 (components:parent-component
                  (loop for child across (components:children component)
                        do (traverse child))))))
      (traverse root)
      (unless (date epub) (setf (date epub) (format-date)))
      (unless (title epub) (setf (title epub) (cdr title)))
      (unless (id epub) (setf (id epub) (format NIL "~a-~a" (format-date) (title epub))))
      (unless (stylesheet epub) (setf (stylesheet epub) (resource-file "stylesheet" "css")))
      epub)))

(defun meta-inf/container ()
  (with-xml
    ("container" (("version" "1.0")
                  ("xmlns" "urn:oasis:names:tc:opendocument:xmlns:container"))
      ("rootfiles" ()
        ("rootfile" (("full-path" "OEBPS/document.opf")
                     ("media-type" "application/oebps-package+xml")))))))

(defun oebps/opf (root epub)
  (with-xml
    ("package" (("version" "2.0")
                ("xmlns" "http://www.idpf.org/2007/opf")
                ("unique-identifier" ""))
      ("metadata"
       (("xmlns:dc" "http://purl.org/dc/elements/1.1/")
        ("xmlns:opf" "http://www.idpf.org/2007/opf"))
       ("dc:title" () (:text (title epub)))
       ("dc:language" () (:text (or (components:language root) "en")))
       ("dc:identifier" (("id" "bookid")) (:text (id epub)))
       ("dc:creator" (("opf:role" "aut") ("id" "author"))
                     (:text (or (components:author root)
                                (car (last (pathname-directory (user-homedir-pathname))))
                                "Anonymous")))
       ("dc:date" () (:text (date epub)))
       ("dc:rights" () (:text (or (components:copyright root) ""))))
      ("manifest"
       ()
       ("item" (("id" "document") ("href" "document.xhtml") ("media-type" "application/xhtml+xml")))
       ("item" (("id" "stylesheet") ("href" "stylesheet.css") ("media-type" "text/css")))
       (:extra (xml)
         (when (cover epub)
           (make-element xml "item" `(("id" "cover-image")
                                      ("media-type" ,(trivial-mimes:mime-lookup (cover epub)))
                                      ("href" ,(format NIL "embed/cover.~a" (pathname-type (cover epub))))
                                      ("properties" "cover-image")))
           (make-element xml "item" `(("id" "cover-page")
                                      ("href" "cover.xhtml")
                                      ("media-type" "application/xhtml+xml"))))
         (loop for (path target) in (embeds epub)
               do (make-element xml "item" `(("id" ,target)
                                             ("href" ,target)
                                             ("media-type" ,(trivial-mimes:mime-lookup path)))))))
      ("spine"
       ()
       (:extra (xml)
         (when (cover epub)
           (make-element xml "itemref" `(("idref" "cover-page")))))
       ("itemref" (("idref" "document")))))))

(defun oebps/html (epub bodyfun)
  (with-xml
    (:extra (xml)
      (plump-dom:make-doctype xml "html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\""))
    ("html" (("xmlns" "http://www.w3.org/1999/xhtml")
             ("xml:lang" "en"))
      ("head" ()
       ("meta" (("http-equiv" "Content-Type")
                ("content" "application/xhtml+xml; charset=utf-8")))
       ("title" () (:text (title epub)))
       ("link" (("rel" "stylesheet")
                ("type" "text/css")
                ("href" "stylesheet.css"))))
      ("body" ()
       (:extra (xml) (funcall bodyfun xml))))))
