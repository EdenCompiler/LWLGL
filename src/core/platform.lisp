(in-package #:lwlgl.core)

(defparameter *lwlgl-version* "0.4.1")

(defun platform ()
  "Retorna uma keyword que identifica a plataforma hospedeira."
  #+windows :windows
  #+darwin :macos
  #+(and unix (not darwin)) :linux
  #-(or windows darwin unix) :unknown)

(defun architecture ()
  "Retorna uma keyword simples para a arquitetura de CPU."
  #+x86-64 :x86-64
  #+x86 :x86
  #+arm64 :arm64
  #+(and arm (not arm64)) :arm
  #-(or x86-64 x86 arm64 arm) :unknown)

(defun shared-library-extension ()
  (ecase (platform)
    (:windows "dll")
    (:macos "dylib")
    (:linux "so")
    (:unknown "so")))

(defun platform-library-names (&key windows macos linux)
  "Escolhe uma lista de nomes de biblioteca para a plataforma atual."
  (copy-list
   (ecase (platform)
     (:windows windows)
     (:macos macos)
     (:linux linux)
     (:unknown linux))))
