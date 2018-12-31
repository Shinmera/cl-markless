#|
 This file is a part of cl-markless
 (c) 2018 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.markless.epub)

(defclass utf-8-input-stream (trivial-gray-streams:fundamental-binary-input-stream)
  ((source :initarg :source :initform (error "SOURCE required.") :accessor source)
   (buffer :initform (make-array 0 :element-type '(unsigned-byte 8)) :accessor buffer)
   (index :initform 0 :accessor index)))

(defun ensure-input-stream (streamish)
  (cond ((stringp streamish)
         (make-instance 'utf-8-input-stream :source (make-string-input-stream streamish)))
        ((pathnamep streamish)
         streamish)
        ((not (streamp streamish))
         (error "Must be string, pathname, or stream."))
        ((eql 'character (stream-element-type streamish))
         (make-instance 'utf-8-input-stream :source streamish))
        (T
         streamish)))

(defun fresh-buffer (stream)
  (let* ((charbuf (make-string 1024 :initial-element #\Nul))
         (read (read-sequence charbuf (source stream)))
         (octs (babel:string-to-octets charbuf :end read :encoding :utf-8)))
    (setf (index stream) 0)
    (setf (buffer stream) octs)))

(defmethod trivial-gray-streams:stream-read-byte ((stream utf-8-input-stream))
  (let ((buffer (buffer stream))
        (index (index stream)))
    (when (<= (length buffer) index)
      (setf index 0)
      (setf buffer (fresh-buffer stream)))
    (cond ((= 0 (length buffer))
           :eof)
          (T
           (setf (index stream) (1+ index))
           (aref buffer index)))))

(defmethod trivial-gray-streams:stream-read-sequence ((stream utf-8-input-stream) sequence start end &key)
  (loop with i = start
        do (let* ((buffer (buffer stream))
                  (index (index stream)))
             (when (<= (length buffer) index)
               (setf index 0)
               (setf buffer (fresh-buffer stream)))
             (when (= 0 (length buffer))
               (return i))
             (let* ((bytes-available (- (length buffer) index))
                    (bytes-to-write (min bytes-available (- end i))))
               (replace sequence buffer :start1 i :end1 (+ i bytes-to-write)
                                        :start2 index)
               (incf (index stream) bytes-to-write)
               (incf i bytes-to-write)
               (when (<= end i) (return i))))))
