(:name :opengl-bootstrap
 :api "OpenGL"
 :package #:lwlgl.opengl
 :revision "curated-1.0.0"
 :constants ((color-buffer-bit #x00004000)
             (depth-buffer-bit #x00000100))
 :commands ((:lisp-name gl-clear-color
             :native-name "glClearColor"
             :version (1 0)
             :dispatch :context
             :return-type :void
             :arguments ((red-value :float) (green :float) (blue :float) (alpha :float)))
            (:lisp-name gl-clear
             :native-name "glClear"
             :version (1 0)
             :dispatch :context
             :return-type :void
             :arguments ((mask :unsigned-int)))
            (:lisp-name gl-fence-sync
             :native-name "glFenceSync"
             :version (3 2)
             :dispatch :context
             :return-type :pointer
             :arguments ((condition :unsigned-int) (flags :unsigned-int))
             :optional t)))
