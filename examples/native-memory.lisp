(in-package #:lwlgl.examples)

(defun native-memory-demo ()
  "Demonstrates cursor buffers, stack allocation, addresses, and UTF-8 ownership."
  (let ((values
          (lwlgl.core:with-memory-stack (stack :size 1024)
            (let ((buffer (lwlgl.core:stack-calloc :float 4 :stack stack)))
              (dolist (value '(1.0 2.0 3.0 4.0))
                (lwlgl.core:buffer-put buffer value))
              (lwlgl.core:flip-native-buffer buffer)
              (format t "~&Stack float buffer: address=~D, remaining=~D~%"
                      (lwlgl.core:mem-address buffer)
                      (lwlgl.core:native-buffer-remaining buffer))
              (loop while (plusp (lwlgl.core:native-buffer-remaining buffer))
                    collect (lwlgl.core:buffer-get buffer))))))
    (let ((utf8 (lwlgl.core:mem-utf8 "LWLGL 1.0 — UTF-8")))
      (unwind-protect
           (let ((decoded
                   (lwlgl.core:utf8-buffer-to-string
                    utf8 :count (1- (lwlgl.core:native-buffer-length utf8)))))
             (format t "UTF-8 round trip: ~A~%" decoded)
             (list :values values :utf8 decoded))
        (lwlgl.core:mem-free utf8)))))
