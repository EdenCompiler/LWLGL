(in-package #:lwlgl.core)

(define-condition lwlgl-error (error) ())

(define-condition native-library-error (lwlgl-error)
  ((module :initarg :module :reader native-library-error-module)
   (cause :initarg :cause :reader native-library-error-cause))
  (:report (lambda (condition stream)
             (format stream "Falha ao carregar módulo nativo ~A: ~A"
                     (native-library-error-module condition)
                     (native-library-error-cause condition)))))

(define-condition unsupported-platform (lwlgl-error)
  ((platform :initarg :platform :reader unsupported-platform-platform))
  (:report (lambda (condition stream)
             (format stream "Plataforma não suportada pelo módulo: ~A"
                     (unsupported-platform-platform condition)))))

(define-condition missing-native-symbol (lwlgl-error)
  ((name :initarg :name :reader missing-native-symbol-name))
  (:report (lambda (condition stream)
             (format stream "Símbolo nativo não encontrado: ~A"
                     (missing-native-symbol-name condition)))))
